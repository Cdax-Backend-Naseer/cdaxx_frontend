// services/http_service.dart - FIXED VERSION
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // FIXED: Use typed_data properly
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/environment_config.dart';
import 'secure_storage_service.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  late http.Client _client;
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  String? _authToken; // ADDED: Store auth token

  // Initialize HTTP client
  void initialize() {
    _client = http.Client();
  }

  // Set auth token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Get base headers with JWT token
  Future<Map<String, String>> _getBaseHeaders() async {
    print('🔍 HttpService._getBaseHeaders() called');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Get JWT token from secure storage or use stored token
    String? token = _authToken;
    if (token == null) {
      token = await _secureStorage.getJWTToken();
    }

    print('🔍 Token retrieved: ${token != null ? "EXISTS (length: ${token.length})" : "NULL"}');

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('🔍 Added Authorization header with token');
    } else {
      print('⚠️ No token found, request will be sent without Authorization header');
    }

    print('🔍 Headers to send: $headers');
    return headers;
  }

  // Get full URL - FIXED VERSION
  String _getFullUrl(String endpoint) {
    // Remove leading slash if present
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

    // Get base URL
    final baseUrl = EnvironmentConfig.baseUrl;

    // Check if base URL already ends with /api
    final bool baseUrlHasApi = baseUrl.endsWith('/api');

    // Check if endpoint already starts with api/
    final bool endpointHasApi = cleanEndpoint.startsWith('api/');

    String fullUrl;

    if (baseUrlHasApi) {
      // Base URL already has /api, don't add it again
      if (endpointHasApi) {
        // Both have /api, use endpoint as is
        fullUrl = '$baseUrl/$cleanEndpoint';
      } else {
        // Base has /api, endpoint doesn't, add endpoint directly
        fullUrl = '$baseUrl/$cleanEndpoint';
      }
    } else {
      // Base URL doesn't have /api
      if (endpointHasApi) {
        // Endpoint has /api, add to base URL
        fullUrl = '$baseUrl/$cleanEndpoint';
      } else {
        // Neither has /api, add /api prefix
        fullUrl = '$baseUrl/api/$cleanEndpoint';
      }
    }

    print('🌐 Constructing URL:');
    print('🌐   Base URL: $baseUrl');
    print('🌐   Endpoint: $cleanEndpoint');
    print('🌐   Full URL: $fullUrl');

    return fullUrl;
  }

  // Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
      http.Response response,
      T Function(dynamic) fromJson,
      ) {
    try {
      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = json.decode(response.body);
        return ApiResponse.success(fromJson(data));
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Request failed';
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      print('❌ Error parsing response: $e');
      return ApiResponse.error('Failed to parse response');
    }
  }

  // Handle download response (for binary data)
  ApiResponse<Uint8List> _handleDownloadResponse(http.Response response) {
    print('📡 Download Response Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse.success(response.bodyBytes);
    } else {
      try {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Download failed';
        return ApiResponse.error(errorMessage);
      } catch (e) {
        return ApiResponse.error('Download failed with status ${response.statusCode}');
      }
    }
  }

  // Handle HTTP exceptions
  ApiResponse<T> _handleError<T>(dynamic error) {
    if (error is SocketException) {
      return ApiResponse.error('No internet connection');
    } else if (error is HttpException) {
      return ApiResponse.error('HTTP error: ${error.message}');
    } else if (error is FormatException) {
      return ApiResponse.error('Invalid response format');
    } else {
      return ApiResponse.error('Unknown error occurred');
    }
  }

  // GET request with JWT
  Future<ApiResponse<T>> get<T>(
      String endpoint,
      T Function(dynamic) fromJson, {
        Map<String, String>? queryParams,
        Map<String, String>? additionalHeaders,
      }) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));
      final finalUri = queryParams != null
          ? uri.replace(queryParameters: queryParams)
          : uri;

      final headers = await _getBaseHeaders();
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      final response = await _client
          .get(finalUri, headers: headers)
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));

      return _handleResponse(response, fromJson);
    } catch (error) {
      return _handleError(error);
    }
  }

  // POST request with JWT
  Future<ApiResponse<T>> post<T>(
      String endpoint,
      T Function(dynamic) fromJson, {
        Map<String, dynamic>? body,
        Map<String, String>? additionalHeaders,
      }) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));

      final headers = await _getBaseHeaders();
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      final response = await _client
          .post(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      )
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));

      return _handleResponse(response, fromJson);
    } catch (error) {
      return _handleError(error);
    }
  }

  // PUT request with JWT
  Future<ApiResponse<T>> put<T>(
      String endpoint,
      T Function(dynamic) fromJson, {
        Map<String, dynamic>? body,
        Map<String, String>? additionalHeaders,
      }) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));

      final headers = await _getBaseHeaders();
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      final response = await _client
          .put(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      )
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));

      return _handleResponse(response, fromJson);
    } catch (error) {
      return _handleError(error);
    }
  }

  // PATCH request with JWT
  Future<ApiResponse<T>> patch<T>(
      String endpoint,
      T Function(dynamic) fromJson, {
        Map<String, dynamic>? body,
        Map<String, String>? additionalHeaders,
      }) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));

      final headers = await _getBaseHeaders();
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      final response = await _client
          .patch(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      )
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));

      return _handleResponse(response, fromJson);
    } catch (error) {
      return _handleError(error);
    }
  }

  // DELETE request with JWT
  Future<ApiResponse<T>> delete<T>(
      String endpoint,
      T Function(dynamic) fromJson, {
        Map<String, String>? additionalHeaders,
      }) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));

      final headers = await _getBaseHeaders();
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));

      return _handleResponse(response, fromJson);
    } catch (error) {
      return _handleError(error);
    }
  }

  // Upload file with JWT
  Future<ApiResponse<T>> uploadFile<T>(
      String endpoint,
      T Function(dynamic) fromJson, {
        required File file,
        required String fieldName,
        Map<String, String>? fields,
      }) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = await _getBaseHeaders();
      request.headers.addAll(headers);

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        fieldName,
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send()
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, fromJson);
    } catch (error) {
      return _handleError(error);
    }
  }

  // FIXED: Download file method
  Future<ApiResponse<Uint8List>> downloadFile(String endpoint) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));

      final headers = await _getBaseHeaders();

      print('📥 Downloading file from: $uri');

      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));

      return _handleDownloadResponse(response);
    } catch (error) {
      return _handleError(error);
    }
  }

  // Check if JWT token exists
  Future<bool> hasJWTToken() async {
    final token = await _secureStorage.getJWTToken();
    return token != null && token.isNotEmpty;
  }

  // Clear JWT token
  Future<void> clearJWTToken() async {
    await _secureStorage.deleteJWTToken();
    _authToken = null;
  }

  // Dispose client
  void dispose() {
    _client.close();
  }
}

/// FIXED: ApiResponse class matching your pattern
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? metadata;

  const ApiResponse._({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
    this.metadata,
  });

  factory ApiResponse.success(
      T data, {
        String? message,
        int? statusCode,
        Map<String, dynamic>? metadata,
      }) {
    return ApiResponse._(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode ?? 200,
      metadata: metadata,
    );
  }

  factory ApiResponse.error(
      String error, {
        int? statusCode,
        Map<String, dynamic>? metadata,
      }) {
    return ApiResponse._(
      success: false,
      error: error,
      statusCode: statusCode,
      metadata: metadata,
    );
  }

  bool get isSuccess => success && error == null;

  String get errorMessage => error ?? 'Unknown error';
}