/// API Endpoints Constants - Complete Fixed Version
 import '/config/environment_config.dart'; // Add this import
/// All API endpoint paths organized by feature
class ApiEndpoints {
  // Base paths
  static const String api = '/api'; // Add API base if needed
  static const String auth = '/auth';
  static const String users = '/users';
  static const String courses = '/courses';
  static const String modules = '/modules';
  static const String assessments = '/assessments';
  static const String jobs = '/jobs';
  static const String payments = '/payments';
  static const String notifications = '/notifications';
  static const String analytics = '/analytics';
  static const String profile = '/profile';

  // ==================== AUTHENTICATION ENDPOINTS ====================

  // Legacy authentication endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  static const String verifyEmail = '$auth/verify-email';
  static const String changePassword = '$auth/change-password';
  static const String firstName = '$auth/firstName';
  static const String getUserByEmail = '$auth/getUserByEmail';

  // JWT authentication endpoints - Fixed to include /api if needed
  static const String jwtLogin = '$auth/jwt/login';
  static const String jwtRegister = '$auth/jwt/register';
  static const String jwtMe = '$auth/jwt/me';
  static const String jwtValidate = '$auth/jwt/validate';
  static const String jwtRefresh = '$auth/jwt/refresh';

  // ==================== USER & PROFILE ENDPOINTS ====================

  // Profile endpoints - FIXED (consolidated naming)
  static const String userProfile = '$auth/profile/me'; // For fetching profile
  static const String updateProfile = '$auth/profile/update'; // For updating profile

  // User endpoints
  static const String userCourses = '$users/courses';
  static const String userAssessments = '$users/assessments';
  static const String userJobs = '$users/jobs';
  static const String userProgress = '$users/progress';
  static const String userAchievements = '$users/achievements';

  // ==================== COURSE ENDPOINTS ====================

  static const String allCourses = '$courses';
  static const String courseDetails = '$courses/{id}';
  static const String courseContent = '$courses/{id}/content';
  static const String courseEnroll = '$courses/{id}/enroll';
  static const String courseProgress = '$courses/{id}/progress';
  static const String courseReviews = '$courses/{id}/reviews';
  static const String courseCategories = '$courses/categories';
  static const String featuredCourses = '$courses/featured';
  static const String popularCourses = '$courses/popular';

  // Module endpoints (if separate)
  static const String moduleProgress = '$modules/{moduleId}/progress';
  static const String moduleComplete = '$modules/{moduleId}/complete';
  static const String courseModules = '$courses/{courseId}/modules';

  // ==================== ASSESSMENT ENDPOINTS ====================

  static const String allAssessments = assessments;
  static const String assessmentDetails = '$assessments/{id}';
  static const String startAssessment = '$assessments/{id}/start';
  static const String submitAssessment = '$assessments/{id}/submit';
  static const String assessmentResults = '$assessments/{id}/results';
  static const String assessmentHistory = '$assessments/history';
  static const String practiceTests = '$assessments/practice';

  // ==================== JOB ENDPOINTS ====================

  static const String allJobs = jobs;
  static const String jobDetails = '$jobs/{id}';
  static const String applyJob = '$jobs/{id}/apply';
  static const String jobApplications = '$jobs/applications';
  static const String jobCategories = '$jobs/categories';
  static const String recommendedJobs = '$jobs/recommended';
  static const String savedJobs = '$jobs/saved';

  // ==================== PAYMENT ENDPOINTS ====================

  static const String createPayment = '$payments/create';
  static const String verifyPayment = '$payments/verify';
  static const String paymentHistory = '$payments/history';
  static const String paymentMethods = '$payments/methods';
  static const String subscriptions = '$payments/subscriptions';
  static const String invoices = '$payments/invoices';

  // ==================== NOTIFICATION ENDPOINTS ====================

  static const String allNotifications = notifications;
  static const String markAsRead = '$notifications/{id}/read';
  static const String markAllAsRead = '$notifications/mark-all-read';
  static const String notificationSettings = '$notifications/settings';

  // ==================== DASHBOARD ENDPOINTS ====================

