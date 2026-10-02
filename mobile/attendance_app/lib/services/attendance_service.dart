import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AttendanceService {
  /// Helper to retrieve stored auth token
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }
    return token;
  }

  /// Sends a clock-in request with GPS coordinates and authentication token.
  Future<void> clockIn(double lat, double lng) async {
    final token = await _getToken();
    final url = Uri.parse('${AppConstants.baseUrl}/attendance/clock-in');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
        }),
      );

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorMessage = responseData['error'] ??
            responseData['message'] ??
            'Clock-in failed (Status: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error during clock-in: $e');
    }
  }

  /// Sends a clock-out request with GPS coordinates and authentication token.
  Future<void> clockOut(double lat, double lng) async {
    final token = await _getToken();
    final url = Uri.parse('${AppConstants.baseUrl}/attendance/clock-out');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
        }),
      );

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorMessage = responseData['error'] ??
            responseData['message'] ??
            'Clock-out failed (Status: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error during clock-out: $e');
    }
  }

  /// Fetches today's attendance record from backend.
  Future<Map<String, dynamic>?> getTodayAttendance() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${AppConstants.baseUrl}/attendance/today');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic>) {
          return responseData;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches attendance history from backend.
  Future<List<dynamic>> getHistory() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${AppConstants.baseUrl}/attendance/history');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic>) {
          final history = responseData['history'] ?? responseData['records'];
          if (history is List) {
            return history;
          }
        } else if (responseData is List) {
          return responseData;
        }
      }
      return [];
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to load attendance history: $e');
    }
  }
}
