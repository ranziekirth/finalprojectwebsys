//lib/providers/room_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/room_model.dart';
import '../models/booking_model.dart';
import '../models/conflict_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';


// Room Provider
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
    _roomsStream = _firestore.getRoomsStream();
    _roomsStream!.listen((rooms) {
      _rooms = rooms;
      notifyListeners();
    });
  }

  Future<void> addRoom(Room room) async {
    try {
      await _firestore.addRoom(room);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRoom(Room room) async {
    try {
      await _firestore.updateRoom(room);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _firestore.deleteRoom(roomId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<Room> getAvailableRooms() {
    return _rooms.where((r) => r.currentStatus == RoomStatus.available).toList();
  }

  List<Room> getRoomsByType(RoomType type) {
    return _rooms.where((r) => r.type == type).toList();
  }

  List<Room> searchRooms(String query) {
    return _rooms.where((r) =>
    r.name.toLowerCase().contains(query.toLowerCase()) ||
        r.building.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}

// Booking Provider
class BookingProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _selectedSemester = 'First Semester';
  String get selectedSemester => _selectedSemester;

  String _selectedSchoolYear = '2024-2025';
  String get selectedSchoolYear => _selectedSchoolYear;

  void setSemester(String semester) {
    _selectedSemester = semester;
    notifyListeners();
    _loadBookings();
  }

  void setSchoolYear(String year) {
    _selectedSchoolYear = year;
    notifyListeners();
    _loadBookings();
  }

  void _loadBookings() {
    _firestore.getBookingsStream(
      semester: _selectedSemester,
      schoolYear: _selectedSchoolYear,
    ).listen((bookings) {
      _bookings = bookings;
      notifyListeners();
    });
  }

  Future<void> addBooking(Booking booking) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.addBooking(booking);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.deleteBooking(bookingId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<Booking> getBookingsForRoom(String roomId) {
    return _bookings.where((b) => b.roomId == roomId).toList();
  }

  List<Booking> getBookingsForTeacher(String teacherId) {
    return _bookings.where((b) => b.teacherId == teacherId).toList();
  }

  List<Booking> getBookingsForDay(String day) {
    return _bookings.where((b) => b.dayOfWeek == day).toList();
  }

  List<Booking> getCurrentBookings() {
    final now = DateTime.now();
    final currentDay = _getDayName(now.weekday);
    final currentTime = TimeOfDay.fromDateTime(now);

    return _bookings.where((b) {
      if (b.dayOfWeek != currentDay) return false;
      final start = _parseTime(b.startTime);
      final end = _parseTime(b.endTime);
      return _isTimeBetween(currentTime, start, end);
    }).toList();
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
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
}

// Auth Provider
class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  User? _user;
  User? get user => _user;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  AuthProvider() {
    _auth.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _isAdmin = await _auth.isAdmin();
      } else {
        _isAdmin = false;
      }
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> createAdmin(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.createAdminUser(email, password, name);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Conflict Provider
class ConflictProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Conflict> _conflicts = [];
  List<Conflict> get conflicts => _conflicts;

  int get openConflicts => _conflicts.where((c) => c.status == ConflictStatus.open).length;

  void init() {
    _firestore.getConflictsStream(status: ConflictStatus.open).listen((conflicts) {
      _conflicts = conflicts;
      notifyListeners();
    });
  }

  Future<void> resolveConflict(String conflictId, String resolution, String resolvedBy) async {
    await _firestore.resolveConflict(conflictId, resolution, resolvedBy);
  }
}