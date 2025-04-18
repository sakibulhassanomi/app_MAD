

import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, processing, completed, cancelled, refunded }

class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final int quantity;
  final double price;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? paymentMethod;
  final String? transactionId;
  final String? shippingAddress;

  Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.paymentMethod,
    this.transactionId,
    this.shippingAddress,
  }) : totalAmount = price * quantity;

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      productId: data['productId'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      status: _parseOrderStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: data['paymentMethod'],
      transactionId: data['transactionId'],
      shippingAddress: data['shippingAddress'],
    );
  }

  static OrderStatus _parseOrderStatus(dynamic status) {
    if (status == null) return OrderStatus.pending;

    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'processing':
        return OrderStatus.processing;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'productId': productId,
      'quantity': quantity,
      'price': price,
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (transactionId != null) 'transactionId': transactionId,
      if (shippingAddress != null) 'shippingAddress': shippingAddress,
    };
  }

  String get formattedStatus {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String get formattedDate =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';
}