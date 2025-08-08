// File: lib/presentation/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart';
// Import for debugPrint

class ProfileScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;

  const ProfileScreen({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ApiClient _apiClient;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData; // To store fetched user data

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient;
    _fetchUserProfile(); // Initiate API call when screen initializes
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });
    try {
      // Assuming your Django backend has an endpoint for the current user's profile
      // This is a common pattern for authenticated user details.
      // Adjust the endpoint if your actual API for fetching current user is different.
      final response = await _apiClient.get('/api/users/me/');
      debugPrint('DEBUG: API call to /api/users/me/ returned. Processing user data.');
      
      // The API might return the user object directly, or a single item in a list.
      // We'll try to handle both cases.
      if (response is Map<String, dynamic>) {
        _userData = response;
      } else if (response is List && response.isNotEmpty) {
        _userData = response[0] as Map<String, dynamic>;
      } else {
        _errorMessage = 'Unexpected API response format for user profile.';
        debugPrint('Profile API Fetch Error: Unexpected response: $response');
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user profile: $e';
        debugPrint('Profile API Fetch Error: $_errorMessage');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchUserProfile, // Allow retry on error
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_userData == null || _userData!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person_off, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'User data not found.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Could not retrieve your profile information.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Display the user profile details
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.account_circle,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 30, thickness: 1),
                  _buildProfileDetailRow(
                    context,
                    icon: Icons.person,
                    label: 'Username',
                    value: _userData!['username'] ?? 'N/A',
                  ),
                  _buildProfileDetailRow(
                    context,
                    icon: Icons.email,
                    label: 'Email',
                    value: _userData!['email'] ?? 'N/A',
                  ),
                  _buildProfileDetailRow(
                    context,
                    icon: Icons.badge,
                    label: 'First Name',
                    value: _userData!['first_name'] ?? 'N/A',
                  ),
                  _buildProfileDetailRow(
                    context,
                    icon: Icons.badge_outlined,
                    label: 'Last Name',
                    value: _userData!['last_name'] ?? 'N/A',
                  ),
                  _buildProfileDetailRow(
                    context,
                    icon: Icons.people,
                    label: 'User Type',
                    // Assuming 'user_type' or 'is_staff' is available
                    value: _getUserType(_userData!),
                  ),
                  // Add more fields as per your User model in Django
                  // Example for is_active
                  _buildProfileDetailRow(
                    context,
                    icon: Icons.check_circle_outline,
                    label: 'Account Status',
                    value: (_userData!['is_active'] ?? false) ? 'Active' : 'Inactive',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getUserType(Map<String, dynamic> userData) {
    if (userData['is_superuser'] == true) {
      return 'Admin';
    } else if (userData['is_staff'] == true) {
      return 'Staff';
    }
    return 'Regular User';
  }
}