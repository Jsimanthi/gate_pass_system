// File: lib/presentation/home/dashboard_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:gatepass_app/presentation/gate_pass_request/gate_pass_request_screen.dart'; // For navigating to request screen

class DashboardOverviewScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;

  const DashboardOverviewScreen({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<DashboardOverviewScreen> createState() => _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  late final ApiClient _apiClient;
  late final AuthService _authService;

  int _pendingPasses = 0;
  int _approvedPasses = 0;
  int _rejectedPasses = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient;
    _authService = widget.authService;
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiClient.get('/api/gatepass/dashboard-summary/');
      setState(() {
        _pendingPasses = response['pending_count'] ?? 0;
        _approvedPasses = response['approved_count'] ?? 0;
        _rejectedPasses = response['rejected_count'] ?? 0;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading dashboard data: $e';
        print('Dashboard API Fetch Error: $_errorMessage');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToGatePassRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GatePassRequestScreen(
          apiClient: _apiClient,
          authService: _authService,
        ),
      ),
    );
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
                onPressed: _fetchDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Welcome, User!', // You might want to display the actual username here
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling inside GridView
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            children: <Widget>[
              _buildDashboardCard(
                context,
                'Pending Passes',
                _pendingPasses.toString(),
                Icons.hourglass_empty,
                Colors.orange.shade700,
              ),
              _buildDashboardCard(
                context,
                'Approved Passes',
                _approvedPasses.toString(),
                Icons.check_circle_outline,
                Colors.green.shade700,
              ),
              _buildDashboardCard(
                context,
                'Rejected Passes',
                _rejectedPasses.toString(),
                Icons.cancel_outlined,
                Colors.red.shade700,
              ),
              _buildDashboardCard(
                context,
                'Total Passes',
                (_pendingPasses + _approvedPasses + _rejectedPasses).toString(),
                Icons.list_alt,
                Colors.blue.shade700,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: _navigateToGatePassRequest,
              icon: const Icon(Icons.note_add),
              label: const Text(
                'Request New Gate Pass',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
      BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}