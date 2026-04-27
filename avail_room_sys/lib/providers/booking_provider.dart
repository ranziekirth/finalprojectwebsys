// lib/providers/booking_provider.dart
import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';

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

  Stream<List<Booking>>? _bookingsStream;

  void init() {
    _loadBookings();
  }

  void _loadBookings() {
    _isLoading = true;
    notifyListeners();

    _bookingsStream = _firestore.getBookingsStream(
      semester: _selectedSemester,
      schoolYear: _selectedSchoolYear,
    );

    _bookingsStream!.listen(
          (bookings) {
        _bookings = bookings;
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}