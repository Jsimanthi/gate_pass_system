import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gatepass_app/presentation/home/home_screen.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/local_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'home_screen_test.mocks.dart';

void main() {
  // Initialize FFI for sqflite, needed because HomeScreen uses LocalDatabaseService
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late MockAuthService mockAuthService;
  late MockApiClient mockApiClient;
  // This mock is not injected, but we can use it if we refactor later.
  // For now, the real service will run against an in-memory FFI database.
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

    // Since LocalDatabaseService is not injected, we can't stop it from running.
    // But we can mock the other services that HomeScreen depends on.
    // We will let the real LocalDatabaseService run, which is fine in a test
    // environment thanks to sqflite_common_ffi.
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: HomeScreen(
        authService: mockAuthService,
        apiClient: mockApiClient,
      ),
    );
  }

  testWidgets('shows loading indicator while fetching role', (WidgetTester tester) async {
    // Arrange: Don't complete the future immediately
    when(mockAuthService.getUserRole()).thenAnswer((_) => Future.delayed(const Duration(seconds: 1), () => 'Admin'));

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert: Loading indicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the future complete
    await tester.pumpAndSettle();
  });

  testWidgets('shows Admin UI for Admin role', (WidgetTester tester) async {
    // Arrange
    when(mockAuthService.getUserRole()).thenAnswer((_) async => 'Admin');

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(); // Wait for FutureBuilder to complete

    // Assert
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('My Passes'), findsOneWidget);
    expect(find.text('Request Pass'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Manage Passes'), findsOneWidget);
    expect(find.byIcon(Icons.sensor_door), findsOneWidget); // Icon for Manage Passes
  });

  testWidgets('shows User UI for User role', (WidgetTester tester) async {
    // Arrange
    when(mockAuthService.getUserRole()).thenAnswer((_) async => 'User');

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(); // Wait for FutureBuilder to complete

    // Assert
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('My Passes'), findsOneWidget);
    expect(find.text('Request Pass'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);

    // These should NOT be visible for a standard User
    expect(find.text('Scan QR'), findsNothing);
    expect(find.text('Manage Passes'), findsNothing);
    expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
    expect(find.byIcon(Icons.sensor_door), findsNothing);
  });
}
