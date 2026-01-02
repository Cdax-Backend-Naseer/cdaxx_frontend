// Backend API configuration for Spring Boot integration
// Update the baseUrl when you have your Spring Boot backend ready

import 'package:flutter/foundation.dart';
import 'environment_config.dart';
class BackendConfig {
  // TODO: Replace with your actual Spring Boot backend URL
  // Example: static const String baseUrl = 'http://localhost:8080';
  // Example: static const String baseUrl = 'https://your-domain.com';
  // static const String baseUrl = 'https://cdax-backend-hosting-2.onrender.com'; // Change this to your backend URL
  // static const String baseUrl = 'https://cdax-assessment-hosting.onrender.com'; // Change this to your backend URL
  // static const String baseUrl = 'https://cdax-assessment-hosting-f284.onrender.com'; // Update with your Spring Boot API URL
  static final String baseUrl = EnvironmentConfig.baseUrl;
  // API timeout configuration
  static const Duration requestTimeout = Duration(seconds: 15);
  
  // Feature flags
  static const bool useRemoteRepository = true; // Set to true when backend is ready
  static const bool enableDebugLogs = true; // Set to false in production
  
  // API endpoints
  static const String coursesEndpoint = '/api/courses';
  static const String enrollEndpoint = '/api/courses/{courseId}/enroll';
  static const String unenrollEndpoint = '/api/courses/{courseId}/unenroll';
  static const String purchaseEndpoint = '/api/courses/{courseId}/purchase';
  
  // Authentication (TODO: Implement when auth is ready)
  static String? authToken;
  
  // Helper method to check if backend should be used
  static bool get shouldUseBackend => useRemoteRepository && baseUrl.isNotEmpty;
  
  // Helper method to log debug messages
  static void debugLog(String message) {
    if (enableDebugLogs) {
      if (kDebugMode) {
        debugPrint('🔧 BackendConfig: $message');
      }
    }
  }
  
  // Method to validate configuration
  static bool validateConfig() {
    if (!shouldUseBackend) {
      debugLog('Backend usage is disabled, using mock data');
      return false;
    }
    
    if (baseUrl.isEmpty) {
      debugLog('Backend URL is not configured');
      return false;
    }
    
    if (baseUrl == 'http://localhost:8080') {
      debugLog('Warning: Using default localhost URL. Update for production!');
    }
    
    debugLog('Backend configuration is valid: $baseUrl');
    return true;
  }
}