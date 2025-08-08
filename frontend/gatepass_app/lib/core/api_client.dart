// File: lib/core/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gatepass_app/services/auth_service.dart'; // Import AuthService
import 'package:flutter/foundation.dart'; // Import for debugPrint

// Custom Exception for API Errors
class ApiError implements Exception {
  final int statusCode;
  final String message;

  ApiError({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiError(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  final String _baseUrl;
  AuthService?
  _authService; // Made nullable to handle circular dependency during initialization

  // Constructor now requires baseUrl and AuthService instance (can be null initially)
  ApiClient(this._baseUrl, this._authService);

  // Setter for AuthService, used to break circular dependency during initial app setup
  void setAuthService(AuthService service) {
    _authService = service;
  }

  // Helper to add Authorization header
  Future<Map<String, String>> _getHeaders({String? customToken}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json', // Added Accept header for consistency
    };
    // Use null-aware assignment for cleaner code
    customToken ??= await _authService
        ?.getAccessToken(); // Access via ? for nullable _authService

    if (customToken != null && customToken.isNotEmpty) {
      headers['Authorization'] =
          'Bearer $customToken'; // Using Bearer token as per your Django setup
    }
    return headers;
  }

  // --- GET Request ---
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();

    debugPrint('API GET Request to: $url');
    debugPrint('Headers: $headers');

    final response = await http.get(url, headers: headers);

    debugPrint('API GET Response Status: ${response.statusCode}');
    debugPrint('API GET Response Body: ${response.body}');

    return _handleResponse(response);
  }

  // --- POST Request ---
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? customToken,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(customToken: customToken);

    debugPrint('API POST Request to: $url');
    debugPrint('Headers: $headers');
    debugPrint('Body: ${json.encode(body)}');

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    debugPrint('API POST Response Status: ${response.statusCode}');
    debugPrint('API POST Response Body: ${response.body}');

    return _handleResponse(response);
  }

  // --- PUT Request ---
  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? customToken, // Corrected parameter name
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(
      customToken: customToken,
    ); // Corrected parameter name here too

    debugPrint('API PUT Request to: $url');
    debugPrint('Headers: $headers');
    debugPrint('Body: ${json.encode(body)}');

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );

    debugPrint('API PUT Response Status: ${response.statusCode}');
    debugPrint('API PUT Response Body: ${response.body}');

    return _handleResponse(response);
  }

  // --- DELETE Request ---
  Future<dynamic> delete(String endpoint, {String? customToken}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders(customToken: customToken);

    debugPrint('API DELETE Request to: $url');
    debugPrint('Headers: $headers');

    final response = await http.delete(url, headers: headers);

    debugPrint('API DELETE Response Status: ${response.statusCode}');
    debugPrint('API DELETE Response Body: ${response.body}');

    return _handleResponse(response);
  }

  // --- Helper to handle responses ---
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          return json.decode(response.body);
        } catch (e) {
          debugPrint(
            'Warning: Non-JSON 2xx response for ${response.request?.url}: ${response.body}',
          );
          // For successful but non-JSON responses, return a simple success map or the raw body
          return {'message': 'Success', 'body': response.body};
        }
      }
      // If the body is empty but status is 2xx, return null or an empty map
      return null;
    } else {
      String errorMessage = 'An unknown error occurred.';
      if (response.body.isNotEmpty) {
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map) {
            // Standard DRF error responses
            if (errorData.containsKey('detail')) {
              errorMessage = errorData['detail'];
            } else if (errorData.containsKey('message')) {
              errorMessage = errorData['message'];
            }
            // Handling DRF validation errors (e.g., {'field': ['error message']})
            else {
              final firstError = errorData.entries.first;
              errorMessage = '${firstError.key}: ${firstError.value[0]}';
            }
          } else {
            errorMessage = response.body; // Fallback for non-JSON error bodies
          }
        } catch (e) {
          errorMessage = 'Failed to parse error response: ${response.body}';
        }
      } else {
          errorMessage = 'API returned status ${response.statusCode} with no content.';
      }
      debugPrint(
        'API Error: $errorMessage (URL: ${response.request?.url}, Status: ${response.statusCode})',
      );
      throw ApiError(statusCode: response.statusCode, message: errorMessage);
    }
  }

  Future<Map<String, dynamic>> verifyQrCode(String qrCode) async {
    final response = await post('/api/gate-operations/scan_qr_code/', {
      'qr_code_data': qrCode,
    });
    return response;
  }
}
