// lib/models/published_schedule_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum PublishStatus { active, archived, draft }

class PublishedSchedule {
  final String id;
  final String semester;
  final String schoolYear;
  final int totalBookings;
  final String publishedBy;
  final String? publishedByName;
  final double successRate;
  final int conflictCount;
  final PublishStatus status;
  final DateTime publishedAt;
  final DateTime? archivedAt;
  final Map<String, dynamic>? metadata;

  PublishedSchedule({
    required this.id,
    required this.semester,
    required this.schoolYear,
    required this.totalBookings,
    required this.publishedBy,
    this.publishedByName,
    this.successRate = 0,
    this.conflictCount = 0,
    this.status = PublishStatus.active,
    required this.publishedAt,
    this.archivedAt,
    this.metadata,
  });

  factory PublishedSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PublishedSchedule(
      id: doc.id,
      semester: data['semester'] ?? '',
      schoolYear: data['schoolYear'] ?? '',
      totalBookings: data['totalBookings'] ?? 0,
      publishedBy: data['publishedBy'] ?? '',
      publishedByName: data['publishedByName'],
      successRate: (data['successRate'] ?? 0).toDouble(),
      conflictCount: data['conflictCount'] ?? 0,
      status: PublishStatus.values.firstWhere(
            (e) => e.name == (data['status'] ?? 'active'),
        orElse: () => PublishStatus.active,
      ),
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      archivedAt: data['archivedAt'] != null
          ? (data['archivedAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'semester': semester,
      'schoolYear': schoolYear,
      'totalBookings': totalBookings,
      'publishedBy': publishedBy,
      'publishedByName': publishedByName,
      'successRate': successRate,
      'conflictCount': conflictCount,
      'status': status.name,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'metadata': metadata,
    };
  }

  bool get isActive => status == PublishStatus.active;
  bool get isArchived => status == PublishStatus.archived;

  String get displayTitle => '$semester - $schoolYear';
}