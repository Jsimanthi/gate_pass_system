// File: lib/presentation/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/presentation/auth/login_screen.dart';
import 'package:gatepass_app/presentation/dashboard/dashboard_overview_screen.dart';
import 'package:gatepass_app/presentation/my_passes/my_passes_screen.dart';
import 'package:gatepass_app/presentation/gate_pass_request/gate_pass_request_screen.dart';
import 'package:gatepass_app/presentation/security/qr_scanner_screen.dart';
import 'package:gatepass_app/services/local_database_service.dart';
import 'package:gatepass_app/presentation/reports/reports_screen.dart';
import 'package:gatepass_app/presentation/admin/admin_screen.dart';
import 'package:gatepass_app/presentation/profile/profile_screen.dart'; // Import ProfileScreen

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
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService.instance;
  List<Map<String, dynamic>> _offlineScans = [];

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient;
    _authService = widget.authService;
    _loadOfflineScans();
  }

  Future<void> _loadOfflineScans() async {
    final scans = await _localDatabaseService.getScannedQRCodes();
    setState(() {
      _offlineScans = scans;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _syncOfflineScans() async {
    for (var scan in _offlineScans) {
      try {
        await _apiClient.verifyQrCode(scan['qr_code_data']);
        await _localDatabaseService.deleteScannedQRCode(scan['id']);
      } catch (e) {
        // Handle sync error, maybe show a message to the user
        print('Error syncing QR code: ${scan['qr_code_data']}. Error: $e');
      }
    }
    _loadOfflineScans();
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
        final userRole = snapshot.data!;
        List<Widget> widgetOptions = [];
        List<BottomNavigationBarItem> navBarItems = [];

        // Common item for all roles
        widgetOptions.add(
          DashboardOverviewScreen(
            apiClient: _apiClient,
            authService: _authService,
          ),
        );
        navBarItems.add(
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        );

        // Role-based navigation items
        if (userRole == 'Admin') {
          widgetOptions.addAll([
            MyPassesScreen(apiClient: _apiClient, authService: _authService),
            GatePassRequestScreen(
              apiClient: _apiClient,
              authService: _authService,
            ),
            QrScannerScreen(apiClient: _apiClient),
            ReportsScreen(apiClient: _apiClient),
            AdminScreen(apiClient: _apiClient, authService: _authService),
          ]);
          navBarItems.addAll([
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
              icon: Icon(Icons.sensor_door),
              label: 'Manage Passes',
            ),
          ]);
        } else if (userRole == 'Security') {
          widgetOptions.addAll([
            QrScannerScreen(apiClient: _apiClient),
            ReportsScreen(apiClient: _apiClient),
          ]);
          navBarItems.addAll([
            const BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan QR',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ]);
        } else if (userRole == 'Client Care') {
          widgetOptions.addAll([
            AdminScreen(apiClient: _apiClient, authService: _authService),
            ReportsScreen(apiClient: _apiClient),
          ]);
          navBarItems.addAll([
            const BottomNavigationBarItem(
              icon: Icon(Icons.sensor_door),
              label: 'Manage Passes',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ]);
        } else if (userRole == 'User') {
          widgetOptions.addAll([
            MyPassesScreen(apiClient: _apiClient, authService: _authService),
            GatePassRequestScreen(
              apiClient: _apiClient,
              authService: _authService,
            ),
            ReportsScreen(apiClient: _apiClient),
          ]);
          navBarItems.addAll([
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
              if (_offlineScans.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: _syncOfflineScans,
                  tooltip: 'Sync Offline Data',
                ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
          body: widgetOptions.elementAt(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            items: navBarItems,
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