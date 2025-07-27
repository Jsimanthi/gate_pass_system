// File: lib/presentation/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/presentation/auth/login_screen.dart';
import 'package:gatepass_app/presentation/home/dashboard_overview_screen.dart';
import 'package:gatepass_app/presentation/my_passes/my_passes_screen.dart';

// Placeholder for GatePassListScreen (can be moved to its own file later)
// This screen doesn't require ApiClient/AuthService directly yet, but if it did,
// you would follow the same pattern as DashboardOverviewScreen.
class GatePassListScreen extends StatelessWidget {
  const GatePassListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.list_alt, size: 80, color: Colors.blueGrey),
          SizedBox(height: 20),
          Text(
            'Gate Passes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'List of all gate passes (pending, approved, rejected) will be displayed here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// Placeholder for ProfileScreen (can be moved to its own file later)
// This screen doesn't require ApiClient/AuthService directly yet, but if it did,
// you would follow the same pattern as DashboardOverviewScreen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.person, size: 80, color: Colors.blueGrey),
          SizedBox(height: 20),
          Text(
            'User Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Manage your profile settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  // Add ApiClient and AuthService as parameters to the constructor
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

  // Declare _apiClient and _authService to be assigned from widget properties
  late final ApiClient _apiClient;
  late final AuthService _authService;

  // List of widgets (screens) to display in the body of the Scaffold
  // These now accept apiClient and authService
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient; // Assign from widget
    _authService = widget.authService; // Assign from widget

    _widgetOptions = <Widget>[
      DashboardOverviewScreen(apiClient: _apiClient, authService: _authService),
      // GatePassListScreen doesn't currently need them, but if it fetches data,
      // it would be: GatePassListScreen(apiClient: _apiClient, authService: _authService),
      GatePassListScreen(),
      ProfileScreen(), // Same for ProfileScreen
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
        MaterialPageRoute(builder: (context) => const LoginScreen()),
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
            icon: Icon(Icons.description), // Or Icons.list_alt
            label: 'Gate Passes',
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