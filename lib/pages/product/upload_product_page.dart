import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/pages/services/product_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product_model.dart';
//import '../../services/product_service.dart';

class UploadProductPage extends StatefulWidget {
  final ProductModel? product;
  final List<String> productCategories;
  const UploadProductPage({
    this.product,
    required this.productCategories,
    super.key,
  });

  @override
  State<UploadProductPage> createState() => _UploadProductPageState();
}

class _UploadProductPageState extends State<UploadProductPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _descController;
  late String _selectedCategory;
  XFile? _mainImageFile;
  List<XFile> _additionalImageFiles = [];
  String? _mainImageUrl;
  List<String>? _additionalImageUrls;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();
    _descController = TextEditingController();

    // Initialize with product data if editing
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _quantityController.text = widget.product!.quantity.toString();
      _descController.text = widget.product!.description;
      _selectedCategory = widget.product!.category;
      _mainImageUrl = widget.product!.imageUrl;
      _additionalImageUrls = widget.product!.additionalImages;
    } else {
      _selectedCategory = widget.productCategories.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _mainImageFile = pickedFile;
          _mainImageUrl = null; // Clear existing URL if new image is picked
        });
      }
    } catch (e) {
      _showError('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _pickAdditionalImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _additionalImageFiles = pickedFiles;
          _additionalImageUrls = null; // Clear existing URLs if new images are picked
        });
      }
    } catch (e) {
      _showError('Failed to pick images: ${e.toString()}');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productService = Provider.of<ProductService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final product = ProductModel(
        id: widget.product?.id ?? '',
        name: _nameController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        description: _descController.text,
        category: _selectedCategory,
        imageUrl: _mainImageUrl ?? '',
        additionalImages: _additionalImageUrls,
        isAvailable: int.parse(_quantityController.text) > 0,
        farmerId: user.uid,
        farmerName: user.displayName ?? 'Farmer',
        farmerImage: user.photoURL,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await productService.saveProduct(
        product: product,
        mainImageFile: _mainImageFile,
        additionalImageFiles: _additionalImageFiles,
        isUpdate: widget.product != null, ConnectivityResult: null,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccess(widget.product == null
            ? 'Product added successfully'
            : 'Product updated successfully');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save product: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        actions: [
          if (widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _confirmDelete,
              tooltip: 'Delete Product',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildFormFields(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainImagePicker(),
        const SizedBox(height: 16),
        _buildAdditionalImagesPicker(),
      ],
    );
  }

  Widget _buildMainImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Main Product Image*',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isLoading ? null : _pickMainImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: _buildMainImageContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildMainImageContent() {
    if (_mainImageFile != null) {
      return kIsWeb
          ? Image.network(_mainImageFile!.path, fit: BoxFit.cover)
          : Image.file(File(_mainImageFile!.path), fit: BoxFit.cover);
    } else if (_mainImageUrl != null && _mainImageUrl!.isNotEmpty) {
      return Image.network(_mainImageUrl!, fit: BoxFit.cover);
    } else {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
          Text('Tap to add main product image'),
        ],
      );
    }
  }

  Widget _buildAdditionalImagesPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Product Images',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isLoading ? null : _pickAdditionalImages,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: _buildAdditionalImagesContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalImagesContent() {
    if (_additionalImageFiles.isNotEmpty) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _additionalImageFiles.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: kIsWeb
                ? Image.network(
                _additionalImageFiles[index].path,
                width: 100,
                height: 100,
                fit: BoxFit.cover)
                : Image.file(
                File(_additionalImageFiles[index].path),
                width: 100,
                height: 100,
                fit: BoxFit.cover),
          );
        },
      );
    } else if (_additionalImageUrls != null && _additionalImageUrls!.isNotEmpty) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _additionalImageUrls!.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.network(
                _additionalImageUrls![index],
                width: 100,
                height: 100,
                fit: BoxFit.cover),
          );
        },
      );
    } else {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 30, color: Colors.grey),
          Text('Tap to add more images'),
        ],
      );
    }
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildNameField(),
        const SizedBox(height: 16),
        _buildPriceField(),
        const SizedBox(height: 16),
        _buildQuantityField(),
        const SizedBox(height: 16),
        _buildCategoryField(),
        const SizedBox(height: 16),
        _buildDescriptionField(),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Product Name*',
        border: OutlineInputBorder(),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: const InputDecoration(
        labelText: 'Price*',
        prefixText: '\$ ',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Required';
        if (double.tryParse(value!) == null) return 'Invalid price';
        if (double.parse(value) <= 0) return 'Must be greater than 0';
        return null;
      },
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: const InputDecoration(
        labelText: 'Quantity*',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Required';
        if (int.tryParse(value!) == null) return 'Invalid quantity';
        if (int.parse(value) < 0) return 'Cannot be negative';
        return null;
      },
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category*',
        border: OutlineInputBorder(),
      ),
      items: widget.productCategories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: _isLoading
          ? null
          : (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedCategory = newValue;
          });
        }
      },
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descController,
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          widget.product == null ? 'ADD PRODUCT' : 'UPDATE PRODUCT',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteProduct();
    }
  }

  Future<void> _deleteProduct() async {
    if (widget.product == null) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<ProductService>(context, listen: false)
          .deleteProduct(widget.product!.id);
      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Product deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to delete product: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}