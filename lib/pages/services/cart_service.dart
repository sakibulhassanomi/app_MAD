import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/cart_item_model.dart';
//import '../models/cart_item_model.dart';
//import '../models/product_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Shipping cost constants
  static const double shippingCostInsideDhaka = 60.0;
  static const double shippingCostOutsideDhaka = 120.0;

  Stream<List<CartItemModel>> getCartItems(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CartItemModel.fromMap(doc.data()))
        .toList());
  }

  Future<void> addToCart(String userId, CartItemModel item) async {
    final cartRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(item.productId);

    final doc = await cartRef.get();
    if (doc.exists) {
      await cartRef.update({
        'quantity': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await cartRef.set(item.toMap());
    }
  }

  Future<void> updateCartItem(String userId, String productId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(userId, productId);
      return;
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeItem(String userId, String productId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  Future<void> clearCart(String userId) async {
    final batch = _firestore.batch();
    final cartItems = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();

    for (var doc in cartItems.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  double calculateShipping(String district) {
    final dhakaDistricts = [
      'Dhaka', 'Gazipur', 'Narayanganj', 'Manikganj', 'Munshiganj',
      'Narsingdi', 'Tangail', 'Faridpur', 'Rajbari', 'Gopalganj',
      'Madaripur', 'Shariatpur'
    ];

    return dhakaDistricts.contains(district)
        ? shippingCostInsideDhaka
        : shippingCostOutsideDhaka;
  }

  Future<List<CartItemModel>> getCartItemsForCheckout(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();

    return snapshot.docs
        .map((doc) => CartItemModel.fromMap(doc.data()))
        .toList();
  }
}