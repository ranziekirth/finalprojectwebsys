// lib/models/schedule_model.dart
enum ScheduleStatus { scheduled, pending, conflict, cancelled }

class ScheduleEntry {
  final String id;
  final String roomId;
  final String teacherId;
  final String subjectId;
  final String day;
  final String startTime;
  final String endTime;
  final ScheduleStatus status;
  final String? conflictReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ScheduleEntry({
    required this.id,
    required this.roomId,
    required this.teacherId,
    required this.subjectId,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.status = ScheduleStatus.scheduled,
    this.conflictReason,
    required this.createdAt,
    this.updatedAt,
  });
}

class Conflict {
  final String id;
  final String type; // 'room', 'teacher', 'equipment'
  final String description;
  final List<String> affectedScheduleIds;
  final DateTime detectedAt;
  final bool isResolved;

  Conflict({
    required this.id,
    required this.type,
    required this.description,
    required this.affectedScheduleIds,
    required this.detectedAt,
    this.isResolved = false,
  });
}