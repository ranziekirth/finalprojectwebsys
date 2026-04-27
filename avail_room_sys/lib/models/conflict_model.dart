//lib/models/conflict_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Conflict {
  final String id;
  final ConflictType type;
  final String description;
  final List<String> involvedBookingIds;
  final List<String> involvedRoomIds;
  final List<String> involvedTeacherIds;
  final DateTime detectedAt;
  final ConflictStatus status;
  final String? resolution;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  Conflict({
    required this.id,
    required this.type,
    required this.description,
    required this.involvedBookingIds,
    required this.involvedRoomIds,
    required this.involvedTeacherIds,
    required this.detectedAt,
    this.status = ConflictStatus.open,
    this.resolution,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory Conflict.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conflict(
      id: doc.id,
      type: ConflictType.values.firstWhere(
            (e) => e.name == data['type'],
        orElse: () => ConflictType.doubleBooking,
      ),
      description: data['description'] ?? '',
      involvedBookingIds: List<String>.from(data['involvedBookingIds'] ?? []),
      involvedRoomIds: List<String>.from(data['involvedRoomIds'] ?? []),
      involvedTeacherIds: List<String>.from(data['involvedTeacherIds'] ?? []),
      detectedAt: (data['detectedAt'] as Timestamp).toDate(),
      status: ConflictStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => ConflictStatus.open,
      ),
      resolution: data['resolution'],
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: data['resolvedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'description': description,
      'involvedBookingIds': involvedBookingIds,
      'involvedRoomIds': involvedRoomIds,
      'involvedTeacherIds': involvedTeacherIds,
      'detectedAt': Timestamp.fromDate(detectedAt),
      'status': status.name,
      'resolution': resolution,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
    };
  }
}

enum ConflictType {
  doubleBooking,      // Same room double booked
  teacherOverlap,     // Teacher scheduled in two places
  roomOverload,       // Room capacity exceeded
  equipmentMismatch,  // Room missing required equipment
  teacherOverload     // Teacher exceeds max hours
}

enum ConflictStatus { open, resolved, ignored }