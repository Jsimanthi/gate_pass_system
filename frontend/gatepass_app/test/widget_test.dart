// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gatepass_app/main.dart'; // Import your main app file
import 'package:gatepass_app/services/auth_service.dart'; // Import AuthService
import 'package:gatepass_app/core/api_client.dart';       // Import ApiClient
import 'package:shared_preferences/shared_preferences.dart'; // Needed for AuthService mock
import 'package:mockito/mockito.dart'; // Import mockito for mocking
import 'package:mockito/annotations.dart';

import 'widget_test.mocks.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// Create mock classes for AuthService and ApiClient
@GenerateMocks([ApiClient, AuthService, SharedPreferences])
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // Group tests related to your main application widget
  group('MyApp widget tests', () {
    // Helper to set screen size for responsive tests
    void setScreenSize(WidgetTester tester, Size size) {
      final view = tester.view;
      view.physicalSize = size;
      view.devicePixelRatio = 1.0;
      // Add a tear down to clear the values after the test
      addTearDown(view.reset);
    }

    // Setup mocks before each test
    late MockAuthService mockAuthService;
    late MockApiClient mockApiClient;

    setUp(() {
      mockAuthService = MockAuthService();
      mockApiClient = MockApiClient();

      // Stub the isLoggedIn method to return true for initial tests,
      // simulating a logged-in state or handling the FutureBuilder.
      // You might want to test both logged-in and logged-out states.
      when(mockAuthService.isLoggedIn()).thenAnswer((_) async => true);
      // Stub other methods if they are called directly in MyApp or initial screens
      when(mockAuthService.getAccessToken()).thenAnswer((_) async => 'mock_token');
      when(mockAuthService.getUserRole()).thenAnswer((_) async => 'Admin');
      when(mockApiClient.get(any)).thenAnswer((_) async => {
            'pending_count': 0,
            'approved_count': 0,
            'rejected_count': 0,
          });
    });

    testWidgets('MyApp renders correctly', (WidgetTester tester) async {
      setScreenSize(tester, const Size(1200, 800));
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MyApp(
          authService: mockAuthService,
          apiClient: mockApiClient,
        ),
      );

      // Verify that the CircularProgressIndicator is shown initially (due to FutureBuilder)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Allow the FutureBuilder to complete
      await tester.pumpAndSettle();

      // After settling, it should navigate to HomeScreen because isLoggedIn returns true.
      // Verify that HomeScreen (or a widget specific to HomeScreen like an AppBar title) is present.
      expect(find.text('Gate Pass System'), findsOneWidget); // Assuming your AppBar title in HomeScreen is 'Gate Pass System'
      expect(find.byType(NavigationRail), findsOneWidget); // Expect the navigation rail
    });

    // You can add more specific tests here, for example:
    // testWidgets('MyApp navigates to LoginScreen if not logged in', (WidgetTester tester) async {
    //   when(mockAuthService.isLoggedIn()).thenAnswer((_) async => false); // Mock not logged in
    //
    //   await tester.pumpWidget(
    //     MyApp(
    //       authService: mockAuthService,
    //       apiClient: mockApiClient,
    //     ),
    //   );
    //
    //   await tester.pumpAndSettle();
    //
    //   expect(find.text('Login'), findsOneWidget); // Assuming LoginScreen has a 'Login' title
    //   expect(find.byType(TextField), findsNWidgets(2)); // Expect username and password fields
    // });
  });
}