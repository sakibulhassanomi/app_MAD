import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_page.dart';

class ViewProfilePage extends StatefulWidget {
  const ViewProfilePage({super.key});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  late final Stream<DocumentSnapshot> _profileStream;

  @override
  void initState() {
    super.initState();
    _profileStream = FirebaseFirestore.instance
        .collection('farmers')
        .doc(userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 28),
            onPressed: () => _navigateToEdit(context),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _profileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildErrorWidget('Profile not found');
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildProfileView(data);
        },
      ),
    );
  }

  Widget _buildProfileView(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileHeader(data),
          const SizedBox(height: 24),
          _buildProfileDetails(data),
          const SizedBox(height: 30),
          _buildEditButton(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage: _getProfileImage(data),
          child: data['imageUrl'] == null
              ? const Icon(Icons.person, size: 50, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          data['name'] ?? 'No Name',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (data['role'] != null) ...[
          const SizedBox(height: 4),
          Chip(
            label: Text(
              data['role'].toString().toUpperCase(),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        ],
      ],
    );
  }

  ImageProvider? _getProfileImage(Map<String, dynamic> data) {
    if (data['imageUrl'] != null) return NetworkImage(data['imageUrl']!);
    return const AssetImage('assets/default_avatar.png');
  }

  Widget _buildProfileDetails(Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailItem(Icons.phone, 'Phone', data['phone']),
            const Divider(height: 24),
            _buildDetailItem(Icons.location_on, 'Address',
                '${data['village'] ?? ''}, ${data['district'] ?? ''}'),
            const Divider(height: 24),
            _buildDetailItem(Icons.email, 'Email', data['email']),
            const Divider(height: 24),
            _buildDetailItem(Icons.calendar_today, 'Member Since',
                _formatDate(data['createdAt'])),
            if (data['farmSize'] != null) ...[
              const Divider(height: 24),
              _buildDetailItem(Icons.agriculture, 'Farm Size',
                  '${data['farmSize']} acres'),
            ],
            if (data['crops'] != null && (data['crops'] as List).isNotEmpty) ...[
              const Divider(height: 24),
              _buildDetailItem(Icons.grass, 'Main Crops',
                  (data['crops'] as List).join(', ')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.green),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value ?? 'Not provided',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return timestamp.toString();
  }

  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.edit),
        label: const Text('EDIT PROFILE'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () => _navigateToEdit(context),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(userId)
        .get();

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          initialData: snapshot.data() as Map<String, dynamic>,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}