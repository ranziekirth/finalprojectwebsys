// lib/providers/auth_provider.dart - COMPLETE WORKING VERSION
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _checkAdminStatus();
      } else {
        _isAdmin = false;
      }
      notifyListeners();
    });
  }

  Future<void> _checkAdminStatus() async {
    if (_user == null) {
      _isAdmin = false;
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _isAdmin = data['role'] == 'admin';
      } else {
        _isAdmin = false;
      }
    } catch (e) {
      _isAdmin = false;
    }
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = credential.user;
      await _checkAdminStatus();

      if (!_isAdmin) {
        await signOut();
        throw Exception('You do not have admin privileges.');
      }

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No admin found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Login failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _isAdmin = false;
    notifyListeners();
  }

  // Create admin user (for initial setup only)
  // In lib/providers/auth_provider.dart - UPDATE this method:

  Future<void> createAdminUser(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Step 1: Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2: Update display name
      await credential.user?.updateDisplayName(name);

      // Step 3: Create user document in Firestore
      // Note: This will only work if your rules allow it!
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      _user = credential.user;
      _isAdmin = true;

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      throw Exception(message);
    } catch (e) {
      // If Firestore fails but Auth succeeded, we should clean up
      // But for now just throw the error
      throw Exception('Registration failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to send reset email: ${e.message}');
    }
  }

  // Update admin profile
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    if (_user == null) throw Exception('Not logged in');

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        if (name != null) 'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}