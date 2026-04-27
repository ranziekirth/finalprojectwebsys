//lib/models/subject_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_model.dart';

class Subject {
  final String id;
  final String code;
  final String name;
  final String department;
  final int units;
  final int requiredHoursPerWeek;
  final RoomType preferredRoomType;
  final List<String> requiredEquipment;
  final int maxStudents;
  final List<String> eligibleTeachers; // Teacher IDs who can teach this
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    required this.units,
    required this.requiredHoursPerWeek,
    required this.preferredRoomType,
    required this.requiredEquipment,
    this.maxStudents = 30,
    this.eligibleTeachers = const [],
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subject(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      department: data['department'] ?? '',
      units: data['units'] ?? 0,
      requiredHoursPerWeek: data['requiredHoursPerWeek'] ?? 0,
      preferredRoomType: RoomType.values.firstWhere(
            (e) => e.name == data['preferredRoomType'],
        orElse: () => RoomType.lecture,
      ),
      requiredEquipment: List<String>.from(data['requiredEquipment'] ?? []),
      maxStudents: data['maxStudents'] ?? 30,
      eligibleTeachers: List<String>.from(data['eligibleTeachers'] ?? []),
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'department': department,
      'units': units,
      'requiredHoursPerWeek': requiredHoursPerWeek,
      'preferredRoomType': preferredRoomType.name,
      'requiredEquipment': requiredEquipment,
      'maxStudents': maxStudents,
      'eligibleTeachers': eligibleTeachers,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ADD copyWith METHOD
  Subject copyWith({
    String? id,
    String? code,
    String? name,
    String? department,
    int? units,
    int? requiredHoursPerWeek,
    RoomType? preferredRoomType,
    List<String>? requiredEquipment,
    int? maxStudents,
    List<String>? eligibleTeachers,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      department: department ?? this.department,
      units: units ?? this.units,
      requiredHoursPerWeek: requiredHoursPerWeek ?? this.requiredHoursPerWeek,
      preferredRoomType: preferredRoomType ?? this.preferredRoomType,
      requiredEquipment: requiredEquipment ?? this.requiredEquipment,
      maxStudents: maxStudents ?? this.maxStudents,
      eligibleTeachers: eligibleTeachers ?? this.eligibleTeachers,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
