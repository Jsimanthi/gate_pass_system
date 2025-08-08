import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/auth_service.dart';
import 'package:gatepass_app/presentation/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final ApiClient apiClient;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.apiClient,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  late final AuthService _authService;
  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService;
    _apiClient = widget.apiClient;
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    final result = await _authService.login(username, password);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        if (mounted) {
          // Check if the widget is still in the tree
          // Navigate to HomeScreen on successful login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(apiClient: _apiClient, authService: _authService),
            ),
          );
        }
      } else {
        _errorMessage = result['message'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen width to adjust the maximum width of the login card
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600
        ? 400.0
        : screenWidth * 0.9; // Max 400px or 90% of screen width

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 24.0,
          ), // Padding around the scrollable content
          child: ConstrainedBox(
            // Constrain the width of the card on larger screens
            constraints: BoxConstraints(maxWidth: cardWidth),
            child: Card(
              elevation: 8, // Increased elevation for a more prominent look
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  16,
                ), // Slightly more rounded corners
              ),
              child: Padding(
                padding: const EdgeInsets.all(
                  32.0,
                ), // Increased padding inside the card
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Make column only take needed space
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Company Logo and Name ---
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/sblt_logo.png', // Make sure this path is correct
                          height: 50, // Adjust the height as needed
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sri Bhagiyalakhsmi Enterprise',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(
                          height: 24,
                        ), // Spacing after the company name
                      ],
                    ),
                    // --- Title / Welcome Text ---
                    Text(
                      'GATE PASS',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue to your Gate Pass account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                      ),
                    ),
                    const SizedBox(height: 32), // More space before text fields
                    // --- Username Field ---
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        prefixIcon: Icon(Icons.person),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(
                      height: 16,
                    ), // Adjusted spacing between fields
                    // --- Password Field ---
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(
                      height: 24,
                    ), // Spacing before error message/button
                    // --- Error Message ---
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // --- Login Button ---
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ), // Make button taller
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeWidth: 2,
                            )
                          : const Text('Login'),
                    ),
                    const SizedBox(height: 16),

                    // --- Forgot Password Button ---
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Forgot Password? Feature not implemented yet.',
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.primary, // Use primary color
                      ),
                      child: const Text('Forgot Password?'),
                    ),
                    // Optional: Add a "Don't have an account?" text and Sign Up button here
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
