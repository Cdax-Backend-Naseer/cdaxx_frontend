/// API Constants
/// All API-related constants and endpoints
import 'environment_config.dart';
class ApiConstants {
  // Base URLs
  // static const String baseUrl = 'https://cdax-backend-hosting-2.onrender.com'; // Update with your Spring Boot API URL
  // static const String baseUrl = 'https://cdax-assessment-hosting.onrender.com'; // Update with your Spring Boot API URL
  // static const String baseUrl = 'https://cdax-assessment-hosting-f284.onrender.com'; // Update with your Spring Boot API URL
  static final String baseUrl = EnvironmentConfig.baseUrl;
  static const String apiVersion = '/api/v1';
  static final String fullApiUrl = '$baseUrl$apiVersion';

  // Authentication Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyOtp = '/auth/verify-otp';
  
  // User Endpoints
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String changePassword = '/users/change-password';
  
  // Course Endpoints
  static const String courses = '/courses';
  static const String courseDetails = '/courses/{id}';
  static const String enrollCourse = '/courses/{id}/enroll';
  static const String courseModules = '/courses/{id}/modules';
  
  // Module Endpoints
  static const String modules = '/modules';
  static const String moduleDetails = '/modules/{id}';
  static const String moduleProgress = '/modules/{id}/progress';
  
  // Performance Endpoints
  static const String performance = '/performance';
  static const String performanceOverview = '/performance/overview';
  static const String performanceDetails = '/performance/{id}';
  
  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/{id}/read';
  
  // HTTP Status Codes
  static const int success = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;
  
  // Request Timeouts
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
  
  // Helper method to replace path parameters
  static String replacePathParams(String endpoint, Map<String, String> params) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}