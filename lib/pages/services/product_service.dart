import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:myapp/models/product_model.dart';
//import '../models/product_model.dart';

class ProductService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Demo products data
  List<ProductModel> getDemoProducts() {
    return [
      ProductModel(
        id: 'demo1',
        name: 'Honey',
        description: 'Fresh organic apples from local farms',
        price: 2.99,
        quantity: 5,
        category: 'Dairy',
        imageUrl: 'assets /images/products/honey-pot-4d7c98d.jpg',
        farmerId: 'demo_farmer',
        farmerName: 'Demo Farmer',
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo2',
        name: 'LICHU',
        description: 'Sweet and crunchy , freshly harvested',
        price: 200,
        quantity: 30,
        category: 'Fruits',
        imageUrl: 'assets /images/products/lichu.png',
        farmerId: 'demo_farmer',
        farmerName: 'Demo Farmer',
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo3',
        name: 'Fresh Milk',
        description: 'Organic milk from grass-fed cows',
        price: 3.99,
        quantity: 20,
        category: 'Dairy',
        imageUrl: 'assets /images/products/milk.png',
        farmerId: 'demo_farmer',
        farmerName: 'Demo Farmer',
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo4',
        name: 'jaggery',
        description: 'Freshly baked whole wheat bread',
        price: 4.50,
        quantity: 15,
        category: 'Grains',
        imageUrl: 'assets /images/products/jaggery .jpg',
        farmerId: 'demo_farmer',
        farmerName: 'Demo Farmer',
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo5',
        name: 'tea leaves',
        description: 'Premium cuts oftea leaves',
        price: 12.99,
        quantity: 10,
        category: 'Dairy',
        imageUrl: 'assets /images/products/tealeaves.jpg',
        farmerId: 'demo_farmer',
        farmerName: 'Demo Farmer',
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo5',
        name: 'Mango',
        description: 'Premium cuts of mango',
        price: 12.99,
        quantity: 10,
        category: 'Fruits',
        imageUrl: 'assets /images/products/download.jpeg',
        farmerId: 'demo_farmer',
        farmerName: 'Demo Farmer',
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Get all products (sorted by creation date) including demo products
  Stream<List<ProductModel>> getAllProducts() {
    try {
      return _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('Firestore Error in getAllProducts: $error');
            return Stream.value([]);
          })
          .map((snapshot) {
            final products =
                snapshot.docs
                    .map((doc) => ProductModel.fromFirestore(doc))
                    .toList();
            return [...products, ...getDemoProducts()];
          });
    } catch (e) {
      debugPrint('Error in getAllProducts: $e');
      return Stream.value(getDemoProducts());
    }
  }

  // Get available marketplace products including available demo products
  Stream<List<ProductModel>> getMarketplaceProducts() {
    try {
      return _firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('Firestore Error in getMarketplaceProducts: $error');
            return Stream.value([]);
          })
          .map((snapshot) {
            final products =
                snapshot.docs
                    .map((doc) => ProductModel.fromFirestore(doc))
                    .toList();
            final demoProducts =
                getDemoProducts().where((p) => p.isAvailable).toList();
            return [...products, ...demoProducts];
          });
    } catch (e) {
      debugPrint('Error in getMarketplaceProducts: $e');
      return Stream.value(
        getDemoProducts().where((p) => p.isAvailable).toList(),
      );
    }
  }

  // Get products by farmer ID including demo products for demo farmer
  Stream<List<ProductModel>> getProductsByFarmerId(String farmerId) {
    try {
      return _firestore
          .collection('products')
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('Firestore Error in getProductsByFarmerId: $error');
            return Stream.value([]);
          })
          .map((snapshot) {
            final products =
                snapshot.docs
                    .map((doc) => ProductModel.fromFirestore(doc))
                    .toList();

            if (farmerId == 'demo_farmer') {
              return [...products, ...getDemoProducts()];
            }
            return products;
          });
    } catch (e) {
      debugPrint('Error in getProductsByFarmerId: $e');
      return farmerId == 'demo_farmer'
          ? Stream.value(getDemoProducts())
          : Stream.value([]);
    }
  }

  // Get admin-managed products (excludes demo products)
  Stream<List<ProductModel>> getAdminProducts() {
    try {
      return _firestore
          .collection('products')
          .where('ownerType', isEqualTo: 'admin')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('Firestore Error in getAdminProducts: $error');
            return Stream.value([]);
          })
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => ProductModel.fromFirestore(doc))
                    .toList(),
          );
    } catch (e) {
      debugPrint('Error in getAdminProducts: $e');
      return Stream.value([]);
    }
  }

  // Get total product count (excluding demo products)
  Stream<int> getTotalProductCount() {
    try {
      return _firestore
          .collection('products')
          .snapshots()
          .handleError((error) {
            debugPrint('Firestore Error in getTotalProductCount: $error');
            return Stream.value(0);
          })
          .map((snapshot) => snapshot.size);
    } catch (e) {
      debugPrint('Error in getTotalProductCount: $e');
      return Stream.value(0);
    }
  }

  // Save product with proper error handling
  Future<void> saveProduct({
    required ProductModel product,
    XFile? mainImageFile,
    List<XFile> additionalImageFiles = const [],
    required bool isUpdate,
    required dynamic ConnectivityResult,
  }) async {
    try {
      // 1. Validate inputs
      if (product.name.isEmpty) throw 'Product name is required';
      if (product.price <= 0) throw 'Price must be positive';
      if (product.quantity < 0) throw 'Quantity cannot be negative';

      // 2. Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        throw 'No internet connection';
      }

      // 3. Check authentication
      final user = _auth.currentUser;
      if (user == null) throw 'User not logged in';

      // 4. Prevent saving demo products
      if (product.id.startsWith('demo')) {
        throw 'Cannot save demo products';
      }

      debugPrint('Starting product save process...');

      // 5. Upload main image if exists
      String? imageUrl = product.imageUrl;
      if (mainImageFile != null) {
        debugPrint('Uploading main image...');
        imageUrl = await _uploadImage(
          mainImageFile,
          'products/${user.uid}/main_${DateTime.now().millisecondsSinceEpoch}',
        );
        debugPrint('Main image uploaded: $imageUrl');
      }

      // 6. Upload additional images if exist
      List<String> additionalImageUrls = product.additionalImages ?? [];
      if (additionalImageFiles.isNotEmpty) {
        debugPrint(
          'Uploading ${additionalImageFiles.length} additional images...',
        );
        additionalImageUrls = await Future.wait(
          additionalImageFiles.map((file) async {
            final url = await _uploadImage(
              file,
              'products/${user.uid}/additional_${DateTime.now().millisecondsSinceEpoch}',
            );
            debugPrint('Additional image uploaded: $url');
            return url;
          }),
        );
      }

      // 7. Prepare final product data
      final productToSave = product.copyWith(
        farmerId: user.uid,
        farmerName: user.displayName ?? 'Farmer',
        imageUrl: imageUrl,
        additionalImages:
            additionalImageUrls.isNotEmpty ? additionalImageUrls : null,
        isAvailable: product.quantity > 0,
        updatedAt: DateTime.now(),
      );

      debugPrint('Saving product to Firestore...');

      // 8. Save to Firestore
      if (isUpdate) {
        await _firestore
            .collection('products')
            .doc(product.id)
            .update(productToSave.toMap());
      } else {
        final docRef = _firestore.collection('products').doc();
        await docRef.set(
          productToSave
              .copyWith(id: docRef.id, createdAt: DateTime.now())
              .toMap(),
        );
      }

      debugPrint('Product saved successfully!');
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving product: $e');
      rethrow;
    }
  }

  // Delete product (with demo product protection)
  Future<void> deleteProduct(String productId) async {
    try {
      if (productId.startsWith('demo')) {
        throw 'Cannot delete demo products';
      }

      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        throw 'No internet connection';
      }

      await _firestore.collection('products').doc(productId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error in deleteProduct: $e');
      rethrow;
    }
  }

  // Update product stock (excluding demo products)
  Future<void> updateProductStock(String productId, int newQuantity) async {
    try {
      if (productId.startsWith('demo')) {
        throw 'Cannot update demo products';
      }

      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        throw 'No internet connection';
      }

      await _firestore.collection('products').doc(productId).update({
        'quantity': newQuantity,
        'isAvailable': newQuantity > 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error in updateProductStock: $e');
      rethrow;
    }
  }

  // Image upload helper
  Future<String> _uploadImage(XFile file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(await file.readAsBytes());

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        debugPrint(
          'Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes',
        );
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Image upload failed: $e');
      throw 'Failed to upload image';
    }
  }

  // Image picking helpers
  Future<XFile?> pickImage() async {
    try {
      return await _picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      debugPrint('Image pick error: $e');
      throw 'Failed to pick image';
    }
  }

  Future<List<XFile>> pickMultipleImages() async {
    try {
      return await _picker.pickMultiImage();
    } catch (e) {
      debugPrint('Multi-image pick error: $e');
      throw 'Failed to pick images';
    }
  }
}
