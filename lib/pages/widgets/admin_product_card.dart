import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/cart_item_model.dart';
import 'package:myapp/models/product_model.dart';
import 'package:provider/provider.dart';
//import '../models/cart_item_model.dart';
//import '../models/product_model.dart';
import '../services/cart_service.dart';

class AdminProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AdminProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: AspectRatio(
              aspectRatio: 1,
              child:
                  product.imageUrl.isNotEmpty
                      ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                      : _buildImagePlaceholder(),
            ),
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name and Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.isAvailable)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      )
                    else
                      const Icon(
                        Icons.remove_circle,
                        color: Colors.red,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Price and Stock
                Row(
                  children: [
                    Text(
                      '৳${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Stock: ${product.quantity}',
                      style: TextStyle(
                        color: product.quantity > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Category
                if (product.category.isNotEmpty) ...[
                  Text(
                    product.category,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                ],

                // Action Buttons
                Row(
                  children: [
                    if (onEdit != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onEdit,
                          child: const Text('Edit'),
                        ),
                      ),
                    if (onEdit != null && onDelete != null)
                      const SizedBox(width: 8),
                    if (onDelete != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDelete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                  ],
                ),

                // Add to Cart Button
                if (product.quantity > 0) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        cartService.addToCart(
                          userId,
                          CartItemModel(
                            productId: product.id,
                            name: product.name,
                            imageUrl: product.imageUrl,
                            price: product.price,
                            // Suggested code may be subject to a license. Learn more: ~LicenseLog:2454431677.
                            sellerId: product.sellerId,
                            quantity: 1,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${product.name} to cart'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
      ),
    );
  }
}

extension on ProductModel {
  get sellerId => null;
}
