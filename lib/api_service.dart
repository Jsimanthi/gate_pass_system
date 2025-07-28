import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/';

  static Future<Map<String, dynamic>> verifyQrCode(String qrCode) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}gate-operations/verify/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'qr_code': qrCode,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to verify QR code.');
    }
  }
}
