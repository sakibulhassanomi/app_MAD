// product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class ProductModel {
  final String id;
  final String farmerId;
  final String farmerName;
  final String? farmerImage;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String category;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;
  final List<String>? additionalImages;

  ProductModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    this.farmerImage,
    required this.name,
    this.description = '',
    required this.price,
    required this.quantity,
    this.category = 'General',
    this.imageUrl = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isAvailable = true,
    this.additionalImages,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel.fromMap(data, doc.id);
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? 'Farmer',
      farmerImage: map['farmerImage'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      category: map['category'] ?? 'General',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
      isAvailable: map['isAvailable'] ?? true,
      additionalImages: map['additionalImages'] != null
          ? List<String>.from(map['additionalImages'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'farmerName': farmerName,
      if (farmerImage != null) 'farmerImage': farmerImage,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isAvailable': isAvailable,
      if (additionalImages != null) 'additionalImages': additionalImages,
    };
  }

  ProductModel copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    String? farmerImage,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
    List<String>? additionalImages,
  }) {
    return ProductModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerImage: farmerImage ?? this.farmerImage,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      additionalImages: additionalImages ?? this.additionalImages,
    );
  }

  bool get hasImages => imageUrl.isNotEmpty || (additionalImages?.isNotEmpty ?? false);

  Widget getMainImageWidget({
    double width = 100,
    double height = 100,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(width, height);
    }
    return _buildNetworkImage(imageUrl, width, height, fit);
  }

  Widget getAdditionalImagesWidget({
    double width = 80,
    double height = 80,
    BoxFit fit = BoxFit.cover,
  }) {
    if (additionalImages == null || additionalImages!.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: additionalImages!.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildNetworkImage(additionalImages![index], width, height, fit),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkImage(String url, double width, double height, BoxFit fit) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(width, height),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ProductModel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              farmerId == other.farmerId &&
              farmerName == other.farmerName &&
              farmerImage == other.farmerImage &&
              name == other.name &&
              description == other.description &&
              price == other.price &&
              quantity == other.quantity &&
              category == other.category &&
              imageUrl == other.imageUrl &&
              createdAt == other.createdAt &&
              updatedAt == other.updatedAt &&
              isAvailable == other.isAvailable &&
              listEquals(additionalImages, other.additionalImages);

  @override
  int get hashCode =>
      id.hashCode ^
      farmerId.hashCode ^
      farmerName.hashCode ^
      farmerImage.hashCode ^
      name.hashCode ^
      description.hashCode ^
      price.hashCode ^
      quantity.hashCode ^
      category.hashCode ^
      imageUrl.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      isAvailable.hashCode ^
      (additionalImages?.hashCode ?? 0);
}