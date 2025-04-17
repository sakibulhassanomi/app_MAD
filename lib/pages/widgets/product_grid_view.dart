import 'package:flutter/material.dart';
import 'package:myapp/models/product_model.dart';
//import '../models/product_model.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel)? onProductTap;
  final Function(ProductModel)? onAddToCart;
  final Function(ProductModel)? onEdit;
  final Function(ProductModel)? onDelete;
  final bool showAdminControls;
  final bool showAddToCart;
  final bool isLoading;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ProductGrid({
    super.key,
    required this.products,
    this.onProductTap,
    this.onAddToCart,
    this.onEdit,
    this.onDelete,
    this.showAdminControls = false,
    this.showAddToCart = true,
    this.isLoading = false,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
    this.spacing = 12,
    this.physics,
    this.shrinkWrap = false, required bool showAdminActions, Future<void> Function(dynamic product)? onEditPressed, required bool showFarmerActions, void Function(dynamic product)? onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty && !isLoading) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: EdgeInsets.all(spacing),
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: isLoading ? products.length + 1 : products.length,
      itemBuilder: (context, index) {
        if (isLoading && index >= products.length) {
          return _buildLoadingCard();
        }
        return _buildProductCard(context, products[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, 
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No products available', 
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product Image
          _buildImageSection(product),
          
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
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.quantity <= 0)
                      const Icon(Icons.cancel, 
                          size: 16, color: Colors.red),
                  ],
                ),
                const SizedBox(height: 8),

                // Price and Stock
                Row(
                  children: [
                    Text(
                      '৳${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      product.quantity > 0 
                          ? '${product.quantity} in stock' 
                          : 'Out of stock',
                      style: TextStyle(
                        color: product.quantity > 0 
                            ? Colors.green 
                            : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons
                if (showAdminControls || showAddToCart)
                  _buildActionButtons(context, product),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ProductModel product) {
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: onProductTap != null ? () => onProductTap!(product) : null,
        child: Stack(
          children: [
            // Product Image
            product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),

            // Admin Controls
            if (showAdminControls && onDelete != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => onDelete!(product),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, 
                        size: 18, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProductModel product) {
    return Row(
      children: [
        // Edit Button (for admin)
        if (showAdminControls && onEdit != null)
          Expanded(
            child: OutlinedButton(
              onPressed: () => onEdit!(product),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Edit'),
            ),
          ),

        if (showAdminControls && onEdit != null && showAddToCart)
          const SizedBox(width: 8),

        // Add to Cart Button
        if (showAddToCart && onAddToCart != null && product.quantity > 0)
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading ? null : () => onAddToCart!(product),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add to Cart'),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
      ),
    );
  }
}