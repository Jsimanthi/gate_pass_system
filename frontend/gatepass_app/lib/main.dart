// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/presentation/auth/login_screen.dart';
import 'package:gatepass_app/presentation/home/home_screen.dart';
import 'package:gatepass_app/presentation/reports/reports_screen.dart';
import 'package:gatepass_app/presentation/admin/admin_screen.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Import this to use kIsWeb
import 'firebase_options.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Import for web database
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // <--- NEW IMPORT for desktop/mobile FFI
// Import for databaseFactory

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI for desktop/mobile, then override for web
  // This must be called before any database operations
  sqfliteFfiInit(); // <--- NEW: Initialize FFI for all platforms first

  if (kIsWeb) {
    // For web, use the sqflite_ffi_web factory
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    // For non-web platforms (desktop, mobile), use the FFI factory
    databaseFactory = databaseFactoryFfi; // <--- NEW: Assign FFI factory for non-web
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");

  final sharedPreferences = await SharedPreferences.getInstance();
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://127.0.0.1:8000';

  final authService = AuthService(sharedPreferences, null);
  final apiClient = ApiClient(baseUrl, authService);
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
        cardTheme: CardThemeData(
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
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
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
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error checking login status: ${snapshot.error}'),
              ),
            );
          } else {
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
        '/reports': (context) => ReportsScreen(apiClient: apiClient),
        '/admin': (context) =>
            AdminScreen(apiClient: apiClient, authService: authService),
      },
    );
  }
}
