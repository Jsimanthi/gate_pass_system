// File: lib/services/auth_service.dart

import 'dart:convert';
import 'package:gatepass_app/core/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  ApiClient _apiClient; // Make it non-nullable again
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  AuthService(this._apiClient) {
    // When AuthService is created, set itself in the ApiClient
    // This handles the circular dependency
    _apiClient.setAuthService(this);
  }

  // --- Login Method ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        '/api/token/',
        {'username': username, 'password': password},
        customToken: '', // Ensure no token is sent for the login itself
      );

      if (response.containsKey('access') && response.containsKey('refresh')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, response['access']);
        await prefs.setString(_refreshTokenKey, response['refresh']);
        return {'success': true, 'message': 'Login successful'};
      } else {
        return {'success': false, 'message': 'Invalid response from server'};
      }
    } catch (e) {
      String errorMessage = 'An unknown error occurred: ${e.toString()}';
      if (e.toString().contains('401')) {
        errorMessage = 'Invalid credentials. Please try again.';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Bad request. Check username/password format or server logs.';
      } else if (e.toString().contains('Failed host lookup')) {
        errorMessage = 'Cannot connect to server. Check your network or server address.';
      }
      return {'success': false, 'message': errorMessage};
    }
  }

  // --- Logout Method ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  // --- Get Access Token ---
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // --- Get Refresh Token ---
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // --- Check if user is logged in (has an access token) ---
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // TODO: Implement refresh token logic if needed for long-lived sessions
  // Future<String?> refreshAccessToken() async {
  //   final refreshToken = await getRefreshToken();
  //   if (refreshToken == null) return null;
  //
  //   try {
  //     final response = await _apiClient.post(
  //       'token/refresh/', // Assuming your JWT refresh endpoint
  //       {'refresh': refreshToken},
  //       customToken: '', // No token needed for refresh request itself
  //     );
  //
  //     if (response.containsKey('access')) {
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString(_accessTokenKey, response['access']);
  //       return response['access'];
  //     }
  //   } catch (e) {
  //     print('Error refreshing token: $e');
  //   }
  //   await logout(); // Logout if refresh fails
  //   return null;
  // }
}