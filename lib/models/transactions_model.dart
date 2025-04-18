import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String status; // pending, completed, cancelled
  final DateTime timestamp;
  final String? imageUrl;
  final String? buyerName;
  final String? sellerName;
  final String? paymentMethod;
  final String? paymentPhone;  // Added this field
  final String? paymentTrxId;  // Added this field
  final String? deliveryAddress;
  final String? notes;

  TransactionModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.status = 'pending',
    required this.timestamp,
    this.imageUrl,
    this.buyerName,
    this.sellerName,
    this.paymentMethod,
    this.paymentPhone,  // Added to constructor
    this.paymentTrxId,  // Added to constructor
    this.deliveryAddress,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'status': status,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
      'buyerName': buyerName,
      'sellerName': sellerName,
      'paymentMethod': paymentMethod,
      'paymentPhone': paymentPhone,  // Added to toMap
      'paymentTrxId': paymentTrxId,  // Added to toMap
      'deliveryAddress': deliveryAddress,
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity']?.toInt() ?? 1,
      status: map['status'] ?? 'pending',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      imageUrl: map['imageUrl'],
      buyerName: map['buyerName'],
      sellerName: map['sellerName'],
      paymentMethod: map['paymentMethod'],
      paymentPhone: map['paymentPhone'],  // Added to fromMap
      paymentTrxId: map['paymentTrxId'],  // Added to fromMap
      deliveryAddress: map['deliveryAddress'],
      notes: map['notes'],
    );
  }

  TransactionModel copyWith({
    String? id,
    String? buyerId,
    String? sellerId,
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    String? status,
    DateTime? timestamp,
    String? imageUrl,
    String? buyerName,
    String? sellerName,
    String? paymentMethod,
    String? paymentPhone,  // Added to copyWith
    String? paymentTrxId,  // Added to copyWith
    String? deliveryAddress,
    String? notes,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      buyerName: buyerName ?? this.buyerName,
      sellerName: sellerName ?? this.sellerName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentPhone: paymentPhone ?? this.paymentPhone,  // Added
      paymentTrxId: paymentTrxId ?? this.paymentTrxId,  // Added
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  double get totalAmount => price * quantity;

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  static List<String> get statusOptions => [
    'pending',
    'completed',
    'cancelled',
  ];
}