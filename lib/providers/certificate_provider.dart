// providers/certificate_provider.dart
import 'package:flutter/material.dart';
import '../services/certificate_service.dart';
import '../models/certificate/certificate_model.dart';
import 'dart:typed_data';


class CertificateProvider with ChangeNotifier {
  final CertificateService _certificateService;

  List<CertificateModel> _certificates = [];
  bool _isLoading = false;
  String? _error;
  Map<String, CertificateModel> _certificateCache = {};

  List<CertificateModel> get certificates => _certificates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CertificateProvider({required CertificateService certificateService})
      : _certificateService = certificateService;

  // Initialize with user data
  void initialize(String userId, String authToken) {
    _certificateService.setUserId(userId);
    _certificateService.setAuthToken(authToken);
  }

  // Load user certificates
  Future<void> loadCertificates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _certificateService.getUserCertificates();

    response.when(
      success: (data) {
        _certificates = data;
        // Update cache
        for (var cert in _certificates) {
          _certificateCache[cert.id] = cert;
        }
      },
      error: (errorMessage) {
        _error = errorMessage;
        _certificates = [];
      },
      loading: () {
        // Loading state already handled
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Get certificate by ID
  Future<CertificateModel?> getCertificateById(String certificateId) async {
    // Check cache first
    if (_certificateCache.containsKey(certificateId)) {
      return _certificateCache[certificateId];
    }

    final response = await _certificateService.getCertificateById(certificateId);

    return response.when(
      success: (certificate) {
        _certificateCache[certificateId] = certificate;
        // Add to list if not already there
        if (!_certificates.any((c) => c.id == certificateId)) {
          _certificates.add(certificate);
          notifyListeners();
        }
        return certificate;
      },
      error: (_) => null,
      loading: () => null,
    );
  }

  // Check course completion
  Future<CertificateModel?> checkCourseCompletion(String courseId) async {
    final response = await _certificateService.checkCourseCompletion(courseId);

    return response.when(
      success: (certificate) => certificate,
      error: (_) => null,
      loading: () => null,
    );
  }

  // Generate certificate for course
  Future<CertificateModel> generateCertificateForCourse({
    required String courseId,
    required double grade,
    required int totalModules,
    required int completedModules,
  }) async {
    final response = await _certificateService.generateCertificate(
      courseId: courseId,
      grade: grade,
      totalModules: totalModules,
      completedModules: completedModules,
    );

    return response.when(
      success: (certificate) {
        // Add to local list and cache
        _certificates.insert(0, certificate);
        _certificateCache[certificate.id] = certificate;
        notifyListeners();
        return certificate;
      },
      error: (errorMessage) {
        throw Exception(errorMessage);
      },
      loading: () {
        throw Exception('Generation in progress');
      },
    );
  }

  // Download certificate PDF
  Future<Uint8List> downloadCertificatePdf(String certificateId) async {
    final response = await _certificateService.downloadCertificatePdf(certificateId);

    return response.when(
      success: (pdfBytes) => pdfBytes,
      error: (errorMessage) {
        throw Exception(errorMessage);
      },
      loading: () {
        throw Exception('Download in progress');
      },
    );
  }

  // Verify certificate
  Future<Map<String, dynamic>> verifyCertificate(String verificationCode) async {
    final response = await _certificateService.verifyCertificate(verificationCode);

    return response.when(
      success: (verificationData) => verificationData,
      error: (errorMessage) {
        throw Exception(errorMessage);
      },
      loading: () {
        throw Exception('Verification in progress');
      },
    );
  }

  // Share certificate
  Future<void> shareCertificate({
    required String certificateId,
    required String platform,
  }) async {
    final response = await _certificateService.shareCertificate(
      certificateId: certificateId,
      platform: platform,
    );

    return response.when(
      success: (_) {},
      error: (errorMessage) {
        throw Exception(errorMessage);
      },
      loading: () {
        throw Exception('Sharing in progress');
      },
    );
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}