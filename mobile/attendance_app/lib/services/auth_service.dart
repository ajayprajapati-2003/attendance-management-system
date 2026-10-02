import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  /// Registers a new user with first name, last name, email, and password.
  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final errorMessage = responseData['error'] ??
            responseData['message'] ??
            'Registration failed (Status: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: Unable to connect to server ($e)');
    }
  }

  /// Authenticates the user with email and password, storing session tokens on success.
  Future<void> login(String email, String password) async {
    final url = Uri.parse('${AppConstants.baseUrl}/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final token = responseData['token'] as String?;
        final userId = responseData['user_id'];
        final role = responseData['role'] as String?;

        if (token == null) {
          throw Exception('Authentication token missing in server response.');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        if (userId != null) {
          await prefs.setString('user_id', userId.toString());
        }
        if (role != null) {
          await prefs.setString('role', role);
        }
        await prefs.setString('email', email.trim());
      } else {
        final errorMessage = responseData['error'] ??
            responseData['message'] ??
            'Login failed (Status: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: Unable to connect to server ($e)');
    }
  }

  /// Retrieves stored JWT token.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Retrieves stored User ID.
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  /// Retrieves stored user role.
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  /// Checks if user has a stored session token.
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clears stored authentication session.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('role');
    await prefs.remove('email');
  }
}
