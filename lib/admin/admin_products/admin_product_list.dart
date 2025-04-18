
//import 'package:apps/admin/admin_products/upload_product_page.dart';
//import 'package:apps/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/pages/product/upload_product_page.dart';
import 'package:myapp/pages/services/product_service.dart';
import 'package:provider/provider.dart';
//import '../../../services/product_service.dart';
import 'admin_product_card.dart';

class AdminProductList extends StatelessWidget {
  const AdminProductList({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UploadProductPage(productCategories: [],),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: productService.getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return AdminProductCard(product: products[index]);
            },
          );
        },
      ),
    );
  }
}