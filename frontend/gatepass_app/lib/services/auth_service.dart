// File: lib/services/auth_service.dart

import 'dart:convert';
import 'package:gatepass_app/core/api_client.dart'; // Ensure this is imported
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class AuthService {
  final SharedPreferences _prefs;
  ApiClient? _apiClient; // Made nullable, will be set after init

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  // Constructor now requires only SharedPreferences for initial setup
  AuthService(this._prefs, this._apiClient); // Keep apiClient in constructor, but allow for initial null

  // New method to set ApiClient after it's fully initialized in main.dart
  void setApiClient(ApiClient client) {
    _apiClient = client;
  }

  // --- Login Method ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (_apiClient == null) {
      return {'success': false, 'message': 'API Client not initialized in AuthService.'};
    }
    try {
      final response = await _apiClient!.post( // Use _apiClient! assuming it's set
        '/api/token/', // Your Django REST Framework Simple JWT token endpoint
        {'username': username, 'password': password},
      );

      if (response.containsKey('access') && response.containsKey('refresh')) {
        await _prefs.setString(_accessTokenKey, response['access']);
        await _prefs.setString(_refreshTokenKey, response['refresh']);
        return {'success': true, 'message': 'Login successful'};
      } else {
        return {'success': false, 'message': 'Invalid response from server: Token not found'};
      }
    } catch (e) {
      String errorMessage = 'An unknown error occurred: ${e.toString()}';
      if (e is Exception) {
        if (e.toString().contains('401')) {
          errorMessage = 'Invalid credentials. Please try again.';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Bad request. Check username/password format or server logs.';
        } else if (e.toString().contains('Failed host lookup') || e.toString().contains('Connection refused')) {
          errorMessage = 'Cannot connect to server. Check your network or server address.';
        } else {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      }
      debugPrint('AuthService Login Error: $e');
      return {'success': false, 'message': errorMessage};
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
    return _prefs.getString(_accessTokenKey);
  }

  // --- Get Refresh Token ---
  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  // --- Check if user is logged in (has an access token) ---
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}