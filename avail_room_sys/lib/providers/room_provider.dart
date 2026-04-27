// lib/providers/room_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../services/firestore_service.dart';

class RoomProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Room> _rooms = [];
  List<Room> get rooms => _rooms;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Stream<List<Room>>? _roomsStream;

  void init() {
    _loadRooms();
  }

  void _loadRooms() {
    _isLoading = true;
    notifyListeners();

    _roomsStream = _firestore.getRoomsStream();
    _roomsStream!.listen(
          (rooms) {
        _rooms = rooms;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    _loadRooms();
  }

  Future<void> addRoom(Room room) async {
    try {
      await _firestore.addRoom(room);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRoom(Room room) async {
    try {
      await _firestore.updateRoom(room);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _firestore.deleteRoom(roomId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    try {
      await _firestore.updateRoomStatus(roomId, status);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  List<Room> getAvailableRooms() {
    return _rooms.where((r) => r.currentStatus == RoomStatus.available).toList();
  }

  List<Room> getOccupiedRooms() {
    return _rooms.where((r) => r.currentStatus == RoomStatus.occupied).toList();
  }

  List<Room> getRoomsByType(RoomType type) {
    return _rooms.where((r) => r.type == type).toList();
  }

  List<Room> getRoomsByBuilding(String building) {
    return _rooms.where((r) => r.building == building).toList();
  }

  List<Room> searchRooms(String query) {
    if (query.isEmpty) return _rooms;
    return _rooms.where((r) =>
    r.name.toLowerCase().contains(query.toLowerCase()) ||
        r.building.toLowerCase().contains(query.toLowerCase()) ||
        r.floor.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Room? getRoomById(String id) {
    try {
      return _rooms.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}