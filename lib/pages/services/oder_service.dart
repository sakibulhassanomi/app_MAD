import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/order_model.dart' as models;

class OrderService {
  final FirebaseFirestore firestore;

  OrderService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new order
  Future<models.Order> createOrder({
    required String buyerId,
    required String sellerId,
    required String productId,
    required int quantity,
    required double price,
    String? paymentMethod,
    String? transactionId,
    String? shippingAddress,
    models.OrderStatus status = models.OrderStatus.pending,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = await firestore.collection('orders').add({
        'buyerId': buyerId,
        'sellerId': sellerId,
        'productId': productId,
        'quantity': quantity,
        'price': price,
        'totalAmount': price * quantity,
        'status': status.toString().split('.').last,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (transactionId != null) 'transactionId': transactionId,
        if (shippingAddress != null) 'shippingAddress': shippingAddress,
      });

      return models.Order(
        id: docRef.id,
        buyerId: buyerId,
        sellerId: sellerId,
        productId: productId,
        quantity: quantity,
        price: price,
        status: status,
        createdAt: now,
        updatedAt: now,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        shippingAddress: shippingAddress,
      );
    } catch (e) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }

  // Get all orders (including admin dashboard version)
  Stream<List<models.Order>> getAllOrders({
    String? userId,
    bool forBuyer = true,
    String? status,
    int limit = 20,
  }) {
    Query query = firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (userId != null) {
      query = query.where(forBuyer ? 'buyerId' : 'sellerId', isEqualTo: userId);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => models.Order.fromFirestore(doc)).toList());
  }

  // Get orders by buyer ID
  Stream<List<models.Order>> getOrdersByBuyer(String buyerId) {
    return firestore
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => models.Order.fromFirestore(doc))
        .toList());
  }

  // Get orders by seller ID
  Stream<List<models.Order>> getOrdersBySeller(String sellerId) {
    return firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => models.Order.fromFirestore(doc))
        .toList());
  }

  // Get total count of orders
  Stream<int> getTotalOrderCount({String? userId, bool forBuyer = true}) {
    Query query = firestore.collection('orders');

    if (userId != null) {
      query = query.where(forBuyer ? 'buyerId' : 'sellerId', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) => snapshot.size);
  }

  // Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required models.OrderStatus status,
  }) async {
    try {
      await firestore.collection('orders').doc(orderId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: ${e.toString()}');
    }
  }

  // Delete an order
  Future<void> deleteOrder(String orderId) async {
    try {
      await firestore.collection('orders').doc(orderId).delete();
    } catch (e) {
      throw Exception('Failed to delete order: ${e.toString()}');
    }
  }

  // Get single order by ID
  Future<models.Order?> getOrderById(String orderId) async {
    try {
      final doc = await firestore.collection('orders').doc(orderId).get();
      return doc.exists ? models.Order.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get order: ${e.toString()}');
    }
  }
}