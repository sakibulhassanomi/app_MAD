import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/user_model.dart';
//import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore;

  // Constructor with dependency injection for testing
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get stream of all consumers
  Stream<List<UserModel>> getConsumers() {
    return _firestore.collection('users')
        .where('role', isEqualTo: 'consumer')
        .snapshots()
        .handleError((error) {
      throw 'Failed to load consumers: ${error.toString()}';
    })
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return UserModel.fromFirestore(doc);
        } catch (e) {
          throw 'Failed to parse consumer data: ${e.toString()}';
        }
      }).toList();
    });
  }

  /// Get single user by ID
  Future<UserModel?> getUserById(String userId) async {
    if (userId.isEmpty) return null;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (e) {
      throw 'Failed to get user: ${e.toString()}';
    }
  }

  /// Get stream of a single user by ID
  Stream<UserModel?> getUserStreamById(String userId) {
    if (userId.isEmpty) return Stream.value(null);

    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    }).handleError((error) {
      throw 'Failed to stream user: ${error.toString()}';
    });
  }

  /// Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      throw 'Failed to update profile: ${e.toString()}';
    }
  }

  /// Get consumer's saved addresses
  Future<List<String>> getSavedAddresses(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['savedAddresses'] ?? []);
      }
      return [];
    } catch (e) {
      throw 'Failed to get saved addresses: ${e.toString()}';
    }
  }

  /// Update consumer's saved addresses
  Future<void> updateSavedAddresses(String userId, List<String> addresses) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'savedAddresses': addresses,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update addresses: ${e.toString()}';
    }
  }

  /// Get consumer's payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['paymentMethods'] ?? []);
      }
      return [];
    } catch (e) {
      throw 'Failed to get payment methods: ${e.toString()}';
    }
  }
}