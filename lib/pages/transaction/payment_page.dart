import 'package:flutter/material.dart';
import 'package:myapp/models/transactions_model.dart';
import 'package:myapp/pages/transaction/bkash_payment.dart';
import 'package:myapp/pages/transaction/nagad_payment.dart';

class PaymentPage extends StatefulWidget {
  final TransactionModel transaction;

  const PaymentPage({super.key, required this.transaction});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = 'bkash';
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _trxIdController = TextEditingController();
  bool _isProcessing = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _trxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Method'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _buildPaymentMethodSelector(),
            const SizedBox(height: 16),
            if (_selectedMethod == 'bkash' || _selectedMethod == 'nagad')
              _buildMobilePaymentForm(),
            if (_selectedMethod == 'bank') _buildBankTransferInfo(),
            const SizedBox(height: 24),
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.transaction.imageUrl ?? '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => const Icon(Icons.image, size: 60),
                ),
              ),
              title: Text(widget.transaction.productName),
              subtitle: Text('Qty: ${widget.transaction.quantity}'),
              trailing: Text(
                '৳${widget.transaction.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 16)),
                Text(
                  '৳${widget.transaction.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPaymentOption(
              icon: Icons.phone_android,
              label: 'bKash',
              value: 'bkash',
              color: Colors.pink,
            ),
            const SizedBox(width: 12),
            _buildPaymentOption(
              icon: Icons.phone_iphone,
              label: 'Nagad',
              value: 'nagad',
              color: Colors.green,
            ),
            const SizedBox(width: 12),
            _buildPaymentOption(
              icon: Icons.account_balance,
              label: 'Bank',
              value: 'bank',
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedMethod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobilePaymentForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              prefixText: '+880 ',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.phone),
              suffixIcon: IconButton(
                icon: const Icon(Icons.contact_page),
                onPressed: _pickFromContacts,
              ),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter mobile number';
              }
              if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'Enter valid 11 digit number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _trxIdController,
            decoration: const InputDecoration(
              labelText: 'Transaction ID',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.confirmation_number),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter transaction ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Send money to ${_getPaymentNumber()} and enter transaction details',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBankTransferInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bank Transfer Instructions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Bank Name: Example Bank'),
            const Text('Account Name: Your Business Name'),
            const Text('Account Number: 1234567890'),
            const Text('Branch: Main Branch'),
            const Text('Routing Number: 123456789'),
            const SizedBox(height: 12),
            const Text(
              'After payment, please provide the transaction details',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getPaymentButtonColor(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                  _selectedMethod == 'bank'
                      ? 'Confirm Bank Transfer'
                      : 'Proceed to Payment',
                  style: const TextStyle(fontSize: 16),
                ),
      ),
    );
  }

  Color _getPaymentButtonColor() {
    switch (_selectedMethod) {
      case 'bkash':
        return Colors.pink;
      case 'nagad':
        return Colors.green;
      case 'bank':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  String _getPaymentNumber() {
    switch (_selectedMethod) {
      case 'bkash':
        return '017XXXXXXXX (Personal)';
      case 'nagad':
        return '018XXXXXXXX (Merchant)';
      default:
        return '';
    }
  }

  Future<void> _pickFromContacts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _phoneController.text = '1712345678');
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == 'bank') {
      _handleBankPayment();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final updatedTransaction = widget.transaction.copyWith(
        paymentMethod: _selectedMethod,
        paymentPhone: _phoneController.text.trim(),
        paymentTrxId: _trxIdController.text.trim(),
        status: 'paid',
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  _selectedMethod == 'bkash'
                      ? BkashPaymentPage(transaction: updatedTransaction)
                      : NagadPaymentPage(transaction: updatedTransaction),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleBankPayment() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bank Transfer'),
            content: const Text(
              'Please complete the bank transfer using the provided details. '
              'We will verify your payment and confirm your order.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitBankPayment();
                },
                child: const Text('I have paid'),
              ),
            ],
          ),
    );
  }

  Future<void> _submitBankPayment() async {
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank payment details submitted for verification'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
