import 'package:flutter/material.dart';
import 'package:myapp/pages/services/product_service.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
//import '../../services/product_service.dart';

class AdminProductManagement extends StatefulWidget {
  const AdminProductManagement({super.key});

  @override
  State<AdminProductManagement> createState() => _AdminProductManagementState();
}

class _AdminProductManagementState extends State<AdminProductManagement> {
  // Sample products to insert
  final List<ProductModel> sampleProducts = [
    ProductModel(
      id: 'prod1',
      name: 'Honey',
      description: 'Fresh Honey from local farms',
      price: 2.99,
      quantity: 5,
      category: 'Dairy',
      imageUrl: 'assets /images/products/honey-pot-4d7c98d.jpg',
      farmerId: 'admin',
      farmerName: 'Admin',
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod2',
      name: 'Fresh Carrots',
      description: 'Sweet and crunchy carrots',
      price: 1.49,
      quantity: 30,
      category: 'Vegetables',
      imageUrl: 'assets/images/products/basil.png',
      farmerId: 'admin',
      farmerName: 'Admin',
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod3',
      name: 'Fresh Milk',
      description: 'Organic milk from grass-fed cows',
      price: 3.99,
      quantity: 20,
      category: 'Dairy',
      imageUrl: 'assets/images/products/bread.png',
      farmerId: 'admin',
      farmerName: 'Admin',
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ProductModel(
      id: 'prod4',
      name: 'Whole Wheat Bread',
      description: 'Freshly baked whole wheat bread',
      price: 4.50,
      quantity: 15,
      category: 'Grains',
      imageUrl: 'assets/images/products/beef.png',
      farmerId: 'admin',
      farmerName: 'Admin',
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Header
          _buildStatisticsHeader(productService),

          // Sample Products Button
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: ElevatedButton.icon(
          //     icon: const Icon(Icons.add_box),
          //     label: const Text('Insert Sample Products'),
          //     onPressed: () => _insertSampleProducts(productService),
          //     style: ElevatedButton.styleFrom(
          //       minimumSize: const Size(double.infinity, 50),
          //     ),
          //   ),
          // ),

          // Products List
          Expanded(child: _buildProductsList(productService)),
        ],
      ),
    );
  }

  Widget _buildStatisticsHeader(ProductService productService) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: StreamBuilder<List<ProductModel>>(
        stream: productService.getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading products',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final products = snapshot.data ?? [];
          final totalProducts = products.length;
          final availableProducts = products.where((p) => p.isAvailable).length;
          final outOfStockProducts =
              products.where((p) => p.quantity <= 0).length;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Total Products',
                totalProducts.toString(),
                Icons.shopping_bag,
              ),
              _buildStatCard(
                'Available',
                availableProducts.toString(),
                Icons.check_circle,
                color: Colors.green,
              ),
              _buildStatCard(
                'Out of Stock',
                outOfStockProducts.toString(),
                Icons.error,
                color: Colors.red,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    Color color = Colors.blue,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildProductsList(ProductService productService) {
    return StreamBuilder<List<ProductModel>>(
      stream: productService.getAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 16),
                Text(
                  'Error loading products',
                  style: TextStyle(color: Colors.red),
                ),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey),
                SizedBox(height: 16),
                Text('No products found'),
                SizedBox(height: 8),
                Text('Add products to get started'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading:
                    product.imageUrl.isNotEmpty
                        ? Image.asset(
                          product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.shopping_bag, size: 50),
                        )
                        : const Icon(Icons.shopping_bag, size: 50),
                title: Text(product.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('৳${product.price.toStringAsFixed(2)}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Stock: ${product.quantity}',
                          style: TextStyle(
                            color:
                                product.quantity > 0
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          product.isAvailable ? 'Available' : 'Not Available',
                          style: TextStyle(
                            color:
                                product.isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProduct(productService, product),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  Future<void> _insertSampleProducts(ProductService productService) async {
    try {
      for (var product in sampleProducts) {
        await productService.saveProduct(
          product: product,
          isUpdate: false,
          ConnectivityResult: null,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample products added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProduct(
    ProductService productService,
    ProductModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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

    if (confirmed == true) {
      try {
        await productService.deleteProduct(product.id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
