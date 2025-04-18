import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';


 
class CartItemModel {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String sellerId;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.sellerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'sellerId': sellerId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as int?) ?? 1,
      sellerId: map['sellerId']?.toString() ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory CartItemModel.fromJson(String source) =>
      CartItemModel.fromMap(json.decode(source));

  CartItemModel copyWith({
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    String? sellerId,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      sellerId: sellerId ?? this.sellerId,
    );
  }

  CartItemModel increment([int amount = 1]) => copyWith(quantity: quantity + amount);

  CartItemModel decrement([int amount = 1]) {
    assert(quantity >= amount, 'Quantity cannot be negative');
    return copyWith(quantity: quantity - amount);
  }

  double get total => price * quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CartItemModel &&
              runtimeType == other.runtimeType &&
              productId == other.productId &&
              name == other.name &&
              imageUrl == other.imageUrl &&
              price == other.price &&
              quantity == other.quantity &&
              sellerId == other.sellerId;

  @override
  int get hashCode =>
      productId.hashCode ^
      name.hashCode ^
      imageUrl.hashCode ^
      price.hashCode ^
      quantity.hashCode ^
      sellerId.hashCode;

  @override
  String toString() {
    return 'CartItemModel('
        'productId: $productId, '
        'name: $name, '
        'price: $price, '
        'quantity: $quantity, '
        'sellerId: $sellerId)';
  }
}