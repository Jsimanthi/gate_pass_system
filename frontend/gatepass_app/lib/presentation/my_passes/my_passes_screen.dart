// File: lib/presentation/my_passes/my_passes_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart';

class MyPassesScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;

  const MyPassesScreen({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<MyPassesScreen> createState() => _MyPassesScreenState();
}

class _MyPassesScreenState extends State<MyPassesScreen> {
  late final ApiClient _apiClient;
  late final AuthService _authService;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _myGatePasses = [];

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient;
    _authService = widget.authService;
    _fetchMyGatePasses();
  }

  Future<void> _fetchMyGatePasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Replace with your actual API endpoint for fetching user's gate passes
      // Example: await _apiClient.get('/api/my-gatepasses/');
      // For now, simulate some data
      await Future.delayed(const Duration(seconds: 1));
      _myGatePasses = [
        {
          'id': 1,
          'person_name': 'John Doe',
          'purpose': 'Visitor',
          'status': 'Approved',
        },
        {
          'id': 2,
          'person_name': 'Jane Smith',
          'purpose': 'Delivery',
          'status': 'Pending',
        },
        {
          'id': 3,
          'person_name': 'Alice Johnson',
          'purpose': 'Maintenance',
          'status': 'Rejected',
        },
      ];
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading your gate passes: $e';
        print('MyPasses API Fetch Error: $_errorMessage');
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
                onPressed: _fetchMyGatePasses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_myGatePasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox_rounded, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No Gate Passes Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'You haven\'t requested any gate passes yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _myGatePasses.length,
      itemBuilder: (context, index) {
        final pass = _myGatePasses[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: _getStatusIcon(pass['status']),
            title: Text(
              'Purpose: ${pass['purpose']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Applicant: ${pass['person_name']}'),
                Text('Status: ${pass['status']}'),
                // Add more details like entry/exit time, gate, etc. as available
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to Gate Pass detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tapped on Gate Pass ID: ${pass['id']}'),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'pending':
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.info_outline, color: Colors.grey);
    }
  }
}
