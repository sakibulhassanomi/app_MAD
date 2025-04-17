//import 'package:apps/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/transactions_model.dart';

class NagadPaymentPage extends StatelessWidget {
  const NagadPaymentPage({super.key, required TransactionModel transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nagad Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Send payment to: 01YYYYYYYYY"),
            const SizedBox(height: 10),
            const Text("Nagad Personal Number"),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: "Nagad Transaction ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save to Firestore or confirm payment
              },
              child: const Text("Submit Payment"),
            ),
          ],
        ),
      ),
    );
  }
}
