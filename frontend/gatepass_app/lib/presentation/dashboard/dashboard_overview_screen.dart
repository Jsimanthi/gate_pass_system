// File: lib/presentation/dashboard/dashboard_overview_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart';

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

  int _pendingPasses = 0;
  int _approvedPasses = 0;
  int _rejectedPasses = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient;
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    // Always check mounted before the first setState in an async method
    if (!mounted) return; 
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiClient.get('/api/gatepass/dashboard-summary/');
      if (mounted) { // Check mounted before updating state after async call
        setState(() {
          _pendingPasses = response['pending_count'] ?? 0;
          _approvedPasses = response['approved_count'] ?? 0;
          _rejectedPasses = response['rejected_count'] ?? 0;
        });
      }
    } catch (e) {
      if (mounted) { // Check mounted before updating state in catch block
        setState(() {
          _errorMessage = 'Error loading dashboard data: $e';
        });
      }
    } finally {
      if (mounted) { // Check mounted before updating state in finally block
        setState(() {
          _isLoading = false;
        });
      }
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
            'Welcome, User!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: 0.85,
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 5),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
