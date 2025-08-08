// File: lib/services/auth_service.dart

import 'package:gatepass_app/core/api_client.dart';
import 'package:gatepass_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  final SharedPreferences _prefs;
  ApiClient? _apiClient;
  final NotificationService _notificationService = NotificationService();

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  AuthService(this._prefs, this._apiClient);

  void setApiClient(ApiClient client) {
    _apiClient = client;
  }

  // --- Login Method ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (_apiClient == null) {
      return {
        'success': false,
        'message': 'API Client not initialized in AuthService.',
      };
    }
    try {
      final response = await _apiClient!.post('/api/token/', {
        'username': username,
        'password': password,
      });

      if (response.containsKey('access') && response.containsKey('refresh')) {
        await _prefs.setString(_accessTokenKey, response['access']);
        await _prefs.setString(_refreshTokenKey, response['refresh']);

        // After successful login, register the device for push notifications
        await _registerDevice();

        return {'success': true, 'message': 'Login successful'};
      } else {
        return {
          'success': false,
          'message': 'Invalid response from server: Token not found',
        };
      }
    } catch (e) {
      String errorMessage = 'An unknown error occurred: ${e.toString()}';
      if (e is Exception) {
        if (e.toString().contains('401')) {
          errorMessage = 'Invalid credentials. Please try again.';
        } else if (e.toString().contains('400')) {
          errorMessage =
              'Bad request. Check username/password format or server logs.';
        } else if (e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection refused')) {
          errorMessage =
              'Cannot connect to server. Check your network or server address.';
        } else {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      }
      debugPrint('AuthService Login Error: $e');
      return {'success': false, 'message': errorMessage};
    }
  }

  // --- Register Device for Push Notifications ---
  Future<void> _registerDevice() async {
    try {
      final token = await _notificationService.getFcmToken();
      if (token != null && _apiClient != null) {
        // Use a platform-specific name or a generic one
        final deviceName = defaultTargetPlatform == TargetPlatform.windows
            ? 'WindowsApp'
            : defaultTargetPlatform == TargetPlatform.linux
                ? 'LinuxApp'
                : defaultTargetPlatform == TargetPlatform.macOS
                    ? 'MacOSApp'
                    : 'WebApp'; // Fallback for web

        await _apiClient!.post('/api/users/devices/', {
          'registration_id': token,
          'name': deviceName,
          'type': 'web', // Or use a platform-specific type
        });
        debugPrint('Device registered for push notifications with token: $token');
      }
    } catch (e) {
      // Fail silently. We don't want to block login if this fails.
      debugPrint('Failed to register device for push notifications: $e');
    }
  }

  // --- Logout Method ---
  Future<void> logout() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    debugPrint('User logged out. Tokens removed.');
  }

  // --- Get Access Token ---
  Future<String?> getAccessToken() async {
    try {
      final token = _prefs.getString(_accessTokenKey);
      debugPrint('AuthService.getAccessToken(): Retrieved token from prefs.');
      return token;
    } catch (e) {
      debugPrint('AuthService.getAccessToken(): Error retrieving token: $e');
      return null;
    }
  }

  // --- Get Refresh Token ---
  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  // --- Check if user is logged in (has an access token) ---
  Future<bool> isLoggedIn() async {
    debugPrint('AuthService.isLoggedIn(): Method called.');
    try {
      final accessToken = await getAccessToken();
      final bool isLoggedIn = accessToken != null && accessToken.isNotEmpty;
      debugPrint('AuthService.isLoggedIn(): Result is $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      debugPrint('AuthService.isLoggedIn(): An unhandled error occurred: $e');
      return false;
    }
  }

  // --- Get User Role ---
  Future<String?> getUserRole() async {
    final accessToken = await getAccessToken();
    if (accessToken == null || JwtDecoder.isExpired(accessToken)) {
      debugPrint('AuthService.getUserRole(): Access token is null or expired.');
      return null;
    }
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
      debugPrint(
          'AuthService.getUserRole(): Decoded token payload: $decodedToken');

      // Check for 'is_staff' first, as 'admin' user has this
      if (decodedToken.containsKey('is_staff') &&
          decodedToken['is_staff'] == true) {
        debugPrint('AuthService.getUserRole(): User is Admin (from is_staff).');
        return 'Admin';
      }

      // Check for 'groups' if 'is_staff' is not true or not present
      if (decodedToken.containsKey('groups') &&
          decodedToken['groups'] is List) {
        List<dynamic> groups = decodedToken['groups'];
        if (groups.contains('Security')) {
          debugPrint(
              'AuthService.getUserRole(): User role is Security (from groups).');
          return 'Security';
        }
        if (groups.contains('Client Care')) {
          debugPrint(
              'AuthService.getUserRole(): User role is Client Care (from groups).');
          return 'Client Care';
        }
        // Add more group-based roles here if applicable
      }

      // If no specific role or staff status is found, default to 'User'
      debugPrint(
          'AuthService.getUserRole(): No specific role found, defaulting to User.');
      return 'User';
    } catch (e) {
      debugPrint(
          'AuthService.getUserRole(): Error decoding token or getting role: $e');
      return null;
    }
  }

  // --- Check if user is an admin ---
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'Admin';
  }

  // --- Check if user is Security ---
  Future<bool> isSecurity() async {
    final role = await getUserRole();
    return role == 'Security';
  }

  // --- Check if user is Client Care ---
  Future<bool> isClientCare() async {
    final role = await getUserRole();
    return role == 'Client Care';
  }

  // --- Check if user is a regular User ---
  Future<bool> isUser() async {
    final role = await getUserRole();
    return role == 'User';
  }
}
