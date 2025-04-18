import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:apps/models/transaction_model.dart';
import 'package:myapp/models/transactions_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches transactions for a specific user (either as buyer or seller)
  Stream<List<TransactionModel>> getTransactionsForUser(
    String userId, {
    String userType = 'consumer', // Default to consumer if not specified
  }) {
    try {
      // Determine which field to query based on user type
      final fieldToQuery = userType == 'farmer' ? 'sellerId' : 'buyerId';

      // Build the query with proper error handling
      final query = _firestore
          .collection('transactions')
          .where(fieldToQuery, isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      return query
          .snapshots()
          .handleError((error) {
            if (error is FirebaseException &&
                error.code == 'failed-precondition') {
              // Provide a more helpful error message with the index creation link
              throw Exception(
                'Firestore query requires an index. Please create it in the Firebase Console.\n'
                'Required index fields: $fieldToQuery (ASC), timestamp (DESC)',
              );
            }
            throw Exception(
              'Failed to fetch transactions: ${error.toString()}',
            );
          })
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return TransactionModel.fromMap(doc.data());
            }).toList();
          });
    } catch (e) {
      throw Exception(
        'Failed to initialize transactions stream: ${e.toString()}',
      );
    }
  }

  /// Creates a new transaction in Firestore
  Future<void> createTransaction(TransactionModel transaction) async {
    try {
      await _firestore.runTransaction((transactionHandler) async {
        transactionHandler.set(
          _firestore.collection('transactions').doc(transaction.id),
          transaction.toMap(),
        );
      });
    } on FirebaseException catch (e) {
      throw Exception('Firestore error creating transaction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create transaction: ${e.toString()}');
    }
  }

  /// Updates the status of an existing transaction
  Future<void> updateTransactionStatus(
    String transactionId,
    String status,
  ) async {
    try {
      await _firestore.runTransaction((transactionHandler) async {
        final docRef = _firestore.collection('transactions').doc(transactionId);
        final doc = await transactionHandler.get(docRef);

        if (!doc.exists) {
          throw Exception('Transaction not found');
        }

        transactionHandler.update(docRef, {
          'status': status,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw Exception('Firestore error updating status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update transaction status: ${e.toString()}');
    }
  }

  /// Updates the payment method of an existing transaction
  Future<void> updatePaymentMethod(String transactionId, String method) async {
    try {
      await _firestore.runTransaction((transactionHandler) async {
        final docRef = _firestore.collection('transactions').doc(transactionId);
        final doc = await transactionHandler.get(docRef);

        if (!doc.exists) {
          throw Exception('Transaction not found');
        }

        transactionHandler.update(docRef, {
          'paymentMethod': method,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw Exception('Firestore error updating payment method: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update payment method: ${e.toString()}');
    }
  }

  /// Deletes a transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.runTransaction((transactionHandler) async {
        final docRef = _firestore.collection('transactions').doc(transactionId);
        final doc = await transactionHandler.get(docRef);

        if (!doc.exists) {
          throw Exception('Transaction not found');
        }

        transactionHandler.delete(docRef);
      });
    } on FirebaseException catch (e) {
      throw Exception('Firestore error deleting transaction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete transaction: ${e.toString()}');
    }
  }

  /// Gets a single transaction by ID
  Future<TransactionModel?> getTransactionById(String transactionId) async {
    try {
      final doc =
          await _firestore.collection('transactions').doc(transactionId).get();

      if (doc.exists) {
        return TransactionModel.fromMap(doc.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      throw Exception('Firestore error getting transaction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get transaction: ${e.toString()}');
    }
  }
}
