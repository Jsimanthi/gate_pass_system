// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/presentation/auth/login_screen.dart';
import 'package:gatepass_app/presentation/home/home_screen.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  const String baseUrl = 'http://127.0.0.1:8000';

  // Initialize AuthService first with a temporary null for ApiClient
  final authService = AuthService(sharedPreferences, null);

  // Initialize ApiClient with the authService instance
  final apiClient = ApiClient(baseUrl, authService);

  // Now, set the fully initialized ApiClient instance to AuthService
  authService.setApiClient(apiClient);

  runApp(MyApp(authService: authService, apiClient: apiClient));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final ApiClient apiClient;

  const MyApp({super.key, required this.authService, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gate Pass System',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        // FIX: Change CardTheme() to CardThemeData()
        cardTheme: CardThemeData(
          // Changed from CardTheme()
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<bool>(
        future: authService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error checking login status: ${snapshot.error}'),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data == true) {
              return HomeScreen(apiClient: apiClient, authService: authService);
            } else {
              return LoginScreen(
                authService: authService,
                apiClient: apiClient,
              );
            }
          }
        },
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) =>
            LoginScreen(authService: authService, apiClient: apiClient),
        '/home': (context) =>
            HomeScreen(apiClient: apiClient, authService: authService),
      },
    );
  }
}
