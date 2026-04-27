import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../models/teacher_model.dart';
import '../models/subject_model.dart';
import '../models/booking_model.dart';
import 'firestore_service.dart';

class SchedulerService {
  static final SchedulerService _instance = SchedulerService._internal();
  factory SchedulerService() => _instance;
  SchedulerService._internal();

  final FirestoreService _firestore = FirestoreService();

  // Time slots configuration
  static const List<String> timeSlots = [
    '07:00-08:30',
    '08:30-10:00',
    '10:00-11:30',
    '11:30-13:00',
    '13:00-14:30',
    '14:30-16:00',
    '16:00-17:30',
  ];

  static const List<String> daysOfWeek = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday'
  ];

  /// Main auto-scheduler function
  /// Returns proposed schedule with conflict detection
  Future<ScheduleResult> generateSchedule({
    required String semester,
    required String schoolYear,
    required List<String> selectedSubjectIds,
    required List<String> selectedRoomIds,
    required List<String> selectedTeacherIds,
    Map<String, dynamic>? constraints,
  }) async {

    final stopwatch = Stopwatch()..start();

    try {
      // 1. Fetch all necessary data
      final allRooms = await _firestore.getRooms();
      final allTeachers = await _firestore.getTeachers();
      final allSubjects = await _firestore.getSubjects();

      final rooms = allRooms.where((r) => selectedRoomIds.contains(r.id)).toList();
      final teachers = allTeachers.where((t) => selectedTeacherIds.contains(t.id)).toList();
      final subjects = allSubjects.where((s) => selectedSubjectIds.contains(s.id)).toList();

      // 2. Initialize tracking structures
      final schedule = <Booking>[];
      final conflicts = <ScheduleConflict>[];
      final teacherLoad = <String, double>{for (var t in teachers) t.id: 0.0};
      final roomSchedule = <String, Set<String>>{for (var r in rooms) r.id: {}};
      final teacherSchedule = <String, Set<String>>{for (var t in teachers) t.id: {}};

      // 3. Sort subjects by priority (harder to schedule first)
      subjects.sort((a, b) => _calculateSubjectPriority(b).compareTo(_calculateSubjectPriority(a)));

      // 4. Generate bookings for each subject
      for (final subject in subjects) {
        final requiredSlots = _calculateRequiredSlots(subject);
        final eligibleTeachers = _findEligibleTeachers(subject, teachers);

        if (eligibleTeachers.isEmpty) {
          conflicts.add(ScheduleConflict(
            type: ConflictType.noEligibleTeacher,
            description: 'No eligible teacher found for ${subject.name} (Code: ${subject.code})',
            subjectId: subject.id,
          ));
          continue;
        }

        // Try to find time slots for this subject
        int slotsAssigned = 0;
        int attempts = 0;
        const maxAttempts = 100;

        while (slotsAssigned < requiredSlots && attempts < maxAttempts) {
          attempts++;

          // Find best available slot
          final slot = _findBestSlot(
            subject: subject,
            rooms: rooms,
            teachers: eligibleTeachers,
            teacherLoad: teacherLoad,
            roomSchedule: roomSchedule,
            teacherSchedule: teacherSchedule,
            existingBookings: schedule,
          );

          if (slot == null) {
            conflicts.add(ScheduleConflict(
              type: ConflictType.noAvailableSlot,
              description: 'Could not find available slot for ${subject.name} (${slotsAssigned + 1}/$requiredSlots)',
              subjectId: subject.id,
            ));
            break;
          }

          // Create booking
          final booking = Booking(
            id: 'temp_${Random().nextInt(100000)}', // Temporary ID
            roomId: slot.room.id,
            teacherId: slot.teacher.id,
            subjectId: subject.id,
            dayOfWeek: slot.day,
            startTime: slot.startTime,
            endTime: slot.endTime,
            semester: semester,
            schoolYear: schoolYear,
            isRecurring: true,
            roomName: slot.room.name,
            teacherName: slot.teacher.name,
            subjectName: subject.name,
            subjectCode: subject.code,
          );

          schedule.add(booking);

          // Update tracking
          final timeKey = '${slot.day}_${slot.startTime}';
          roomSchedule[slot.room.id]!.add(timeKey);
          teacherSchedule[slot.teacher.id]!.add(timeKey);
          teacherLoad[slot.teacher.id] = (teacherLoad[slot.teacher.id] ?? 0) +
              _calculateSlotHours(slot.startTime, slot.endTime);

          slotsAssigned++;
        }
      }

      // 5. Validate final schedule
      final validationConflicts = _validateSchedule(schedule, teachers, rooms);
      conflicts.addAll(validationConflicts);

      stopwatch.stop();

      return ScheduleResult(
        bookings: schedule,
        conflicts: conflicts,
        generationTimeMs: stopwatch.elapsedMilliseconds,
        totalSubjects: subjects.length,
        scheduledSubjects: subjects.length - conflicts.where((c) => c.type == ConflictType.noAvailableSlot).length,
        teacherUtilization: _calculateTeacherUtilization(teacherLoad, teachers),
        roomUtilization: _calculateRoomUtilization(roomSchedule, rooms),
      );

    } catch (e) {
      stopwatch.stop();
      throw Exception('Schedule generation failed: $e');
    }
  }

  /// Save generated schedule to Firestore
  Future<void> publishSchedule(ScheduleResult result, String createdBy) async {
    if (result.bookings.isEmpty) return;

    final semester = result.bookings.first.semester;
    final schoolYear = result.bookings.first.schoolYear;

    final batch = FirebaseFirestore.instance.batch();

    // 1. Clear all existing bookings for this semester/year
    final existing = await _firestore.getBookings(
      semester: semester,
      schoolYear: schoolYear,
    );

    for (final booking in existing) {
      batch.delete(_firestore.bookingsCollection.doc(booking.id));
    }

    // 2. Write all new bookings
    for (final booking in result.bookings) {
      final docRef = _firestore.bookingsCollection.doc();
      final newBooking = Booking(
        id: docRef.id,
        roomId: booking.roomId,
        teacherId: booking.teacherId,
        subjectId: booking.subjectId,
        dayOfWeek: booking.dayOfWeek,
        startTime: booking.startTime,
        endTime: booking.endTime,
        semester: semester,
        schoolYear: schoolYear,
        isRecurring: booking.isRecurring,
        roomName: booking.roomName,
        teacherName: booking.teacherName,
        subjectName: booking.subjectName,
        subjectCode: booking.subjectCode,
        createdBy: createdBy,
      );
      batch.set(docRef, newBooking.toFirestore());
    }

    await batch.commit();

    // 3. Record this publish event in published_schedules (NEW)
    //    This is what the Dashboard and Reports screens read for history.
    await _firestore.publishScheduleRecord(
      semester: semester,
      schoolYear: schoolYear,
      totalBookings: result.bookings.length,
      publishedBy: createdBy,
      successRate: result.successRate,
      conflictCount: result.conflicts.length,
    );

    // 4. Update teacher load summaries
    await _updateTeacherLoads(result.bookings);
  }

  // ==================== HELPER METHODS ====================

  double _calculateSubjectPriority(Subject subject) {
    double score = 0;
    // Higher priority for subjects with specific requirements
    if (subject.preferredRoomType == RoomType.laboratory) score += 10;
    if (subject.requiredEquipment.isNotEmpty) score += subject.requiredEquipment.length * 2;
    // Higher priority for subjects with fewer eligible teachers
    score += (5 - subject.eligibleTeachers.length).clamp(0, 5);
    return score;
  }

  int _calculateRequiredSlots(Subject subject) {
    // Assuming each slot is 1.5 hours
    return (subject.requiredHoursPerWeek / 1.5).ceil();
  }

  List<Teacher> _findEligibleTeachers(Subject subject, List<Teacher> teachers) {
    return teachers.where((t) {
      // Check 1: Direct ID match from subject's eligibleTeachers list (highest priority)
      final canTeachById = subject.eligibleTeachers.contains(t.id);
      if (canTeachById) return true; // Immediate match if explicitly assigned

      // Check 2: Department compatibility (teacher's department matches subject's department)
      // Uses contains for flexible matching: "IT" matches "Information Technology"
      final departmentMatch = t.department.toLowerCase() == subject.department.toLowerCase() ||
          subject.department.toLowerCase().contains(t.department.toLowerCase()) ||
          t.department.toLowerCase().contains(subject.department.toLowerCase());

      // Check 3: Expertise matches subject name (e.g., "Security" in "Information Security")
      final expertiseMatch = t.expertiseSubjects.any((expertise) {
        final expLower = expertise.toLowerCase();
        final subjNameLower = subject.name.toLowerCase();
        final subjCodeLower = subject.code.toLowerCase();

        return subjNameLower.contains(expLower) ||      // "Information Security" contains "security"
            expLower.contains(subjNameLower) ||        // "security" contains "information security" (unlikely but safe)
            subjCodeLower.contains(expLower) ||        // "INFOSECT1" contains "security"
            expLower.contains(subjCodeLower);          // "security" contains "infosect1" (unlikely but safe)
      });

      // Check 4: Subject code prefix match (e.g., teacher with "INFO" expertise teaches "INFOSECT1")
      final codePrefixMatch = t.expertiseSubjects.any((expertise) {
        // Extract prefix from subject code (e.g., "INFO" from "INFOSECT1")
        final codePrefix = subject.code.replaceAll(RegExp(r'[^A-Z]'), ''); // Extract letters only
        return expertise.toUpperCase() == codePrefix ||
            codePrefix.contains(expertise.toUpperCase()) ||
            expertise.toUpperCase().contains(codePrefix);
      });

      // Combine checks: Must have capacity AND (department match OR expertise match OR code match)
      final hasCapacity = t.currentWeeklyHours < t.maxWeeklyHours;
      final canTeachSubject = departmentMatch || expertiseMatch || codePrefixMatch;

      // Debug output for troubleshooting
      if (!canTeachSubject && subject.code == 'INFOSECT1') {
        print('DEBUG: Teacher ${t.name} cannot teach ${subject.code}');
        print('  - Teacher Dept: ${t.department} | Subject Dept: ${subject.department}');
        print('  - Expertise: ${t.expertiseSubjects}');
        print('  - Dept Match: $departmentMatch | Expertise Match: $expertiseMatch | Code Match: $codePrefixMatch');
      }

      return canTeachSubject && hasCapacity;
    }).toList();
  }

  _SlotCandidate? _findBestSlot({
    required Subject subject,
    required List<Room> rooms,
    required List<Teacher> teachers,
    required Map<String, double> teacherLoad,
    required Map<String, Set<String>> roomSchedule,
    required Map<String, Set<String>> teacherSchedule,
    required List<Booking> existingBookings,
  }) {
    final candidates = <_SlotCandidate>[];

    for (final day in daysOfWeek) {
      for (final timeSlot in timeSlots) {
        final times = timeSlot.split('-');
        final startTime = times[0];
        final endTime = times[1];
        final timeKey = '${day}_$startTime';

        // Find suitable rooms
        for (final room in rooms) {
          // Check room type match
          if (room.type != subject.preferredRoomType &&
              subject.preferredRoomType == RoomType.laboratory) {
            continue; // Strict match for labs
          }

          // Check equipment
          final hasEquipment = subject.requiredEquipment.every(
                  (eq) => room.equipment.any((re) =>
                  re.toLowerCase().contains(eq.toLowerCase()))
          );
          if (!hasEquipment) continue;

          // Check capacity
          if (room.capacity < subject.maxStudents) continue;

          // Check if room is available
          if (roomSchedule[room.id]!.contains(timeKey)) continue;

          // Find best teacher for this slot
          for (final teacher in teachers) {
            // Hard Limit: Check teacher current session load (with small buffer for odd hours)
            final currentSessionLoad = teacherLoad[teacher.id] ?? 0.0;
            if (currentSessionLoad >= teacher.maxWeeklyHours + 2.0) continue;

            // Check teacher availability
            if (teacherSchedule[teacher.id]!.contains(timeKey)) continue;

            // Check unavailable slots
            if (_isTeacherUnavailable(teacher, day, startTime, endTime)) continue;

            // Calculate score
            final score = _calculateSlotScore(
              room: room,
              teacher: teacher,
              subject: subject,
              day: day,
              startTime: startTime,
              teacherLoad: teacherLoad,
            );

            candidates.add(_SlotCandidate(
              room: room,
              teacher: teacher,
              day: day,
              startTime: startTime,
              endTime: endTime,
              score: score,
            ));
          }
        }
      }
    }

    if (candidates.isEmpty) return null;

    // Sort by score (higher is better) and return best
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.first;
  }

  double _calculateSlotScore({
    required Room room,
    required Teacher teacher,
    required Subject subject,
    required String day,
    required String startTime,
    required Map<String, double> teacherLoad,
  }) {
    double score = 0;

    // Prefer rooms with exact equipment match (not over-equipped)
    final equipmentMatch = room.equipment.length == subject.requiredEquipment.length;
    if (equipmentMatch) score += 10;

    // Prefer optimal capacity (not too big, not too small)
    final capacityRatio = subject.maxStudents / room.capacity;
    if (capacityRatio >= 0.7 && capacityRatio <= 1.0) score += 10;
    else if (capacityRatio >= 0.5) score += 5;

    // Prefer teachers with lower current load (balance workload)
    final loadRatio = (teacherLoad[teacher.id] ?? 0) / teacher.maxWeeklyHours;
    score += (1 - loadRatio) * 20;

    // Prefer teacher preferred time slots
    final timeOfDay = _getTimeOfDay(startTime);
    if (teacher.preferredTimeSlots.contains(timeOfDay)) score += 15;

    // Small random factor to break ties
    score += Random().nextDouble() * 2;

    return score;
  }

  String _getTimeOfDay(String time) {
    final hour = int.parse(time.split(':')[0]);
    if (hour < 10) return 'morning';
    if (hour < 13) return 'midday';
    if (hour < 16) return 'afternoon';
    return 'evening';
  }

  bool _isTeacherUnavailable(Teacher teacher, String day, String start, String end) {
    final unavailable = teacher.unavailableSlots[day.toLowerCase()];
    if (unavailable == null) return false;

    // Check if time overlaps with unavailable slots
    // Proper implementation would convert everything to minutes from midnight
    return false;
  }

  double _calculateSlotHours(String start, String end) {
    final startParts = start.split(':');
    final endParts = end.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    return (endMinutes - startMinutes) / 60.0;
  }

  List<ScheduleConflict> _validateSchedule(
      List<Booking> schedule,
      List<Teacher> teachers,
      List<Room> rooms
      ) {
    final conflicts = <ScheduleConflict>[];

    // Check for double bookings
    for (int i = 0; i < schedule.length; i++) {
      for (int j = i + 1; j < schedule.length; j++) {
        final a = schedule[i];
        final b = schedule[j];

        if (a.dayOfWeek == b.dayOfWeek && a.startTime == b.startTime) {
          if (a.roomId == b.roomId) {
            conflicts.add(ScheduleConflict(
              type: ConflictType.doubleBooking,
              description: 'Room ${a.roomName} double booked on ${a.dayOfWeek} at ${a.startTime}',
              roomId: a.roomId,
              bookingIds: [a.id, b.id],
            ));
          }
          if (a.teacherId == b.teacherId) {
            conflicts.add(ScheduleConflict(
              type: ConflictType.teacherOverlap,
              description: 'Teacher ${a.teacherName} double booked on ${a.dayOfWeek} at ${a.startTime}',
              teacherId: a.teacherId,
              bookingIds: [a.id, b.id],
            ));
          }
        }
      }
    }

    // Check teacher overloads
    final teacherHours = <String, double>{};
    for (final booking in schedule) {
      final hours = _calculateSlotHours(booking.startTime, booking.endTime);
      teacherHours[booking.teacherId] = (teacherHours[booking.teacherId] ?? 0) + hours;
    }

    for (final teacher in teachers) {
      final hours = teacherHours[teacher.id] ?? 0;
      if (hours > teacher.maxWeeklyHours + 0.1) {
        conflicts.add(ScheduleConflict(
          type: ConflictType.teacherOverload,
          description: 'Teacher ${teacher.name} assigned ${hours.toStringAsFixed(1)} hours (max: ${teacher.maxWeeklyHours})',
          teacherId: teacher.id,
        ));
      }
    }

    return conflicts;
  }

  Map<String, double> _calculateTeacherUtilization(
      Map<String, double> teacherLoad,
      List<Teacher> teachers
      ) {
    final result = <String, double>{};
    for (final teacher in teachers) {
      final load = teacherLoad[teacher.id] ?? 0;
      result[teacher.name] = (load / teacher.maxWeeklyHours * 100).clamp(0, 100);
    }
    return result;
  }

  Map<String, double> _calculateRoomUtilization(
      Map<String, Set<String>> roomSchedule,
      List<Room> rooms
      ) {
    final result = <String, double>{};
    final totalSlots = daysOfWeek.length * timeSlots.length;

    for (final room in rooms) {
      final booked = roomSchedule[room.id]?.length ?? 0;
      result[room.name] = (booked / totalSlots * 100).clamp(0, 100);
    }
    return result;
  }

  Future<void> _updateTeacherLoads(List<Booking> bookings) async {
    final teacherHours = <String, double>{};

    for (final booking in bookings) {
      final hours = _calculateSlotHours(booking.startTime, booking.endTime);
      teacherHours[booking.teacherId] = (teacherHours[booking.teacherId] ?? 0) + hours;
    }

    for (final entry in teacherHours.entries) {
      await _firestore.updateTeacherLoad(
          entry.key,
          entry.value.toInt(), // Rounding for legacy compatibility
          bookings.where((b) => b.teacherId == entry.key).map((b) => b.subjectId).toSet().length
      );
    }
  }
}

