// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // TODO: Replace with your real base URL
  static const String baseUrl = 'https://example.com/api';

  // We can keep an in-memory token or pass it in from AuthService
  static String? authToken;

  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(
      url,
      headers: _buildHeaders(),
    );
    return _parseResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  static Future<dynamic> postForm(String endpoint, Map<String, String> fields) async {
    // For form-data or multipart
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: {
        ..._buildHeaders(),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: fields,
    );
    return _parseResponse(response);
  }

  static Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  static dynamic _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
  }
}
