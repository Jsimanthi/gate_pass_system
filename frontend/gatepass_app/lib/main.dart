import 'package:flutter/material.dart';
import 'package:gatepass_app/presentation/auth/login_screen.dart';
import 'package:gatepass_app/presentation/home/home_screen.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart';

void main() {
  runApp(const GatePassApp());
}

class GatePassApp extends StatefulWidget {
  const GatePassApp({super.key});

  @override
  State<GatePassApp> createState() => _GatePassAppState();
}

class _GatePassAppState extends State<GatePassApp> {
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = AuthService(ApiClient()).isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gate Pass System',
      theme: ThemeData(
        // --- START OF UI ENHANCEMENT: Material 3 Theme ---
        useMaterial3: true, // Enable Material 3
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey, // Your primary brand color
          brightness: Brightness.light, // Or .dark for dark theme
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey, // Customize app bar background
          foregroundColor: Colors.white, // Customize app bar text/icon color
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
            minimumSize: const Size(double.infinity, 50), // Full width buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        // --- END OF UI ENHANCEMENT ---
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<bool>(
        future: _isLoggedInFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            if (snapshot.hasData && snapshot.data == true) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}