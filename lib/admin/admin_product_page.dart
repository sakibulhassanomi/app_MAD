
import 'package:flutter/material.dart';
import 'package:myapp/admin/admin_products/admin_product_card.dart';
import 'package:myapp/pages/services/product_service.dart';
import 'package:provider/provider.dart';
// import '../services/product_service.dart';
// import '../widgets/admin_product_card.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmers Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => productService.getMarketplaceProducts(),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: productService.getMarketplaceProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No products available'));
          }

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