// Supporting classes
class _SlotCandidate {
  final Room room;
  final Teacher teacher;
  final String day;
  final String startTime;
  final String endTime;
  final double score;

  _SlotCandidate({
    required this.room,
    required this.teacher,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.score,
  });
}

class ScheduleResult {
  final List<Booking> bookings;
  final List<ScheduleConflict> conflicts;
  final int generationTimeMs;
  final int totalSubjects;
  final int scheduledSubjects;
  final Map<String, double> teacherUtilization;
  final Map<String, double> roomUtilization;

  ScheduleResult({
    required this.bookings,
    required this.conflicts,
    required this.generationTimeMs,
    required this.totalSubjects,
    required this.scheduledSubjects,
    required this.teacherUtilization,
    required this.roomUtilization,
  });

  bool get hasConflicts => conflicts.isNotEmpty;
  double get successRate => totalSubjects > 0 ? (scheduledSubjects / totalSubjects * 100) : 0;
}

class ScheduleConflict {
  final ConflictType type;
  final String description;
  final String? subjectId;
  final String? roomId;
  final String? teacherId;
  final List<String>? bookingIds;

  ScheduleConflict({
    required this.type,
    required this.description,
    this.subjectId,
    this.roomId,
    this.teacherId,
    this.bookingIds,
  });
}

enum ConflictType {
  noEligibleTeacher,
  noAvailableSlot,
  doubleBooking,
  teacherOverlap,
  teacherOverload,
  roomOverload,
}
