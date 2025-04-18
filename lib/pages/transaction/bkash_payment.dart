import 'package:flutter/material.dart';
//import 'package:apps/models/transaction_model.dart';
import 'package:myapp/models/transactions_model.dart';
import 'package:myapp/pages/services/transaction_service.dart';

class BkashPaymentPage extends StatefulWidget {
  final TransactionModel transaction;

  const BkashPaymentPage({super.key, required this.transaction});

  @override
  State<BkashPaymentPage> createState() => _BkashPaymentPageState();
}

class _BkashPaymentPageState extends State<BkashPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _txnController = TextEditingController();
  bool _isLoading = false;
  final TransactionService _transactionService = TransactionService();

  @override
  void dispose() {
    _txnController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update transaction with payment info
      final updatedTransaction = widget.transaction.copyWith(
        status: 'completed',
        notes: 'bKash Txn ID: ${_txnController.text}',
      );

      await _transactionService.updateTransactionStatus(
          updatedTransaction.id,
          'completed'
      );

      await _transactionService.updatePaymentMethod(
          updatedTransaction.id,
          'bKash'
      );

      if (!mounted) return;
      _showSuccessMessage();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment successful!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: $error"),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Payment Instructions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text("1. Go to bKash Mobile Menu"),
        const Text("2. Select 'Send Money'"),
        const Text("3. Enter Merchant Number: 01XXXXXXXXX"),
        Text("4. Enter Amount: ৳${widget.transaction.totalAmount.toStringAsFixed(2)}"),
        Text("5. Enter Reference: ${widget.transaction.id}"),
      ],
    );
  }

  Widget _buildTransactionIdField() {
    return TextFormField(
      controller: _txnController,
      decoration: const InputDecoration(
        labelText: "bKash Transaction ID",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.confirmation_number),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter transaction ID';
        }
        if (value.length < 10) {
          return 'Please enter a valid transaction ID (min 10 characters)';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitPayment,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.pink,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
        "Confirm Payment",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("bKash Payment"),
        backgroundColor: Colors.pink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPaymentInstructions(),
              const SizedBox(height: 24),
              _buildTransactionIdField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
}