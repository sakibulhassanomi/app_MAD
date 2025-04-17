// import 'package:apps/models/cart_item_model.dart';
// import 'package:apps/models/chat_model.dart';
// import 'package:apps/models/transaction_model.dart';
// import 'package:apps/pages/transaction/payment_page.dart';
// import 'package:apps/services/cart_service.dart';
// import 'package:apps/services/chat_services.dart';
// import 'package:apps/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/cart_item_model.dart';
import 'package:myapp/models/transactions_model.dart';
import 'package:myapp/pages/services/cart_service.dart';
import 'package:myapp/pages/services/oder_service.dart';
import 'package:myapp/pages/transaction/payment_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/cart_item_model.dart';
// import '../models/transaction_model.dart';
// import '../models/chat_model.dart';
// import '../services/cart_service.dart';
// import '../services/order_service.dart';
// import '../services/chat_service.dart';
// import 'payment_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isProcessing = false;
  String _selectedDistrict = 'Dhaka';
  final List<String> _districts = [
    'Dhaka',
    'Gazipur',
    'Chittagong',
    'Sylhet',
    'Rajshahi',
    'Khulna',
    'Barisal',
    'Rangpur',
    'Mymensingh',
    'Comilla',
  ];

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _confirmClearCart,
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildCartItems(userId)),
          _buildCheckoutSection(userId),
        ],
      ),
    );
  }

  Widget _buildCartItems(String userId) {
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        return StreamBuilder<List<CartItemModel>>(
          stream: cartService.getCartItems(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final cartItems = snapshot.data ?? [];

            if (cartItems.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('Your cart is empty', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text(
                      'Add some products to get started',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Dismissible(
                  key: Key('${item.productId}-${item.sellerId}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) => _confirmItemRemoval(item.name),
                  onDismissed:
                      (direction) => _removeItem(userId, item.productId),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading:
                          item.imageUrl.isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) =>
                                          const Icon(Icons.shopping_cart),
                                ),
                              )
                              : const Icon(Icons.shopping_cart),
                      title: Text(item.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('৳${item.price.toStringAsFixed(2)} each'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed:
                                    () => _updateQuantity(userId, item, -1),
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                color: Colors.grey,
                              ),
                              SizedBox(
                                width: 30,
                                child: Text(
                                  item.quantity.toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed:
                                    () => _updateQuantity(userId, item, 1),
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '৳${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Sold by ${item.name}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCheckoutSection(String userId) {
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        return StreamBuilder<List<CartItemModel>>(
          stream: cartService.getCartItems(userId),
          builder: (context, snapshot) {
            final cartItems = snapshot.data ?? [];
            final subtotal = cartItems.fold(
              0.0,
              (totalSum, item) => totalSum + (item.price * item.quantity),
            );
            final shipping = 50.0; // Fixed shipping cost for simplicity
            final total = subtotal + shipping;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  DropdownButtonFormField(
                    value: _selectedDistrict,
                    items:
                        _districts.map((district) {
                          return DropdownMenuItem(
                            value: district,
                            child: Text(district),
                          );
                        }).toList(),
                    onChanged:
                        (value) => setState(
                          () => _selectedDistrict = value.toString(),
                        ),
                    decoration: const InputDecoration(
                      labelText: 'Delivery District',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Subtotal:', subtotal),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Shipping:', shipping),
                  const Divider(height: 24),
                  _buildSummaryRow('Total:', total, isTotal: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed:
                          _isProcessing || total == 0
                              ? null
                              : () => _processCheckout(
                                context,
                                userId,
                                total,
                                _selectedDistrict,
                              ),
                      child:
                          _isProcessing
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Proceed to Checkout',
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '৳${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Theme.of(context).primaryColor : null,
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmItemRemoval(String productName) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Remove Item'),
                content: Text('Remove $productName from your cart?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _updateQuantity(
    String userId,
    CartItemModel item,
    int change,
  ) async {
    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      final newQuantity = item.quantity + change;

      if (newQuantity <= 0) {
        final confirmed = await _confirmItemRemoval(item.name);
        if (confirmed) {
          await _removeItem(userId, item.productId);
        }
      } else {
        await cartService.updateCartItem(userId, item.productId, newQuantity);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating quantity: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeItem(String userId, String productId) async {
    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      await cartService.removeItem(userId, productId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item removed from cart')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item: ${e.toString()}')),
      );
    }
  }

  Future<void> _confirmClearCart() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cart'),
            content: const Text(
              'Are you sure you want to remove all items from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _clearCart(userId);
    }
  }

  Future<void> _clearCart(String userId) async {
    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      await cartService.clearCart(userId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart cleared')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing cart: ${e.toString()}')),
      );
    }
  }

  Future<void> _processCheckout(
    BuildContext context,
    String userId,
    double totalAmount,
    String deliveryDistrict,
  ) async {
    setState(() => _isProcessing = true);

    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);
      //final chatService = Provider.of<ChatService>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final cartItems = await cartService.getCartItems(userId).first;
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Create transactions for each item
      final transactions = <TransactionModel>[];
      final batch = FirebaseFirestore.instance.batch();

      for (final item in cartItems) {
        final transaction = TransactionModel(
          id: FirebaseFirestore.instance.collection('transactions').doc().id,
          buyerId: currentUser.uid,
          sellerId: item.sellerId,
          productId: item.productId,
          productName: item.name,
          price: item.price,
          quantity: item.quantity,
          status: 'pending',
          timestamp: DateTime.now(),
          imageUrl: item.imageUrl,
          buyerName: currentUser.displayName ?? 'Customer',
          sellerName: item.name,
          deliveryAddress: '',
        );

        transactions.add(transaction);
        batch.set(
          FirebaseFirestore.instance
              .collection('transactions')
              .doc(transaction.id),
          transaction.toMap(),
        );

        // Create order for each item
        await orderService.createOrder(
          buyerId: currentUser.uid,
          sellerId: item.sellerId,
          productId: item.productId,
          quantity: item.quantity,
          price: item.price,
        );
      }

      // Commit all transactions at once
      await batch.commit();

      // Clear the cart
      await cartService.clearCart(userId);

      // Notify sellers about each transaction
      // for (final transaction in transactions) {
      //   final chatId = await chatService.createOrGetChatDoc(
      //     currentUser.uid,
      //     transaction.sellerId,
      //     transaction.sellerName ?? 'Seller',
      //     '', // Default empty string for image URL
      //   );

      //   await chatService.sendMessage(
      //     chatId,
      //     ChatMessage(
      //       id: FirebaseFirestore.instance.collection('messages').doc().id,
      //       text: 'I have placed an order for ${transaction.productName} (${transaction.quantity}x)',
      //       senderId: currentUser.uid,
      //       timestamp: DateTime.now(),
      //     ),
      //   );
      // }

      if (!mounted) return;

      // Navigate to payment page for the first transaction
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(transaction: transactions.first),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
