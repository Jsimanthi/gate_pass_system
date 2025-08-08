import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart'; // <-- Add this import
import 'package:mockito/mockito.dart';
import 'package:gatepass_app/presentation/home/home_screen.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/local_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gatepass_app/presentation/dashboard/dashboard_overview_screen.dart';

import 'home_screen_test.mocks.dart';

// Add this annotation here
@GenerateMocks([AuthService, ApiClient, LocalDatabaseService])
void main() {
  // Initialize FFI for sqflite, needed because HomeScreen uses LocalDatabaseService
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late MockAuthService mockAuthService;
  late MockApiClient mockApiClient;
  late MockLocalDatabaseService mockLocalDatabaseService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockApiClient = MockApiClient();
    mockLocalDatabaseService = MockLocalDatabaseService();

    // Add a default stub for the dashboard summary API call to prevent MissingStubError
    when(mockApiClient.get(any)).thenAnswer((_) async => {
          'total_passes': 0,
          'pending_passes': 0,
          'approved_passes': 0,
          'rejected_passes': 0,
        });
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: HomeScreen(
        authService: mockAuthService,
        apiClient: mockApiClient,
      ),
    );
  }

  // Helper to set screen size for responsive tests
  void setScreenSize(WidgetTester tester, Size size) {
    tester.binding.window.physicalSizeTestValue = size;
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    // Add a tear down to clear the values after the test
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
  }

  testWidgets('shows loading indicator while fetching role', (WidgetTester tester) async {
    when(mockAuthService.getUserRole()).thenAnswer((_) => Future.delayed(const Duration(seconds: 1), () => 'Admin'));
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('displays correct initial screen for Admin role', (WidgetTester tester) async {
    when(mockAuthService.getUserRole()).thenAnswer((_) async => 'Admin');
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    // Check that the first screen is the dashboard
    expect(find.byType(DashboardOverviewScreen), findsOneWidget);
  });

  testWidgets('shows NavigationBar on small screens for Admin', (WidgetTester tester) async {
    setScreenSize(tester, const Size(400, 800)); // Mobile size
    when(mockAuthService.getUserRole()).thenAnswer((_) async => 'Admin');
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    // Check for a label that is unique to the Admin role
    expect(find.text('Manage Passes'), findsOneWidget);
  });

  testWidgets('shows NavigationRail on large screens for Admin', (WidgetTester tester) async {
    setScreenSize(tester, const Size(1200, 800)); // Desktop size
    when(mockAuthService.getUserRole()).thenAnswer((_) async => 'Admin');
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // Check for a label that is unique to the Admin role
    expect(find.text('Manage Passes'), findsOneWidget);
  });
}