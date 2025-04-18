//import 'package:apps/pages/product/upload_product_pages.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/pages/product/upload_product_page.dart';
import 'package:myapp/pages/services/cart_service.dart';
import 'package:myapp/pages/services/product_service.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
// import '../../services/product_service.dart';
// import '../../services/cart_service.dart';
// import '../../widgets/product_grid_view.dart';
import '../widgets/product_grid_view.dart';
//import '../product/upload_product_page.dart';

class ProductListPage extends StatefulWidget {
  final bool isAdminView;
  final bool isFarmerView;
  final List<String> productCategories;
  final String? farmerId;

  const ProductListPage({
    super.key,
    this.isAdminView = false,
    this.isFarmerView = false,
    required this.productCategories,
    this.farmerId,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late final String userId;
  late final ProductService _productService;
  late Stream<List<ProductModel>> _productsStream;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _productService = Provider.of<ProductService>(context, listen: false);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    setState(() {
      if (widget.isAdminView) {
        _productsStream = _productService.getAllProducts();
      } else if (widget.isFarmerView) {
        _productsStream = _productService.getProductsByFarmerId(userId);
      } else {
        _productsStream = widget.farmerId != null
            ? _productService.getProductsByFarmerId(widget.farmerId!)
            : _productService.getMarketplaceProducts();
      }
    });
  }

  Future<void> _refreshProducts() async {
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isAdminView || widget.isFarmerView
          ? AppBar(
        title: Text(widget.isAdminView ? 'All Products' : 'My Products'),
        actions: [
          if (!widget.isAdminView) ...[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToEditProduct(context, null),
              tooltip: 'Add Product',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
            tooltip: 'Refresh',
          ),
        ],
      )
          : null,
      body: Column(
        children: [
          if (!widget.isAdminView && !widget.isFarmerView) ...[
            _buildSearchField(),
            _buildCategoryFilter(),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshProducts,
              child: StreamBuilder<List<ProductModel>>(
                stream: _productsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  List<ProductModel> products = snapshot.data ?? [];
                  products = _filterProducts(products);

                  return products.isEmpty
                      ? _buildEmptyState()
                      : widget.isAdminView || widget.isFarmerView
                      ? _buildListView(products)
                      : _buildGridView(products);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isFarmerView
          ? FloatingActionButton(
        onPressed: () => _navigateToEditProduct(context, null),
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: ['All', ...widget.productCategories].length,
        itemBuilder: (context, index) {
          final category = ['All', ...widget.productCategories][index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(category),
              selected: _selectedCategory == category,
              onSelected: (selected) => setState(() {
                _selectedCategory = selected ? category : 'All';
              }),
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: _selectedCategory == category
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: _selectedCategory == category
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    // Apply category filter
    if (_selectedCategory != 'All') {
      products = products.where((p) => p.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      products = products.where((p) =>
      p.name.toLowerCase().contains(_searchQuery) ||
          (p.description.toLowerCase().contains(_searchQuery))).toList();
    }

    return products;
  }

  Widget _buildListView(List<ProductModel> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          leading: product.imageUrl.isNotEmpty
              ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
              : const Icon(Icons.shopping_bag, size: 50),
          title: Text(product.name),
          subtitle: Text('৳${product.price.toStringAsFixed(2)} | Stock: ${product.quantity}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _navigateToEditProduct(context, product),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(product.id),
              ),
            ],
          ),
          onTap: () => _viewProductDetails(context, product),
        );
      },
    );
  }

  Widget _buildGridView(List<ProductModel> products) {
    return ProductGrid(
      products: products,
      showAdminActions: widget.isAdminView,
      showFarmerActions: widget.isFarmerView,
      onProductTap: (product) => _viewProductDetails(context, product),
      onAddToCart: (product) => _addToCart(context, product),
      onEditPressed: widget.isAdminView || widget.isFarmerView
          ? (product) => _navigateToEditProduct(context, product)
          : null,
      onDeletePressed: widget.isAdminView || widget.isFarmerView
          ? (product) => _confirmDelete(product.id)
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            widget.isAdminView
                ? 'No products available'
                : widget.isFarmerView
                ? 'You haven\'t added any products yet'
                : 'No products match your search',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (widget.isFarmerView)
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add First Product'),
              onPressed: () => _navigateToEditProduct(context, null),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load products',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: _refreshProducts,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEditProduct(BuildContext context, ProductModel? product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadProductPage(
          product: product,
          productCategories: widget.productCategories,
        ),
      ),
    );

    if (mounted && result == true) {
      _refreshProducts();
    }
  }

  void _viewProductDetails(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                )
                    : _buildImagePlaceholder(),
              ),
              const SizedBox(height: 16),
              Text(
                '৳${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Stock: ${product.quantity}'),
              Text('Category: ${product.category}'),
              const SizedBox(height: 16),
              Text(product.description),
              const SizedBox(height: 16),
              if (widget.isAdminView || widget.isFarmerView)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToEditProduct(context, product);
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addToCart(context, product);
                    },
                    child: const Text('Add to Cart'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }

  void _confirmDelete(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('This will permanently remove the product. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(productId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _productService.deleteProduct(productId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshProducts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addToCart(BuildContext context, ProductModel product) async {
    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final cartItem = CartItemModel(
        productId: product.id,
        name: product.name,
        price: product.price,
        quantity: 1,
        imageUrl: product.imageUrl,
        sellerId: product.farmerId,
      );

      await cartService.addToCart(userId, cartItem);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${product.name} to cart'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}