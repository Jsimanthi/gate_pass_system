// File: lib/presentation/my_passes/my_passes_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:gatepass_app/presentation/my_passes/my_pass_details_screen.dart';

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
  List<Map<String, dynamic>> _filteredGatePasses = [];
  String _selectedStatus = 'All';
  bool _isSortedByDate = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient;
    _authService = widget.authService;
    _fetchMyGatePasses(); // Initiate API call when screen initializes
  }

  // Helper function to extract results from paginated API response
  List<Map<String, dynamic>> _extractResults(dynamic response) {
    debugPrint('DEBUG: _extractResults received response: $response'); // Debug print
    if (response is Map<String, dynamic> &&
        response.containsKey('results') &&
        response['results'] is List) {
      debugPrint('DEBUG: Extracting results from paginated response.'); // Debug print
      return List<Map<String, dynamic>>.from(response['results']);
    } else if (response is List) {
      // If the API directly returns a list (no pagination, less common for DRF)
      debugPrint('DEBUG: Response is a direct list.'); // Debug print
      return List<Map<String, dynamic>>.from(response);
    }
    // Log a warning if the response format is unexpected
    debugPrint(
      'Warning: API response not in expected paginated or list format: $response',
    );
    return []; // Return empty list to avoid errors if format is wrong
  }

  Future<void> _fetchMyGatePasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });
    try {
      // Actual API call to your Django backend
      final response = await _apiClient.get('/api/gatepass/');
      debugPrint('DEBUG: API call to /api/gatepass/ returned. Processing results.'); // Debug print
      _myGatePasses = _extractResults(response); // Process the response
      _filteredGatePasses = _myGatePasses;
      debugPrint('DEBUG: _myGatePasses after extraction: $_myGatePasses'); // Debug print

    } catch (e) {
      // Catch any errors during API call or data processing
      setState(() {
        _errorMessage = 'Error loading your gate passes: $e';
        debugPrint('MyPasses API Fetch Error: $_errorMessage'); // Print error to console
      });
    } finally {
      setState(() {
        _isLoading = false; // Stop loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Passes'),
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
                onPressed: _fetchMyGatePasses, // Allow retry on error
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

    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchMyGatePasses,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _filteredGatePasses.length,
              itemBuilder: (context, index) {
                final pass = _filteredGatePasses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Theme.of(context).primaryColor, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: _getStatusIcon(pass['status']), // Get icon based on status
                    title: Text(
                      // Access nested 'name' property for purpose with null checks
                      'Purpose: ${pass['purpose'] != null ? pass['purpose']['name'] ?? 'N/A' : 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Applicant: ${pass['person_name'] ?? 'N/A'}'),
                        // Access nested 'name' property for gate with null checks
                        Text('Gate: ${pass['gate'] != null ? pass['gate']['name'] ?? 'N/A' : 'N/A'}'),
                        Text('Status: ${pass['status'] ?? 'N/A'}'),
                        // Conditionally display vehicle and driver if they exist and are not null
                        if (pass['vehicle'] != null && pass['vehicle']['vehicle_number'] != null)
                          Text('Vehicle: ${pass['vehicle']['vehicle_number']}'),
                        if (pass['driver'] != null && pass['driver']['name'] != null)
                          Text('Driver: ${pass['driver']['name']}'),
                        // Format and display entry/exit times using intl package with null checks
                        Text('Entry: ${pass['entry_time'] != null ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(pass['entry_time'])) : 'N/A'}'),
                        Text('Exit: ${pass['exit_time'] != null ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(pass['exit_time'])) : 'N/A'}'),
                        Text('Created At: ${pass['created_at'] != null ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(pass['created_at'])) : 'N/A'}'),
                        // Conditionally display created_by and approved_by usernames with null checks
                        if (pass['created_by'] != null && pass['created_by']['username'] != null)
                          Text('Created By: ${pass['created_by']['username']}'),
                        if (pass['approved_by'] != null && pass['approved_by']['username'] != null)
                          Text('Approved By: ${pass['approved_by']['username']}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyPassDetailsScreen(pass: pass),
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

  // Helper function to get status icon based on status string
  Icon _getStatusIcon(String? status) {
    if (status == null) return const Icon(Icons.info_outline, color: Colors.grey);
    switch (status.toUpperCase()) { // Use toUpperCase to match Django's constants
      case 'APPROVED':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'PENDING':
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case 'REJECTED':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'CANCELLED': // Handle CANCELLED status if you use it
        return const Icon(Icons.remove_circle_outline, color: Colors.blueGrey);
      default:
        return const Icon(Icons.info_outline, color: Colors.grey);
    }
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterButton('All', Icons.all_inclusive),
          _buildFilterButton('APPROVED', Icons.check_circle),
          _buildFilterButton('PENDING', Icons.hourglass_empty),
          _buildFilterButton('REJECTED', Icons.cancel),
          IconButton(
            icon: Icon(Icons.sort, color: _isSortedByDate ? Theme.of(context).primaryColor : Colors.grey),
            onPressed: _sortPasses,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String status, IconData icon) {
    return IconButton(
      onPressed: () => _filterPasses(status),
      icon: Icon(icon),
      color: _selectedStatus == status ? Theme.of(context).primaryColor : Colors.grey,
    );
  }

  void _filterPasses(String status) {
    setState(() {
      _selectedStatus = status;
      if (status == 'All') {
        _filteredGatePasses = _myGatePasses;
      } else {
        _filteredGatePasses = _myGatePasses.where((pass) => pass['status'] == status).toList();
      }
    });
  }

  void _sortPasses() {
    setState(() {
      _isSortedByDate = !_isSortedByDate;
      _filteredGatePasses.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['created_at']);
          final dateB = DateTime.parse(b['created_at']);
          return _isSortedByDate ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by applicant name or vehicle number',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: _searchPasses,
      ),
    );
  }

  void _searchPasses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGatePasses = _myGatePasses;
      } else {
        _filteredGatePasses = _myGatePasses.where((pass) {
          final applicantName = pass['person_name']?.toLowerCase() ?? '';
          final vehicleNumber = pass['vehicle']?['vehicle_number']?.toLowerCase() ?? '';
          final lowerCaseQuery = query.toLowerCase();
          return applicantName.contains(lowerCaseQuery) || vehicleNumber.contains(lowerCaseQuery);
        }).toList();
      }
    });
  }
}