//lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../models/teacher_model.dart';
import '../models/subject_model.dart';
import '../models/booking_model.dart';
import '../models/conflict_model.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get roomsCollection => _firestore.collection('rooms');
  CollectionReference get teachersCollection => _firestore.collection('teachers');
  CollectionReference get subjectsCollection => _firestore.collection('subjects');
  CollectionReference get bookingsCollection => _firestore.collection('bookings');
  CollectionReference get conflictsCollection => _firestore.collection('conflicts');
  CollectionReference get publishedSchedulesCollection =>
      _firestore.collection('published_schedules'); // NEW
  DocumentReference get settingsDocument =>
      _firestore.collection('settings').doc('app_settings'); // NEW

  // ==================== ROOM OPERATIONS ====================

  Stream<List<Room>> getRoomsStream() {
    return roomsCollection
        .orderBy('building')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList();
    });
  }

  Future<List<Room>> getRooms() async {
    final snapshot = await roomsCollection.get();
    return snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList();
  }

  Future<Room?> getRoom(String roomId) async {
    final doc = await roomsCollection.doc(roomId).get();
    if (doc.exists) {
      return Room.fromFirestore(doc);
    }
    return null;
  }

  Future<String> addRoom(Room room) async {
    final docRef = await roomsCollection.add(room.toFirestore());
    return docRef.id;
  }

  Future<void> updateRoom(Room room) async {
    await roomsCollection.doc(room.id).update(room.toFirestore());
  }

  Future<void> deleteRoom(String roomId) async {
    await roomsCollection.doc(roomId).delete();
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    await roomsCollection.doc(roomId).update({
      'currentStatus': status.name,
      'updatedAt': Timestamp.now(),
    });
  }

  // ==================== TEACHER OPERATIONS ====================

  Stream<List<Teacher>> getTeachersStream() {
    return teachersCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Teacher.fromFirestore(doc)).toList();
    });
  }

  Future<List<Teacher>> getTeachers() async {
    final snapshot = await teachersCollection.get();
    return snapshot.docs.map((doc) => Teacher.fromFirestore(doc)).toList();
  }

  Future<Teacher?> getTeacher(String teacherId) async {
    final doc = await teachersCollection.doc(teacherId).get();
    if (doc.exists) {
      return Teacher.fromFirestore(doc);
    }
    return null;
  }

  Future<String> addTeacher(Teacher teacher) async {
    final docRef = await teachersCollection.add(teacher.toFirestore());
    return docRef.id;
  }

  Future<void> updateTeacher(Teacher teacher) async {
    await teachersCollection.doc(teacher.id).update(teacher.toFirestore());
  }

  Future<void> deleteTeacher(String teacherId) async {
    await teachersCollection.doc(teacherId).delete();
  }

  Future<void> updateTeacherLoad(String teacherId, int hours, int subjects) async {
    await teachersCollection.doc(teacherId).update({
      'currentWeeklyHours': hours,
      'activeSubjectsCount': subjects,
      'updatedAt': Timestamp.now(),
    });
  }

  // ==================== SUBJECT OPERATIONS ====================

  Stream<List<Subject>> getSubjectsStream() {
    return subjectsCollection
        .orderBy('code')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();
    });
  }

  Future<List<Subject>> getSubjects() async {
    final snapshot = await subjectsCollection.get();
    return snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();
  }

  Future<String> addSubject(Subject subject) async {
    final docRef = await subjectsCollection.add(subject.toFirestore());
    return docRef.id;
  }

  Future<void> updateSubject(Subject subject) async {
    await subjectsCollection.doc(subject.id).update(subject.toFirestore());
  }

  Future<void> deleteSubject(String subjectId) async {
    await subjectsCollection.doc(subjectId).delete();
  }

  // ==================== BOOKING OPERATIONS ====================

  Stream<List<Booking>> getBookingsStream({
    String? semester,
    String? schoolYear,
    String? roomId,
    String? teacherId,
    String? dayOfWeek,
  }) {
    Query query = bookingsCollection;

    if (semester != null) {
      query = query.where('semester', isEqualTo: semester);
    }
    if (schoolYear != null) {
      query = query.where('schoolYear', isEqualTo: schoolYear);
    }
    if (roomId != null) {
      query = query.where('roomId', isEqualTo: roomId);
    }
    if (teacherId != null) {
      query = query.where('teacherId', isEqualTo: teacherId);
    }
    if (dayOfWeek != null) {
      query = query.where('dayOfWeek', isEqualTo: dayOfWeek);
    }

    return query.orderBy('startTime').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    });
  }

  Future<List<Booking>> getBookings({
    String? semester,
    String? schoolYear,
    String? roomId,
    String? teacherId,
  }) async {
    Query query = bookingsCollection;

    if (semester != null) {
      query = query.where('semester', isEqualTo: semester);
    }
    if (schoolYear != null) {
      query = query.where('schoolYear', isEqualTo: schoolYear);
    }
    if (roomId != null) {
      query = query.where('roomId', isEqualTo: roomId);
    }
    if (teacherId != null) {
      query = query.where('teacherId', isEqualTo: teacherId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }

  Future<String> addBooking(Booking booking) async {
    final hasConflict = await _checkBookingConflict(booking);
    if (hasConflict) {
      throw Exception('Booking conflicts with existing schedule');
    }

    final docRef = await bookingsCollection.add(booking.toFirestore());
    await _updateRoomStatusFromBooking(booking);
    return docRef.id;
  }

  Future<void> updateBooking(Booking booking) async {
    await bookingsCollection.doc(booking.id).update(booking.toFirestore());
    await _updateRoomStatusFromBooking(booking);
  }

  Future<void> deleteBooking(String bookingId) async {
    await bookingsCollection.doc(bookingId).delete();
  }

  Future<void> batchAddBookings(List<Booking> bookings) async {
    final batch = _firestore.batch();

    for (final booking in bookings) {
      final docRef = bookingsCollection.doc();
      batch.set(docRef, booking.toFirestore());
    }

    await batch.commit();
  }

  Future<bool> _checkBookingConflict(Booking newBooking) async {
    final existingBookings = await getBookings(
      roomId: newBooking.roomId,
      semester: newBooking.semester,
      schoolYear: newBooking.schoolYear,
    );

    for (final existing in existingBookings) {
      if (existing.id != newBooking.id &&
          existing.dayOfWeek == newBooking.dayOfWeek &&
          existing.conflictsWith(newBooking)) {
        return true;
      }
    }

    final teacherBookings = await getBookings(
      teacherId: newBooking.teacherId,
      semester: newBooking.semester,
      schoolYear: newBooking.schoolYear,
    );

    for (final existing in teacherBookings) {
      if (existing.id != newBooking.id &&
          existing.dayOfWeek == newBooking.dayOfWeek &&
          existing.conflictsWith(newBooking)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _updateRoomStatusFromBooking(Booking booking) async {
    final now = DateTime.now();
    final bookingDay = _getDayOfWeekNumber(booking.dayOfWeek);
    final currentDay = now.weekday;

    if (bookingDay == currentDay) {
      final startTime = _parseTime(booking.startTime);
      final endTime = _parseTime(booking.endTime);
      final currentTime = TimeOfDay.fromDateTime(now);

      if (_isTimeBetween(currentTime, startTime, endTime)) {
        await updateRoomStatus(booking.roomId, RoomStatus.occupied);
      }
    }
  }

  int _getDayOfWeekNumber(String day) {
    final days = {
      'monday': 1, 'tuesday': 2, 'wednesday': 3,
      'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7
    };
    return days[day.toLowerCase()] ?? 1;
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  // ==================== CONFLICT OPERATIONS ====================

  Stream<List<Conflict>> getConflictsStream({ConflictStatus? status}) {
    Query query = conflictsCollection;

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.orderBy('detectedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Conflict.fromFirestore(doc)).toList();
    });
  }

  Future<String> addConflict(Conflict conflict) async {
    final docRef = await conflictsCollection.add(conflict.toFirestore());
    return docRef.id;
  }

  Future<void> resolveConflict(
      String conflictId, String resolution, String resolvedBy) async {
    await conflictsCollection.doc(conflictId).update({
      'status': ConflictStatus.resolved.name,
      'resolution': resolution,
      'resolvedAt': Timestamp.now(),
      'resolvedBy': resolvedBy,
    });
  }

  // ==================== SETTINGS OPERATIONS (NEW) ====================

  /// Load app-wide settings from Firestore.
  /// Returns null if not yet configured.
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final doc = await settingsDocument.get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load settings: $e');
    }
  }

  /// Save (merge) settings to Firestore. Partial updates are supported.
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      await settingsDocument.set(
        {
          ...settings,
          'updatedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  /// Stream of settings document for real-time updates.
  Stream<Map<String, dynamic>?> getSettingsStream() {
    return settingsDocument.snapshots().map((doc) {
      if (doc.exists) return doc.data() as Map<String, dynamic>;
      return null;
    });
  }

  // ==================== PUBLISHED SCHEDULES (NEW) ====================

  /// Records a publish event in the published_schedules collection.
  /// Called by SchedulerService.publishSchedule() after bookings are committed.
  Future<String> publishScheduleRecord({
    required String semester,
    required String schoolYear,
    required int totalBookings,
    required String publishedBy,
    double successRate = 0,
    int conflictCount = 0,
  }) async {
    try {
      final docRef = await publishedSchedulesCollection.add({
        'semester': semester,
        'schoolYear': schoolYear,
        'totalBookings': totalBookings,
        'publishedBy': publishedBy,
        'successRate': successRate,
        'conflictCount': conflictCount,
        'status': 'active',
        'publishedAt': Timestamp.now(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to record publish: $e');
    }
  }

  /// Stream of all published schedule records, newest first.
  /// Used by the dashboard and reports screens.
  Stream<List<Map<String, dynamic>>> getPublishedSchedulesStream() {
    return publishedSchedulesCollection
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  /// Returns the most recently published schedule record, or null.
  Future<Map<String, dynamic>?> getLatestPublishedSchedule() async {
    final snap = await publishedSchedulesCollection
        .orderBy('publishedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data() as Map<String, dynamic>;
    data['id'] = snap.docs.first.id;
    return data;
  }

  // ==================== ANALYTICS & REPORTS ====================

  Future<Map<String, dynamic>> getTeacherLoadReport(String teacherId) async {
    final teacher = await getTeacher(teacherId);
    if (teacher == null) throw Exception('Teacher not found');

    final bookings = await getBookings(teacherId: teacherId);

    final subjectCount = <String, int>{};
    final roomCount = <String, int>{};
    int totalHours = 0;

    for (final booking in bookings) {
      subjectCount[booking.subjectName ?? 'Unknown'] =
          (subjectCount[booking.subjectName] ?? 0) + 1;
      roomCount[booking.roomName ?? 'Unknown'] =
          (roomCount[booking.roomName] ?? 0) + 1;

      final start = _parseTime(booking.startTime);
      final end = _parseTime(booking.endTime);
      final duration = (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
      totalHours += duration ~/ 60;
    }

    return {
      'teacherName': teacher.name,
      'totalBookings': bookings.length,
      'totalHours': totalHours,
      'maxHours': teacher.maxWeeklyHours,
      'utilization': (totalHours / teacher.maxWeeklyHours * 100).toStringAsFixed(1),
      'subjects': subjectCount,
      'rooms': roomCount,
      'isOverloaded': totalHours > teacher.maxWeeklyHours,
    };
  }

  Future<Map<String, dynamic>> getRoomUtilizationReport(String roomId) async {
    final room = await getRoom(roomId);
    if (room == null) throw Exception('Room not found');

    final bookings = await getBookings(roomId: roomId);

    const availableHoursPerWeek = 12 * 5;
    int bookedHours = 0;

    final dayDistribution = <String, int>{
      'monday': 0,
      'tuesday': 0,
      'wednesday': 0,
      'thursday': 0,
      'friday': 0
    };

    for (final booking in bookings) {
      final start = _parseTime(booking.startTime);
      final end = _parseTime(booking.endTime);
      final duration = (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
      final hours = duration ~/ 60;

      bookedHours += hours;
      dayDistribution[booking.dayOfWeek.toLowerCase()] =
          (dayDistribution[booking.dayOfWeek.toLowerCase()] ?? 0) + hours;
    }

    return {
      'roomName': room.name,
      'totalBookings': bookings.length,
      'bookedHours': bookedHours,
      'availableHours': availableHoursPerWeek,
      'utilizationPercentage':
      (bookedHours / availableHoursPerWeek * 100).toStringAsFixed(1),
      'dayDistribution': dayDistribution,
    };
  }
  // Add to lib/services/firestore_service.dart

  /// Stream of published schedules with full data

  /// Get all bookings without filter (for schedule management)
  Future<List<Booking>> getAllBookings() async {
    final snapshot = await bookingsCollection
        .orderBy('dayOfWeek')
        .orderBy('startTime')
        .get();
    return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
  }
}
