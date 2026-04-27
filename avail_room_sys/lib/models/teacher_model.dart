// lib/models/teacher_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  final String id;
  final String name;
  final String email;
  final String department;
  final List<String> expertiseSubjects;
  final int maxWeeklyHours;
  final List<String> preferredTimeSlots;
  final Map<String, dynamic> unavailableSlots;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int currentWeeklyHours;
  final int activeSubjectsCount;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.expertiseSubjects,
    this.maxWeeklyHours = 20,
    this.preferredTimeSlots = const [],
    this.unavailableSlots = const {},
    this.profileImageUrl,
    this.currentWeeklyHours = 0,
    this.activeSubjectsCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Teacher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Teacher(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
      expertiseSubjects: List<String>.from(data['expertiseSubjects'] ?? []),
      maxWeeklyHours: data['maxWeeklyHours'] ?? 20,
      preferredTimeSlots: List<String>.from(data['preferredTimeSlots'] ?? []),
      unavailableSlots: Map<String, dynamic>.from(data['unavailableSlots'] ?? {}),
      profileImageUrl: data['profileImageUrl'],
      currentWeeklyHours: data['currentWeeklyHours'] ?? 0,
      activeSubjectsCount: data['activeSubjectsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'department': department,
      'expertiseSubjects': expertiseSubjects,
      'maxWeeklyHours': maxWeeklyHours,
      'preferredTimeSlots': preferredTimeSlots,
      'unavailableSlots': unavailableSlots,
      'profileImageUrl': profileImageUrl,
      'currentWeeklyHours': currentWeeklyHours,
      'activeSubjectsCount': activeSubjectsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ADD THIS METHOD
  Teacher copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    List<String>? expertiseSubjects,
    int? maxWeeklyHours,
    List<String>? preferredTimeSlots,
    Map<String, dynamic>? unavailableSlots,
    String? profileImageUrl,
    int? currentWeeklyHours,
    int? activeSubjectsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      expertiseSubjects: expertiseSubjects ?? this.expertiseSubjects,
      maxWeeklyHours: maxWeeklyHours ?? this.maxWeeklyHours,
      preferredTimeSlots: preferredTimeSlots ?? this.preferredTimeSlots,
      unavailableSlots: unavailableSlots ?? this.unavailableSlots,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      currentWeeklyHours: currentWeeklyHours ?? this.currentWeeklyHours,
      activeSubjectsCount: activeSubjectsCount ?? this.activeSubjectsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isOverloaded() => currentWeeklyHours > maxWeeklyHours;

  double get loadPercentage => (currentWeeklyHours / maxWeeklyHours * 100).clamp(0, 100);
}