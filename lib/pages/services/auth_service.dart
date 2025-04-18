import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/user_model.dart';
//import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Add currentUser getter
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String district,
    required String village,
    required String role,
    String? imageUrl,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) return null;

      final userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        district: district.trim(),
        village: village.trim(),
        role: role.trim().toLowerCase(),
        imageUrl: imageUrl,
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      notifyListeners();
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw AuthException('Registration failed: ${e.toString()}');
    }
  }

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      notifyListeners();
      return credential.user != null
          ? await _getUserData(credential.user!.uid)
          : null;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      return user != null ? await _getUserData(user.uid) : null;
    } catch (e) {
      throw AuthException('Failed to get current user: ${e.toString()}');
    }
  }

  Stream<UserModel?> get userChanges {
    return _auth.userChanges().asyncMap((user) async =>
    user != null ? await _getUserData(user.uid) : null);
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      throw AuthException('Logout failed: ${e.toString()}');
    }
  }

  Future<UserModel?> _getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (e) {
      throw DatabaseException('Failed to load user data');
    }
  }

  // Additional helper methods
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
      notifyListeners();
    } catch (e) {
      throw DatabaseException('Failed to update user profile');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw AuthException('Password reset failed: ${e.toString()}');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthException('Invalid email address');
      case 'user-disabled':
        return AuthException('Account disabled');
      case 'user-not-found':
      case 'wrong-password':
        return AuthException('Invalid credentials');
      case 'email-already-in-use':
        return AuthException('Email already used');
      case 'operation-not-allowed':
        return AuthException('Operation not allowed');
      case 'weak-password':
        return AuthException('Weak password');
      case 'too-many-requests':
        return AuthException('Too many requests. Try again later');
      default:
        return AuthException('Authentication failed');
    }
  }
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
}