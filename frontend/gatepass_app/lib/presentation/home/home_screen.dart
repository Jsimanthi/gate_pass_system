// File: lib/presentation/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/presentation/auth/login_screen.dart';
import 'package:gatepass_app/presentation/dashboard/dashboard_overview_screen.dart';
import 'package:gatepass_app/presentation/my_passes/my_passes_screen.dart';
import 'package:gatepass_app/presentation/gate_pass_request/gate_pass_request_screen.dart'; // NEW: Import GatePassRequestScreen
import 'package:gatepass_app/presentation/profile/profile_screen.dart'; // NEW: Import the external ProfileScreen

class HomeScreen extends StatefulWidget {
  final ApiClient apiClient;
  final AuthService authService;

  const HomeScreen({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Index for the BottomNavigationBar

  late final ApiClient _apiClient;
  late final AuthService _authService;

  late final List<Widget> _widgetOptions; // List of screens for the navigation

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient; // Assign from widget
    _authService = widget.authService; // Assign from widget

    _widgetOptions = <Widget>[
      DashboardOverviewScreen(apiClient: _apiClient, authService: _authService),
      MyPassesScreen(apiClient: _apiClient, authService: _authService),
      GatePassRequestScreen(
        apiClient: _apiClient,
        authService: _authService,
      ), // NEW: Add GatePassRequestScreen
      ProfileScreen(
        apiClient: _apiClient,
        authService: _authService,
      ), // NEW: Use the external ProfileScreen
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      // Use pushAndRemoveUntil to clear the stack and go to LoginScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              LoginScreen(apiClient: _apiClient, authService: _authService),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Pass System'), // AppBar title for the whole app
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _widgetOptions.elementAt(
        _selectedIndex,
      ), // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description), // Icon for My Passes
            label: 'My Passes',
          ),
          BottomNavigationBarItem(
            // NEW: Add Request Pass item
            icon: Icon(Icons.add_box),
            label: 'Request Pass',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(
          context,
        ).colorScheme.primary, // Use theme color
        unselectedItemColor: Colors.grey, // Ensure unselected items are visible
        onTap: _onItemTapped,
        type: BottomNavigationBarType
            .fixed, // Use fixed type if you have more than 3 items
      ),
    );
  }
}
