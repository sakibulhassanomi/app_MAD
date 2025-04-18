import 'package:flutter/material.dart';
import 'package:myapp/models/transactions_model.dart';
import 'package:myapp/pages/services/transaction_service.dart';

class TransactionPage extends StatelessWidget {
  final String userId;
  final String userType; // 'farmer' or 'consumer'

  const TransactionPage({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              // Add filter functionality
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: TransactionService().getTransactionsForUser(userId, userType: userType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No transactions found"));
          }

          final transactions = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final txn = transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(txn.status),
                    child: Icon(
                      _getPaymentMethodIcon(txn.paymentMethod),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(txn.productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${txn.quantity} x ৳${txn.price.toStringAsFixed(2)}"),
                      Text(dateFormat.format(txn.timestamp)),
                      if (txn.paymentMethod != null)
                        Text("Paid via ${txn.paymentMethod}"),
                      Text(
                        "Status: ${txn.status.toUpperCase()}",
                        style: TextStyle(
                          color: _getStatusColor(txn.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "৳${txn.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (userType == 'farmer')
                        Text(txn.buyerName ?? 'Customer'),
                      if (userType == 'consumer')
                        Text(txn.sellerName ?? 'Seller'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getPaymentMethodIcon(String? method) {
    switch (method?.toLowerCase()) {
      case 'bkash':
        return Icons.payment;
      case 'nagad':
        return Icons.mobile_friendly;
      default:
        return Icons.help_outline;
    }
  }
}

DateFormat(String s) {
}