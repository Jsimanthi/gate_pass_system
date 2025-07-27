// File: lib/presentation/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/presentation/auth/login_screen.dart';
import 'package:gatepass_app/presentation/dashboard/dashboard_overview_screen.dart'; // Corrected import
import 'package:gatepass_app/presentation/my_passes/my_passes_screen.dart';

// Placeholder for ProfileScreen - now accepts AuthService
class ProfileScreen extends StatelessWidget {
  final AuthService authService; // Added authService

  const ProfileScreen({super.key, required this.authService}); // Required authService

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.person, size: 80, color: Colors.blueGrey),
          const SizedBox(height: 20),
          const Text(
            'User Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Manage your profile settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          // Example: Display current user or logout button here using authService
          ElevatedButton(
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen(authService: authService, apiClient: ApiClient('', authService))), // Recreate LoginScreen with dependencies
                  (Route<dynamic> route) => false,
                );
              }
            },
            child: const Text('Logout from Profile'),
          ),
        ],
      ),
    );
  }
}

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
      MyPassesScreen(apiClient: _apiClient, authService: _authService), // Pass required dependencies
      ProfileScreen(authService: _authService), // Pass required dependency
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
        MaterialPageRoute(builder: (context) => LoginScreen(apiClient: _apiClient, authService: _authService)),
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
      body: _widgetOptions.elementAt(_selectedIndex), // Display the selected screen
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary, // Use theme color
        onTap: _onItemTapped,
      ),
    );
  }
}