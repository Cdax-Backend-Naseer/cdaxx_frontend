// HTTP Client Service
// Handles all HTTP requests with proper error handling and interceptors
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/environment_config.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();
  
  late http.Client _client;
  String? _authToken;
  
  // Initialize HTTP client
  void initialize() {
    _client = http.Client();
  }
  
  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }
  
  // Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }
  
  // Get base headers
  Map<String, String> _getBaseHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }
  
  // Get full URL
  String _getFullUrl(String endpoint) {
    final fullUrl = '${EnvironmentConfig.fullApiUrl}$endpoint';
    print('🌐 Constructing URL:');
    print('🌐   Base URL: ${EnvironmentConfig.baseUrl}');
    print('🌐   API Version: ${EnvironmentConfig.apiVersion}');
    print('🌐   Endpoint: $endpoint');
    print('🌐   Full URL: $fullUrl');
    return fullUrl;
  }
  
  // Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic) fromJson,
  ) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = json.decode(response.body);
        return ApiResponse.success(fromJson(data));
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Request failed';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response', response.statusCode);
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
  
  // GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(dynamic) fromJson, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));
      final finalUri = queryParams != null
          ? uri.replace(queryParameters: queryParams)
          : uri;
      
      final response = await _client
          .get(finalUri, headers: _getBaseHeaders())
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));
      
      return _handleResponse(response, fromJson);
    } catch (error) {
      return _handleError(error);
    }
  }
  
  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    T Function(dynamic) fromJson, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));
      final response = await _client
          .post(
            uri,
            headers: _getBaseHeaders(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));
      
      return _handleResponse(response, fromJson);
    } catch (error) {
      return _handleError(error);
    }
  }
  
  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint,
    T Function(dynamic) fromJson, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));
      final response = await _client
          .put(
            uri,
            headers: _getBaseHeaders(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));
      
      return _handleResponse(response, fromJson);
    } catch (error) {
      return _handleError(error);
    }
  }
  
  // PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint,
    T Function(dynamic) fromJson, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));
      final response = await _client
          .patch(
            uri,
            headers: _getBaseHeaders(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));
      
      return _handleResponse(response, fromJson);
    } catch (error) {
      return _handleError(error);
    }
  }
  
  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final uri = Uri.parse(_getFullUrl(endpoint));
      final response = await _client
          .delete(uri, headers: _getBaseHeaders())
          .timeout(Duration(milliseconds: AppConfig.connectionTimeout));
      
      return _handleResponse(response, fromJson);
    } catch (error) {
      return _handleError(error);
    }
  }
  
  // Upload file
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
      request.headers.addAll(_getBaseHeaders());
      
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
  
  // Dispose client
  void dispose() {
    _client.close();
  }
}

/// API Response wrapper - Robust Version
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? _error;
  final int? statusCode;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    String? error,
    this.statusCode,
  }) : _error = error;

  factory ApiResponse.success(T data) {
    return ApiResponse._(isSuccess: true, data: data);
  }

  factory ApiResponse.error(String error, [int? statusCode]) {
    return ApiResponse._(isSuccess: false, error: error, statusCode: statusCode);
  }

  // Always returns a non-null string
  String get errorMessage => _error ?? 'Unknown error';

  // For backward compatibility
  String? get error => _error;
}