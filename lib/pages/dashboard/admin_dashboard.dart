import 'package:flutter/material.dart';
import 'package:myapp/admin/admin_product_management.dart';
import 'package:myapp/models/cart_item_model.dart';
import 'package:myapp/models/order_model.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/pages/auth/cart_page.dart';
import 'package:myapp/pages/auth/login_page.dart';
import 'package:myapp/pages/product/upload_product_page.dart';
import 'package:myapp/pages/services/auth_service.dart';
import 'package:myapp/pages/services/cart_service.dart';
import 'package:myapp/pages/services/oder_service.dart';
import 'package:myapp/pages/services/product_service.dart';
import 'package:myapp/pages/widgets/product_grid_view.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildProductsPage(),
      const AdminProductManagement(),
      _buildProfilePage(),
      _buildPaymentsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: _buildAppBarActions(),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProductsPage() {
    return Scaffold(
      body: _buildProductsGrid(showAdminActions: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddProduct(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          Consumer<AuthService>(
            builder: (context, authService, _) {
              return Text(
                authService.currentUser?.email ?? 'Admin',
                style: const TextStyle(fontSize: 20),
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _logout,
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsPage() {
    return Scaffold(
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          return StreamBuilder<List<Order>>(
            stream: orderService.getAllOrders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final orders = snapshot.data ?? [];
              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final orderIdDisplay = order.id.length >= 8
                      ? order.id.substring(0, 8)
                      : order.id;
                  final productIdDisplay = order.productId.length >= 8
                      ? '${order.productId.substring(0, 8)}...'
                      : order.productId;

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('Order #$orderIdDisplay'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Product: $productIdDisplay'),
                          Text('Qty: ${order.quantity} × \$${order.price.toStringAsFixed(2)}'),
                          Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
                          Text('Date: ${_formatDate(order.createdAt)}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          order.status.toString().split('.').last,
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                          ),
                        ),
                        backgroundColor: Color.lerp(
                          _getStatusColor(order.status),
                          Colors.white,
                          0.9,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid({bool showAdminActions = false}) {
    return Consumer<ProductService>(
      builder: (context, productService, _) {
        return StreamBuilder<List<ProductModel>>(
          stream: productService.getAllProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final products = snapshot.data ?? [];
            return ProductGrid(
              products: products,
              showAdminActions: showAdminActions,
              onProductTap: (product) => _viewProductDetails(context, product),
              onEditPressed: showAdminActions
                  ? (product) => _navigateToEditProduct(context, product)
                  : null,
              onDeletePressed: showAdminActions
                  ? (product) => _confirmDeleteProduct(context, product)
                  : null,
              onAddToCart: (product) => _addToCart(context, product), showFarmerActions: false,
            );
          },
        );
      },
    );
  }

  Future<void> _addToCart(BuildContext context, ProductModel product) async {
    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid ?? '';

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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green[800],
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Store',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payment),
          label: 'Payments',
        ),
      ],
    );
  }

  String _getAppBarTitle() {
    const titles = [
      'Products Management',
      'Store',
      'Profile',
      'Payments',
    ];
    return titles[_currentIndex];
  }

  List<Widget> _buildAppBarActions() {
    return [
      if (_currentIndex == 0)
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () => _navigateToCart(context),
          tooltip: 'View Cart',
        ),
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: _logout,
        tooltip: 'Logout',
      ),
    ];
  }

  Future<void> _navigateToAddProduct(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadProductPage(
          productCategories: const [
            'Vegetables', 'Fruits', 'Grains', 'Dairy',
            'Meat', 'Poultry', 'Seafood', 'Herbs', 'Flowers', 'Other'
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditProduct(BuildContext context, ProductModel product) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadProductPage(
          product: product,
          productCategories: const [
            'Vegetables', 'Fruits', 'Grains', 'Dairy',
            'Meat', 'Poultry', 'Seafood', 'Herbs', 'Flowers', 'Other'
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCart(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  Future<void> _viewProductDetails(BuildContext context, ProductModel product) async {
    final bool isProductsPage = _currentIndex == 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              Text(
                'Stock: ${product.quantity}',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                'Category: ${product.category}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                product.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (isProductsPage) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToEditProduct(context, product);
                    },
                    child: const Text('Edit Product'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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

  Future<void> _confirmDeleteProduct(BuildContext context, ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteProduct(context, product);
    }
  }

  Future<void> _deleteProduct(BuildContext context, ProductModel product) async {
    try {
      final productService = Provider.of<ProductService>(context, listen: false);
      await productService.deleteProduct(product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${product.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.purple;
    }
  }
}