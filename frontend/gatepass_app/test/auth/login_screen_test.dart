import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mockito/mockito.dart';
import 'package:gatepass_app/presentation/auth/login_screen.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/presentation/home/home_screen.dart';

import 'login_screen_test.mocks.dart';

void main() {
  // Initialize FFI for sqflite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late MockAuthService mockAuthService;
  late MockApiClient mockApiClient;

  setUp(() {
    mockAuthService = MockAuthService();
    mockApiClient = MockApiClient();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: LoginScreen(
        authService: mockAuthService,
        apiClient: mockApiClient,
      ),
    );
  }

  testWidgets('LoginScreen should render correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('GATE PASS'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });

  testWidgets('should show error message on failed login', (WidgetTester tester) async {
    when(mockAuthService.login(any, any)).thenAnswer(
      (_) async => {'success': false, 'message': 'Invalid credentials'},
    );

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField).first, 'testuser');
    await tester.enterText(find.byType(TextField).last, 'wrongpassword');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump(); // Re-render after state change

    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('should navigate to HomeScreen on successful login', (WidgetTester tester) async {
    when(mockAuthService.login(any, any)).thenAnswer(
      (_) async => {'success': true, 'token': 'fake_token'},
    );

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField).first, 'testuser');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));

    // Wait for navigation to complete
    await tester.pumpAndSettle();

    // Check if HomeScreen is now on screen
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
