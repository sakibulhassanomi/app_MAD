import 'package:flutter/material.dart';
import 'package:myapp/models/product_model.dart';
//import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final double? height;
  final double? width;
  final bool showStock;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.height,
    this.width,
    this.showStock = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              _buildImageSection(context),
              
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isAvailable)
                          const Icon(Icons.check_circle, 
                            color: Colors.green, size: 16)
                        else
                          const Icon(Icons.cancel, 
                            color: Colors.red, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Price and Category
                    Row(
                      children: [
                        Text(
                          '৳${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (product.category.isNotEmpty)
                          Text(
                            product.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Stock and Actions
                    Row(
                      children: [
                        if (showStock)
                          Text(
                            product.quantity > 0 
                              ? '${product.quantity} available' 
                              : 'Out of stock',
                            style: TextStyle(
                              color: product.quantity > 0 
                                ? Colors.green 
                                : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        const Spacer(),
                        if (showActions) _buildActionButtons(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Stack(
      children: [
        // Product Image
        Container(
          height: height ?? 150,
          color: Colors.grey[100],
          child: _buildProductImage(),
        ),
        
        // Favorite Button
        if (onTap != null)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.favorite_border),
              color: Colors.white,
              onPressed: () {}, // Add favorite functionality
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: Colors.blue,
            onPressed: onEdit,
            padding: EdgeInsets.zero,
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: Colors.red,
            onPressed: onDelete,
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildProductImage() {
    if (product.imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }

    return Image.network(
      product.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
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
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return const Center(
      child: Icon(Icons.shopping_bag, size: 48, color: Colors.grey),
    );
  }
}