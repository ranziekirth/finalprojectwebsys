// lib/models/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String roomId;
  final String teacherId;
  final String subjectId;
  final String dayOfWeek; // "monday", "tuesday", etc.
  final String startTime; // "07:00"
  final String endTime; // "08:30"
  final DateTime? specificDate; // For one-time bookings
  final bool isRecurring; // true for semester schedule
  final String semester;
  final String schoolYear;
  final BookingStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy; // Admin ID

  // Expanded fields (populated from joins)
  String? roomName;
  String? teacherName;
  String? subjectName;
  String? subjectCode;

  Booking({
    required this.id,
    required this.roomId,
    required this.teacherId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.specificDate,
    this.isRecurring = true,
    required this.semester,
    required this.schoolYear,
    this.status = BookingStatus.active,
    this.notes,
    this.createdBy,
    this.roomName,
    this.teacherName,
    this.subjectName,
    this.subjectCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      teacherId: data['teacherId'] ?? '',
      subjectId: data['subjectId'] ?? '',
      dayOfWeek: data['dayOfWeek'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      specificDate: data['specificDate'] != null
          ? (data['specificDate'] as Timestamp).toDate()
          : null,
      isRecurring: data['isRecurring'] ?? true,
      semester: data['semester'] ?? '',
      schoolYear: data['schoolYear'] ?? '',
      status: BookingStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => BookingStatus.active,
      ),
      notes: data['notes'],
      createdBy: data['createdBy'],
      roomName: data['roomName'],
      teacherName: data['teacherName'],
      subjectName: data['subjectName'],
      subjectCode: data['subjectCode'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'teacherId': teacherId,
      'subjectId': subjectId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'specificDate': specificDate != null
          ? Timestamp.fromDate(specificDate!)
          : null,
      'isRecurring': isRecurring,
      'semester': semester,
      'schoolYear': schoolYear,
      'status': status.name,
      'notes': notes,
      'createdBy': createdBy,
      'roomName': roomName,
      'teacherName': teacherName,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DateTime get startDateTime {
    // Helper to convert to DateTime for comparisons
    return DateTime.parse('2024-01-01 $startTime:00');
  }

  DateTime get endDateTime {
    return DateTime.parse('2024-01-01 $endTime:00');
  }

  bool conflictsWith(Booking other) {
    if (dayOfWeek != other.dayOfWeek &&
        specificDate?.day != other.specificDate?.day) {
      return false;
    }
    // Time overlap check
    return !(endDateTime.isBefore(other.startDateTime) ||
        startDateTime.isAfter(other.endDateTime));
  }
}

enum BookingStatus { active, cancelled, completed, pending }
