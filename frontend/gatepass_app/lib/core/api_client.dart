// File: lib/core/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gatepass_app/config/app_config.dart';
import 'package:gatepass_app/services/auth_service.dart'; // Import AuthService

class ApiClient {
  final String _baseUrl = AppConfig.baseUrl;
  AuthService? _authService; // Make it nullable

  ApiClient(); // Default constructor

  // Setter for AuthService, used to break circular dependency
  void setAuthService(AuthService service) {
    _authService = service;
  }

  // Helper to add Authorization header
  Future<Map<String, String>> _getHeaders({String? customToken}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    String? token = customToken;

    // Only try to get token from AuthService if _authService is set and customToken is null
    if (token == null && _authService != null) {
      token = await _authService!.getAccessToken();
    }

    if (token != null && token.isNotEmpty) { // Also check if token is not empty
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- GET Request ---
  Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  // --- POST Request ---
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? customToken,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(customToken: customToken);

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  // ... (PUT and DELETE methods are similar, make sure to call _getHeaders with customToken if applicable) ...
   // --- PUT Request ---
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? customToken,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(customToken: customToken);

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  // --- DELETE Request ---
  Future<Map<String, dynamic>> delete(String endpoint, {String? customToken}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(customToken: customToken);

    final response = await http.delete(url, headers: headers);
    return _handleResponse(response);
  }


  // --- Helper to handle responses ---
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return {'message': 'Success, no content'};
    } else {
      String errorMessage = 'Failed to load data. Status code: ${response.statusCode}';
      if (response.body.isNotEmpty) {
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'];
          } else if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else {
            errorMessage = response.body;
          }
        } catch (e) {
          errorMessage = 'Failed to parse error response: ${response.body}';
        }
      }
      throw Exception(errorMessage);
    }
  }
}