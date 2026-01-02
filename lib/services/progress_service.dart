// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Base headers
  Future<Map<String, String>> getHeaders({bool withAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await _getToken();
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Get token from shared preferences
  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token') ?? '';
    } catch (e) {
      return '';
    }
  }

  // Save token
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token.isNotEmpty;
  }

  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Generic GET request
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? params}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint')
        .replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: await getHeaders(),
    );

    return _handleResponse(response);
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: await getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please login again.');
    } else if (response.statusCode == 403) {
      throw Exception('Access forbidden.');
    } else if (response.statusCode == 404) {
      throw Exception('Resource not found.');
    } else if (response.statusCode >= 500) {
      throw Exception('Server error. Please try again later.');
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }
}