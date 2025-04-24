// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  static const _prefsTokenKey = 'authToken';

  static Future<User?> login(String username, String password) async {
    // Adjust endpoint as needed
    final body = {'username': username, 'password': password};
    final result = await ApiClient.post('/login', body);

    // Convert JSON to a User object
    final user = User.fromJson(result);

    // Save token in memory & local storage
    ApiClient.authToken = user.token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsTokenKey, user.token);

    return user;
  }

  static Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefsTokenKey);
    if (token != null && token.isNotEmpty) {
      ApiClient.authToken = token;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTokenKey);
    ApiClient.authToken = null;
  }
}
