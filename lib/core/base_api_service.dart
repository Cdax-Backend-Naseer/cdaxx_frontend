// Base API Service - COMPLETE WORKING VERSION
// Abstract base class for all API services with common functionality
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../config/environment_config.dart';
import 'api_response.dart' as core;
import 'error_handler.dart';
import '../services/secure_storage_service.dart';

abstract class BaseApiService {
  final http.Client _client = http.Client();
  final SecureStorageService _secureStorage = SecureStorageService.instance;

  // Set authentication token (optional, for backward compatibility)
  void setAuthToken(String token) {
    // Not needed anymore - we get token from secure storage automatically
  }

  // Clear authentication token (optional, for backward compatibility)
  void clearAuthToken() {
    // Not needed anymore - token is managed by SecureStorageService
  }

  // Get common headers with JWT token
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Get JWT token from secure storage
    final token = await _secureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Build full URL
  String _buildUrl(String endpoint) {
    // Remove leading slash if present to avoid double slashes
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

    // Check if endpoint already contains /api
    if (cleanEndpoint.startsWith('api/')) {
      // Endpoint already has /api, don't add it again
      return '${EnvironmentConfig.baseUrl}/$cleanEndpoint';
    } else {
      // Add the API version
      return '${EnvironmentConfig.fullApiUrl}$endpoint';
    }
  }

  // Generic GET request
  Future<core.ApiResponse<T>> get<T>(
      String endpoint, {
        Map<String, String>? queryParameters,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      final uri = Uri.parse(_buildUrl(endpoint));
      final finalUri = queryParameters != null
          ? uri.replace(queryParameters: queryParameters)
          : uri;

      final headers = await _getHeaders();
      final response = await _client
          .get(finalUri, headers: headers)
          .timeout(Duration(seconds: ApiConstants.connectionTimeout));

      print('📡 BaseApiService GET: ${finalUri.toString()}');
      print('📡 Status: ${response.statusCode}');

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('❌ BaseApiService GET error: $e');
      return ErrorHandler.handleError<T>(e);
    }
  }

  // Generic POST request
  Future<core.ApiResponse<T>> post<T>(
      String endpoint, {
        Map<String, dynamic>? body,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      final uri = Uri.parse(_buildUrl(endpoint));
      final headers = await _getHeaders();

      print('📡 BaseApiService POST: ${uri.toString()}');
      print('📡 Body: $body');

      final response = await _client
          .post(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      )
          .timeout(Duration(seconds: ApiConstants.connectionTimeout));

      print('📡 Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('❌ BaseApiService POST error: $e');
      return ErrorHandler.handleError<T>(e);
    }
  }

  // Generic PUT request
  Future<core.ApiResponse<T>> put<T>(
      String endpoint, {
        Map<String, dynamic>? body,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      final uri = Uri.parse(_buildUrl(endpoint));
      final headers = await _getHeaders();

      final response = await _client
          .put(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      )
          .timeout(Duration(seconds: ApiConstants.connectionTimeout));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ErrorHandler.handleError<T>(e);
    }
  }

  // Generic DELETE request
  Future<core.ApiResponse<T>> delete<T>(
      String endpoint, {
        T Function(dynamic)? fromJson,
      }) async {
    try {
      final uri = Uri.parse(_buildUrl(endpoint));
      final headers = await _getHeaders();

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(Duration(seconds: ApiConstants.connectionTimeout));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ErrorHandler.handleError<T>(e);
    }
  }

  // Handle HTTP response
  core.ApiResponse<T> _handleResponse<T>(
      http.Response response,
      T Function(dynamic)? fromJson,
      ) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          // Empty response for DELETE or other operations
          return core.ApiResponse.success(null as T);
        }

        if (fromJson != null) {
          try {
            final data = json.decode(response.body);
            return core.ApiResponse.success(fromJson(data));
          } catch (e) {
            print('❌ JSON parsing error: $e');
            print('❌ Response body: ${response.body}');
            return core.ApiResponse.error('Failed to parse response: ${e.toString()}');
          }
        } else {
          return core.ApiResponse.success(response.body as T);
        }
      } else {
        print('❌ HTTP error ${response.statusCode}: ${response.body}');
        return ErrorHandler.handleHttpError<T>(response);
      }
    } catch (e) {
      print('❌ Response handling error: $e');
      return core.ApiResponse.error('Failed to handle response: ${e.toString()}');
    }
  }

  // Dispose resources
  void dispose() {
    _client.close();
  }
}
