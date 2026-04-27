// lib/providers/subject_provider.dart - MISSING FILE
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';
import '../services/firestore_service.dart';

class SubjectProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Subject> _subjects = [];
  List<Subject> get subjects => _subjects;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Stream<List<Subject>>? _subjectsStream;

  void init() {
    _loadSubjects();
  }

  void _loadSubjects() {
    _isLoading = true;
    notifyListeners();

    _subjectsStream = _firestore.getSubjectsStream();
    _subjectsStream!.listen(
          (subjects) {
        _subjects = subjects;
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
    _loadSubjects();
  }

  Future<void> addSubject(Subject subject) async {
    try {
      await _firestore.addSubject(subject);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      await _firestore.updateSubject(subject);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await _firestore.deleteSubject(subjectId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  List<Subject> searchSubjects(String query) {
    if (query.isEmpty) return _subjects;
    return _subjects.where((s) =>
    s.name.toLowerCase().contains(query.toLowerCase()) ||
        s.code.toLowerCase().contains(query.toLowerCase()) ||
        s.department.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Subject? getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}