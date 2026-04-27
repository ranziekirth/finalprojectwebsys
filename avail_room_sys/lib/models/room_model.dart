// lib/models/room_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomType { lecture, laboratory, meeting, seminar }
enum RoomStatus { available, occupied, maintenance, reserved }

class Room {
  final String id;
  final String name;
  final String building;
  final String floor;
  final int capacity;
  final RoomType type;
  final List<String> equipment;
  final RoomStatus currentStatus;
  final DateTime? maintenanceUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  Room({
    required this.id,
    required this.name,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.type,
    required this.equipment,
    this.currentStatus = RoomStatus.available,
    this.maintenanceUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      name: data['name'] ?? '',
      building: data['building'] ?? '',
      floor: data['floor'] ?? '',
      capacity: data['capacity'] ?? 0,
      type: RoomType.values.firstWhere(
            (e) => e.name == data['type'],
        orElse: () => RoomType.lecture,
      ),
      equipment: List<String>.from(data['equipment'] ?? []),
      currentStatus: RoomStatus.values.firstWhere(
            (e) => e.name == data['currentStatus'],
        orElse: () => RoomStatus.available,
      ),
      maintenanceUntil: data['maintenanceUntil'] != null
          ? (data['maintenanceUntil'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'building': building,
      'floor': floor,
      'capacity': capacity,
      'type': type.name,
      'equipment': equipment,
      'currentStatus': currentStatus.name,
      'maintenanceUntil': maintenanceUntil != null
          ? Timestamp.fromDate(maintenanceUntil!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // MAKE SURE THIS METHOD EXISTS
  Room copyWith({
    String? id,
    String? name,
    String? building,
    String? floor,
    int? capacity,
    RoomType? type,
    List<String>? equipment,
    RoomStatus? currentStatus,
    DateTime? maintenanceUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      equipment: equipment ?? this.equipment,
      currentStatus: currentStatus ?? this.currentStatus,
      maintenanceUntil: maintenanceUntil ?? this.maintenanceUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}