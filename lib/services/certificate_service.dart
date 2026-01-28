// services/certificate_service.dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Adjust imports based on your project structure
import '../config/backend_config.dart'; // or '../config/api_constants.dart'
import '../core/api_response.dart';
import '../models/certificate/certificate_model.dart';
import '../models/certificate/certificate_data.dart';

class CertificateService {
  final String baseUrl;
  final http.Client _httpClient;
  String? _authToken;
  String? _userId;

  CertificateService({
    http.Client? httpClient,
    String? customBaseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        baseUrl = customBaseUrl ?? BackendConfig.baseUrl;

  // Set authentication token (call this after login)
  void setAuthToken(String token) {
    _authToken = token;
  }

  void setUserId(String userId) {
    _userId = userId;
  }

  // Helper method to get headers
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Get user certificates
  Future<ApiResponse<List<CertificateModel>>> getUserCertificates() async {
    if (_userId == null) {
      return ApiResponse.error('User ID not set');
    }

    try {
      final url = Uri.parse('$baseUrl/api/certificates/user/$_userId');
      final response = await _httpClient.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'] as List<dynamic>;
          final certificates = data
              .map((certJson) => CertificateModel.fromJson(certJson))
              .toList();
          return ApiResponse.success(certificates);
        } else {
          return ApiResponse.error(
            jsonResponse['message'] ?? 'Failed to load certificates',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error loading certificates: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get certificate by ID
  Future<ApiResponse<CertificateModel>> getCertificateById(
      String certificateId,
      ) async {
    try {
      final url = Uri.parse('$baseUrl/api/certificates/$certificateId');
      final response = await _httpClient.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final certificate = CertificateModel.fromJson(jsonResponse['data']);
          return ApiResponse.success(certificate);
        } else {
          return ApiResponse.error(
            jsonResponse['message'] ?? 'Certificate not found',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error getting certificate: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Check course completion
  Future<ApiResponse<CertificateModel?>> checkCourseCompletion(
      String courseId,
      ) async {
    if (_userId == null) {
      return ApiResponse.error('User ID not set');
    }

    try {
      final url = Uri.parse(
        '$baseUrl/api/certificates/course/$courseId/completion-status?userId=$_userId',
      );
      final response = await _httpClient.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          if (jsonResponse['data'] != null) {
            final certificate = CertificateModel.fromJson(jsonResponse['data']);
            return ApiResponse.success(certificate);
          } else {
            return ApiResponse.success(null);
          }
        } else {
          return ApiResponse.error(
            jsonResponse['message'] ?? 'Failed to check completion',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error checking course completion: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Generate certificate
  Future<ApiResponse<CertificateModel>> generateCertificate({
    required String courseId,
    required double grade,
    required int totalModules,
    required int completedModules,
  }) async {
    if (_userId == null) {
      return ApiResponse.error('User ID not set');
    }

    try {
      final url = Uri.parse('$baseUrl/api/certificates/generate');
      final body = jsonEncode({
        'userId': _userId,
        'courseId': courseId,
        'grade': grade,
        'totalModules': totalModules,
        'completedModules': completedModules,
        'completionDate': DateTime.now().toIso8601String(),
      });

      final response = await _httpClient.post(
        url,
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final certificate = CertificateModel.fromJson(jsonResponse['data']);
          return ApiResponse.success(certificate);
        } else {
          return ApiResponse.error(
            jsonResponse['message'] ?? 'Failed to generate certificate',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error generating certificate: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Download certificate PDF
  Future<ApiResponse<Uint8List>> downloadCertificatePdf(
      String certificateId,
      ) async {
    try {
      final url = Uri.parse('$baseUrl/api/certificates/$certificateId/download-pdf');

      // Create a custom request to get bytes
      final request = http.Request('GET', url);
      request.headers.addAll(_getHeaders());

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return ApiResponse.success(response.bodyBytes);
      } else {
        return ApiResponse.error(
          'Download failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error downloading certificate: $e');
      return ApiResponse.error('Download failed: ${e.toString()}');
    }
  }

  // Verify certificate (public endpoint)
  Future<ApiResponse<Map<String, dynamic>>> verifyCertificate(
      String verificationCode,
      ) async {
    try {
      final url = Uri.parse('$baseUrl/api/certificates/verify/$verificationCode');
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return ApiResponse.success(jsonResponse['data']);
        } else {
          return ApiResponse.error(
            jsonResponse['message'] ?? 'Verification failed',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error verifying certificate: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Share certificate
  Future<ApiResponse<void>> shareCertificate({
    required String certificateId,
    required String platform,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/certificates/$certificateId/share');
      final body = jsonEncode({
        'platform': platform,
        'sharedAt': DateTime.now().toIso8601String(),
      });

      final response = await _httpClient.post(
        url,
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return ApiResponse.success(null);
        } else {
          return ApiResponse.error(
            jsonResponse['message'] ?? 'Failed to share certificate',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error sharing certificate: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get certificate analytics
  Future<ApiResponse<Map<String, dynamic>>> getCertificateAnalytics() async {
    if (_userId == null) {
      return ApiResponse.error('User ID not set');
    }

    try {
      final url = Uri.parse('$baseUrl/api/certificates/user/$_userId/analytics');
      final response = await _httpClient.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return ApiResponse.success(jsonResponse['data']);
        } else {
          return ApiResponse.error(
            jsonResponse['message'] ?? 'Failed to get analytics',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error getting analytics: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }
}