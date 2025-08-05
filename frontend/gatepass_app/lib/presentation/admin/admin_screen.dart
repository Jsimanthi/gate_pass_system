import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:gatepass_app/presentation/my_passes/my_pass_details_screen.dart';

class AdminScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;

  const AdminScreen({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final ApiClient _apiClient;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allGatePasses = [];
  List<Map<String, dynamic>> _filteredGatePasses = [];
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient;
    _fetchAllGatePasses();
  }

  List<Map<String, dynamic>> _extractResults(dynamic response) {
    if (response is Map<String, dynamic> &&
        response.containsKey('results') &&
        response['results'] is List) {
      return List<Map<String, dynamic>>.from(response['results']);
    } else if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  Future<void> _fetchAllGatePasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiClient.get('/api/gatepass/gatepasses/');
      _allGatePasses = _extractResults(response);
      _filteredGatePasses = _allGatePasses;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading gate passes: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approvePass(int passId) async {
    try {
      await _apiClient.post('/api/gatepass/gatepasses/$passId/approve/', {});
      _fetchAllGatePasses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve pass: $e')),
      );
    }
  }

  Future<void> _rejectPass(int passId) async {
    try {
      await _apiClient.post('/api/gatepass/gatepasses/$passId/reject/', {});
      _fetchAllGatePasses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject pass: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - All Passes'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
                onPressed: _fetchAllGatePasses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_allGatePasses.isEmpty) {
      return const Center(
        child: Text('No gate passes found.'),
      );
    }

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchAllGatePasses,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _filteredGatePasses.length,
              itemBuilder: (context, index) {
                final pass = _filteredGatePasses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(
                        'Purpose: ${pass['purpose'] != null ? pass['purpose']['name'] ?? 'N/A' : 'N/A'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Applicant: ${pass['person_name'] ?? 'N/A'}'),
                        Text('Status: ${pass['status'] ?? 'N/A'}'),
                        Text(
                            'Entry: ${pass['entry_time'] != null ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(pass['entry_time'])) : 'N/A'}'),
                      ],
                    ),
                    trailing: pass['status'] == 'PENDING'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _approvePass(pass['id']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectPass(pass['id']),
                              ),
                            ],
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MyPassDetailsScreen(pass: pass),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildFilterButton('All')),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterButton('PENDING')),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterButton('APPROVED')),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterButton('REJECTED')),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String status) {
    return ElevatedButton(
      onPressed: () => _filterPasses(status),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _selectedStatus == status ? Theme.of(context).primaryColor : Colors.grey,
      ),
      child: Text(status),
    );
  }

  void _filterPasses(String status) {
    setState(() {
      _selectedStatus = status;
      if (status == 'All') {
        _filteredGatePasses = _allGatePasses;
      } else {
        _filteredGatePasses =
            _allGatePasses.where((pass) => pass['status'] == status).toList();
      }
    });
  }
}
