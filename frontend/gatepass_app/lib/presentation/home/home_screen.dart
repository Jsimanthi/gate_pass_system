// File: lib/presentation/home/home_screen.dart

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
  int _selectedIndex = 0;
  late final ApiClient _apiClient;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient;
    _authService = widget.authService;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              LoginScreen(apiClient: _apiClient, authService: _authService),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  // A Future that resolves with the user's role
  Future<String?> _getUserRoleFuture() async {
    final role = await _authService.getUserRole();
    debugPrint('HomeScreen: User role is $role');
    return role;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRoleFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while we fetch the role
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          // Show an error screen if something went wrong
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (snapshot.data == null) {
          // If the role is null, something is wrong with the token.
          // Force logout and navigate to login.
          _logout();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // We have a valid user role, build the screen
        final _userRole = snapshot.data!;
        List<Widget> _widgetOptions = [];
        List<BottomNavigationBarItem> _navBarItems = [];

        // Common item for all roles
        _widgetOptions.add(
          DashboardOverviewScreen(
            apiClient: _apiClient,
            authService: _authService,
          ),
        );
        _navBarItems.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        );

        // Role-based navigation items
        if (_userRole == 'Admin') {
          _widgetOptions.addAll([
            MyPassesScreen(apiClient: _apiClient, authService: _authService),
            GatePassRequestScreen(
              apiClient: _apiClient,
              authService: _authService,
            ),
            QrScannerScreen(apiClient: _apiClient),
            ReportsScreen(apiClient: _apiClient),
            AdminScreen(apiClient: _apiClient, authService: _authService),
          ]);
          _navBarItems.addAll([
            const BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: 'My Passes',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_box),
              label: 'Request Pass',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan QR',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Manage Passes',
            ),
          ]);
        } else if (_userRole == 'Security') {
          _widgetOptions.addAll([
            QrScannerScreen(apiClient: _apiClient),
            ReportsScreen(apiClient: _apiClient),
          ]);
          _navBarItems.addAll([
            const BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan QR',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ]);
        } else if (_userRole == 'Client Care') {
          _widgetOptions.addAll([
            AdminScreen(apiClient: _apiClient, authService: _authService),
            ReportsScreen(apiClient: _apiClient),
          ]);
          _navBarItems.addAll([
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Manage Passes',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ]);
        } else if (_userRole == 'User') {
          _widgetOptions.addAll([
            MyPassesScreen(apiClient: _apiClient, authService: _authService),
            GatePassRequestScreen(
              apiClient: _apiClient,
              authService: _authService,
            ),
            ReportsScreen(apiClient: _apiClient),
          ]);
          _navBarItems.addAll([
            const BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: 'My Passes',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_box),
              label: 'Request Pass',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ]);
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Image.asset('assets/images/sblt_logo.png', height: 40),
            ),
            title: const Text('Gate Pass System'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        apiClient: _apiClient,
                        authService: _authService,
                      ),
                    ),
                  );
                },
                tooltip: 'Profile',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
          body: _widgetOptions.elementAt(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            items: _navBarItems,
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }
}
