// lib/providers/teacher_provider.dart - MISSING FILE
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_model.dart';
import '../services/firestore_service.dart';

class TeacherProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Teacher> _teachers = [];
  List<Teacher> get teachers => _teachers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Stream<List<Teacher>>? _teachersStream;

  void init() {
    _loadTeachers();
  }

  void _loadTeachers() {
    _isLoading = true;
    notifyListeners();

    _teachersStream = _firestore.getTeachersStream();
    _teachersStream!.listen(
          (teachers) {
        _teachers = teachers;
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
    _loadTeachers();
  }

  Future<void> addTeacher(Teacher teacher) async {
    try {
      await _firestore.addTeacher(teacher);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTeacher(Teacher teacher) async {
    try {
      await _firestore.updateTeacher(teacher);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTeacher(String teacherId) async {
    try {
      await _firestore.deleteTeacher(teacherId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  List<Teacher> searchTeachers(String query) {
    if (query.isEmpty) return _teachers;
    return _teachers.where((t) =>
    t.name.toLowerCase().contains(query.toLowerCase()) ||
        t.email.toLowerCase().contains(query.toLowerCase()) ||
        t.department.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Teacher? getTeacherById(String id) {
    try {
      return _teachers.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}