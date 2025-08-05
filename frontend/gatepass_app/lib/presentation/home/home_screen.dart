import 'package:flutter/material.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/presentation/auth/login_screen.dart';
import 'package:gatepass_app/presentation/dashboard/dashboard_overview_screen.dart';
import 'package:gatepass_app/presentation/my_passes/my_passes_screen.dart';
import 'package:gatepass_app/presentation/gate_pass_request/gate_pass_request_screen.dart';
import 'package:gatepass_app/presentation/profile/profile_screen.dart';
import 'package:gatepass_app/presentation/reports/reports_screen.dart';
import 'package:gatepass_app/presentation/security/qr_scanner_screen.dart';
import 'package:gatepass_app/presentation/admin/admin_screen.dart';

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
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient; // Assign from widget
    _authService = widget.authService; // Assign from widget
    _checkAdminStatus();

    _widgetOptions = <Widget>[
      DashboardOverviewScreen(apiClient: _apiClient, authService: _authService),
      MyPassesScreen(apiClient: _apiClient, authService: _authService),
      GatePassRequestScreen(apiClient: _apiClient, authService: _authService),
      ProfileScreen(apiClient: _apiClient, authService: _authService),
      QrScannerScreen(apiClient: _apiClient),
      ReportsScreen(apiClient: _apiClient),
      if (_isAdmin)
        AdminScreen(apiClient: _apiClient, authService: _authService),
    ];
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _authService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      setState(() {
        _selectedIndex = 0;
      });
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
        // Set automaticallyImplyLeading to false to use our custom leading widget
        automaticallyImplyLeading: false,

        // --- Custom Logo as Leading Widget ---
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0), // Add some padding
          child: Image.asset(
            'assets/images/sblt_logo.png',
            height: 40, // You can adjust this height
          ),
        ),

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
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description), // Icon for My Passes
            label: 'My Passes',
          ),
          BottomNavigationBarItem(
            // Add Request Pass item
            icon: Icon(Icons.add_box),
            label: 'Request Pass',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          if (_isAdmin)
            BottomNavigationBarItem(
              icon: const Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
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