  static const String dashboardPublic = '/dashboard/public';
  static const String dashboardUser = '$users/{userId}/dashboard';
  static const String userActivity = '$users/{userId}/activity';
  static const String dashboardStats = '/dashboard/stats'; // Add if needed

  // ==================== ANALYTICS ENDPOINTS ====================

  static const String userAnalytics = '$analytics/user';
  static const String courseAnalytics = '$analytics/courses';
  static const String assessmentAnalytics = '$analytics/assessments';
  static const String platformAnalytics = '$analytics/dashboard';

  // ==================== FAVORITE & CART ENDPOINTS ====================

  static const String userFavorites = '$users/favorites';
  static const String addToFavorites = '$users/favorites/add';
  static const String removeFromFavorites = '$users/favorites/remove';

  static const String userCart = '$users/cart';
  static const String addToCart = '$users/cart/add';
  static const String removeFromCart = '$users/cart/remove';
  static const String checkoutCart = '$users/cart/checkout';

  // ==================== UTILITY METHODS ====================

  /// Replace path parameters in endpoint string
  static String replacePathParams(String endpoint, Map<String, String> params) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  /// Get endpoint with query parameters
  static String withQueryParams(String endpoint, Map<String, String> queryParams) {
    if (queryParams.isEmpty) return endpoint;

    final queryString = queryParams.entries
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
        .join('&');

    return '$endpoint?$queryString';
  }

  /// Get complete URL by combining base URL and endpoint
  /// Adjust this based on your EnvironmentConfig setup
  static String getFullUrl(String endpoint) {
    // Remove leading slash if present
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

    // Check if endpoint already contains /api
    if (cleanEndpoint.startsWith('api/')) {
      // Already has /api prefix
      return '${EnvironmentConfig.baseUrl}/$cleanEndpoint';
    } else {
      // Add /api prefix if your base URL doesn't include it
      return '${EnvironmentConfig.baseUrl}/api/$cleanEndpoint';
    }
  }

  /// Get JWT endpoints summary
  static Map<String, String> getJWTEndpoints() {
    return {
      'login': jwtLogin,
      'register': jwtRegister,
      'me': jwtMe,
      'validate': jwtValidate,
      'refresh': jwtRefresh,
    };
  }

  /// Get profile endpoints
  static Map<String, String> getProfileEndpoints() {
    return {
      'getProfile': userProfile,
      'updateProfile': updateProfile,
    };
  }

  /// Get course endpoints for a specific course
  static Map<String, String> getCourseEndpoints(String courseId) {
    return {
      'details': replacePathParams(courseDetails, {'id': courseId}),
      'content': replacePathParams(courseContent, {'id': courseId}),
      'enroll': replacePathParams(courseEnroll, {'id': courseId}),
      'progress': replacePathParams(courseProgress, {'id': courseId}),
      'reviews': replacePathParams(courseReviews, {'id': courseId}),
    };
  }

  /// Get module endpoints for a specific module
  static Map<String, String> getModuleEndpoints(String moduleId) {
    return {
      'progress': replacePathParams(moduleProgress, {'moduleId': moduleId}),
      'complete': replacePathParams(moduleComplete, {'moduleId': moduleId}),
    };
  }

  /// Debug method to print all endpoints
  static void debugEndpoints() {
    print('🔗 API ENDPOINTS DEBUG:');
    print('  AUTH:');
    print('    ├─ JWT Login: $jwtLogin');
    print('    ├─ JWT Register: $jwtRegister');
    print('    ├─ JWT Me: $jwtMe');
    print('    ├─ Login: $login');
    print('    ├─ Register: $register');
    print('    ├─ Logout: $logout');

    print('  PROFILE:');
    print('    ├─ Get Profile: $userProfile');
    print('    ├─ Update Profile: $updateProfile');

    print('  COURSES:');
    print('    ├─ All Courses: $allCourses');
    print('    ├─ Course Details: $courseDetails');
    print('    ├─ Course Modules: $courseModules');

    print('  MODULES:');
    print('    ├─ Module Progress: $moduleProgress');

    print('  FAVORITES & CART:');
    print('    ├─ User Favorites: $userFavorites');
    print('    ├─ User Cart: $userCart');
  }
}