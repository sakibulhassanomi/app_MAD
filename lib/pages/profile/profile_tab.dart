import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/pages/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/user_model.dart';
//import '../../services/auth_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}


class _ProfileTabState extends State<ProfileTab> {
  File? _image; 

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('User data not available'));
        }

        final user = snapshot.data!;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image with Camera Option
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : const AssetImage('assets/images/download.jpg.jpg') as ImageProvider,
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.green),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (_) {
                              return Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera),
                                    title: const Text("Take Photo"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text("Choose from Gallery"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // User Details
                _buildProfileItem(Icons.person, 'Name', user.name),
                _buildProfileItem(Icons.phone, 'Phone', user.phone),
                _buildProfileItem(Icons.location_on, 'District', user.district),
                _buildProfileItem(Icons.home, 'Village', user.village),
                _buildProfileItem(Icons.work, 'Role', user.role.toUpperCase()),

                const SizedBox(height: 20),

                // Edit Profile Button
                Center(
                  child: ElevatedButton(
                    onPressed: () => _editProfile(context, user),
                    child: const Text('Edit Profile'),
                  ),
                ),

                // Transactions Section
                const Divider(),
                const Text(
                    "Payment Methods",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 10),
                _buildTransactionOption(Icons.account_balance_wallet, "bKash"),
                _buildTransactionOption(Icons.account_balance, "Nagad"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionOption(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(text, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        // Navigate to payment method details
      },
    );
  }

  void _editProfile(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final districtController = TextEditingController(text: user.district);
    final villageController = TextEditingController(text: user.village);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: districtController,
                decoration: const InputDecoration(labelText: 'District'),
              ),
              TextField(
                controller: villageController,
                decoration: const InputDecoration(labelText: 'Village'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Update user data in Firestore
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'district': districtController.text,
                  'village': villageController.text,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating profile: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}