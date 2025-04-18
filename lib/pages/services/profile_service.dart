import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
///import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get consumer profile
  Future<Map<String, dynamic>> getProfile(String userId) async {
    final doc = await _firestore.collection('consumers').doc(userId).get();
    return doc.data() ?? {};
  }

  // Update consumer profile
  Future<void> updateProfile(
    String userId, {
    required String name,
    required String phone,
    required String district,
    required String village,
    String? imageUrl, required String address,
  }) async {
    await _firestore.collection('consumers').doc(userId).update({
      'name': name,
      'phone': phone,
      'district': district,
      'village': village,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Upload profile image
  Future<String> uploadImage(File image, dynamic FirebaseStorage, {required String userId}) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance
        .ref()
        .child('consumer_profile_images')
        .child('$userId.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  // Get consumer-specific data (example: saved addresses)
  Future<List<String>> getSavedAddresses(String userId) async {
    final doc = await _firestore.collection('consumers').doc(userId).get();
    final data = doc.data();
    return List<String>.from(data?['savedAddresses'] ?? []);
  }

  // Update consumer-specific preferences (example: dietary preferences)
  Future<void> updatePreferences(
    String userId, {
    List<String>? dietaryPreferences,
    bool? newsletterSubscription,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (dietaryPreferences != null) {
      updateData['dietaryPreferences'] = dietaryPreferences;
    }
    if (newsletterSubscription != null) {
      updateData['newsletterSubscription'] = newsletterSubscription;
    }

    await _firestore.collection('consumers').doc(userId).update(updateData);
  }
}