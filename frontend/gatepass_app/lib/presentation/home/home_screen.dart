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
import 'package:gatepass_app/presentation/profile/profile_screen.dart';

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
    if (mounted) {
      setState(() {
        _offlineScans = scans;
      });
    }
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
        debugPrint('Error syncing QR code: ${scan['qr_code_data']}. Error: $e');
      }
    }
    if (mounted) {
      _loadOfflineScans();
    }
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

  Future<String?> _getUserRoleFuture() async {
    final role = await _authService.getUserRole();
    debugPrint('HomeScreen: User role is $role');
    return role;
  }

  // Helper method to build navigation destinations to avoid duplication
  List<Widget> _getScreenWidgets(String userRole) {
    List<Widget> widgetOptions = [
      DashboardOverviewScreen(apiClient: _apiClient, authService: _authService),
    ];
    if (userRole == 'Admin') {
      widgetOptions.addAll([
        MyPassesScreen(apiClient: _apiClient, authService: _authService),
        GatePassRequestScreen(apiClient: _apiClient, authService: _authService),
        QrScannerScreen(apiClient: _apiClient),
        ReportsScreen(apiClient: _apiClient),
        AdminScreen(apiClient: _apiClient, authService: _authService),
      ]);
    } else if (userRole == 'Security') {
      widgetOptions.addAll([
        QrScannerScreen(apiClient: _apiClient),
        ReportsScreen(apiClient: _apiClient),
      ]);
    } else if (userRole == 'Client Care') {
      widgetOptions.addAll([
        AdminScreen(apiClient: _apiClient, authService: _authService),
        ReportsScreen(apiClient: _apiClient),
      ]);
    } else if (userRole == 'User') {
      widgetOptions.addAll([
        MyPassesScreen(apiClient: _apiClient, authService: _authService),
        GatePassRequestScreen(apiClient: _apiClient, authService: _authService),
        ReportsScreen(apiClient: _apiClient),
      ]);
    }
    return widgetOptions;
  }

  List<NavigationDestination> _getNavigationDestinations(String userRole) {
    List<NavigationDestination> navBarItems = [
      const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    ];
    if (userRole == 'Admin') {
      navBarItems.addAll([
        const NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'My Passes'),
        const NavigationDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: 'Request Pass'),
        const NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Scan QR'),
        const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
        const NavigationDestination(icon: Icon(Icons.sensor_door_outlined), selectedIcon: Icon(Icons.sensor_door), label: 'Manage Passes'),
      ]);
    } else if (userRole == 'Security') {
      navBarItems.addAll([
        const NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Scan QR'),
        const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
      ]);
    } else if (userRole == 'Client Care') {
      navBarItems.addAll([
        const NavigationDestination(icon: Icon(Icons.sensor_door_outlined), selectedIcon: Icon(Icons.sensor_door), label: 'Manage Passes'),
        const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
      ]);
    } else if (userRole == 'User') {
      navBarItems.addAll([
        const NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'My Passes'),
        const NavigationDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: 'Request Pass'),
        const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
      ]);
    }
    return navBarItems;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRoleFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _logout();
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userRole = snapshot.data!;
        final screens = _getScreenWidgets(userRole);
        final destinations = _getNavigationDestinations(userRole);

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
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 640) {
                // Use BottomNavigationBar for small screens
                return Scaffold(
                  body: IndexedStack(
                    index: _selectedIndex,
                    children: screens,
                  ),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                    destinations: destinations,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  ),
                );
              } else {
                // Use NavigationRail for wider screens
                return Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onItemTapped,
                      labelType: NavigationRailLabelType.all,
                      destinations: destinations
                          .map((d) => NavigationRailDestination(
                                icon: d.icon,
                                selectedIcon: d.selectedIcon,
                                label: Text(d.label),
                              ))
                          .toList(),
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: screens,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }
}
