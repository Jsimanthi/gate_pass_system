import 'dart:convert';
import 'package:gatepass_app/core/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiClient _apiClient;
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  AuthService(this._apiClient);

  // --- Login Method ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        'token/', // Assuming your JWT login endpoint is /api/token/
        {'username': username, 'password': password},
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
      return {'success': false, 'message': e.toString()};
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