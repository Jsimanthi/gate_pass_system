import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gatepass_app/config/app_config.dart'; // Import your AppConfig

class ApiClient {
  final String _baseUrl = AppConfig.baseUrl; // Use the base URL from config

  // --- GET Request ---
  Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  // --- POST Request ---
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  // --- PUT Request ---
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  // --- DELETE Request ---
  Future<Map<String, dynamic>> delete(String endpoint, {String? token}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{}; // No content type for DELETE usually
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.delete(url, headers: headers);
    return _handleResponse(response);
  }

  // --- Helper to handle responses ---
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Successful response
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return {'message': 'Success, no content'}; // For 204 No Content
    } else {
      // Error response
      String errorMessage =
          'Failed to load data. Status code: ${response.statusCode}';
      if (response.body.isNotEmpty) {
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'];
          } else if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else {
            errorMessage = response.body; // Fallback to raw error body
          }
        } catch (e) {
          errorMessage = 'Failed to parse error response: ${response.body}';
        }
      }
      throw Exception(errorMessage);
    }
  }
}
