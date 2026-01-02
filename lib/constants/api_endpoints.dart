/// API Endpoints Constants
/// All API endpoint paths organized by feature
class ApiEndpoints {
  // Base paths
  static const String auth = '/auth';
  static const String users = '/users';
  static const String courses = '/courses';
  static const String assessments = '/assessments';
  static const String jobs = '/jobs';
  static const String payments = '/payments';
  static const String notifications = '/notifications';
  static const String analytics = '/analytics';
  
  // Authentication endpoints
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
  
  // User endpoints
  static const String userProfile = '$users/profile';
  static const String updateProfile = '$users/profile';
  static const String userCourses = '/api/courses/user';
  static const String userAssessments = '$users/assessments';
  static const String userJobs = '$users/jobs';
  static const String userProgress = '$users/progress';
  static const String userAchievements = '$users/achievements';

  // Course endpoints
  static const String allCourses = '/courses';
  static const String courseDetails = '$courses/{id}';
  static const String courseContent = '$courses/{id}/content';
  static const String courseEnroll = '$courses/{id}/enroll';
  static const String courseProgress = '$courses/{id}/progress';
  static const String courseReviews = '$courses/{id}/reviews';
  static const String courseCategories = '$courses/categories';
  static const String featuredCourses = '$courses/featured';
  static const String popularCourses = '$courses/popular';
  
  // Assessment endpoints
  static const String allAssessments = assessments;
  static const String assessmentDetails = '$assessments/{id}';
  static const String startAssessment = '$assessments/{id}/start';
  static const String submitAssessment = '$assessments/{id}/submit';
  static const String assessmentResults = '$assessments/{id}/results';
  static const String assessmentHistory = '$assessments/history';
  static const String practiceTests = '$assessments/practice';
  
  // Job endpoints
  static const String allJobs = jobs;
  static const String jobDetails = '$jobs/{id}';
  static const String applyJob = '$jobs/{id}/apply';
  static const String jobApplications = '$jobs/applications';
  static const String jobCategories = '$jobs/categories';
  static const String recommendedJobs = '$jobs/recommended';
  static const String savedJobs = '$jobs/saved';
  
  // Payment endpoints
  static const String createPayment = '$payments/create';
  static const String verifyPayment = '$payments/verify';
  static const String paymentHistory = '$payments/history';
  static const String paymentMethods = '$payments/methods';
  static const String subscriptions = '$payments/subscriptions';
  static const String invoices = '$payments/invoices';
  
  // Notification endpoints
  static const String allNotifications = notifications;
  static const String markAsRead = '$notifications/{id}/read';
  static const String markAllAsRead = '$notifications/mark-all-read';
  static const String notificationSettings = '$notifications/settings';
  
  // Dashboard endpoints
  static const String dashboardPublic = '/dashboard/public';
  static const String dashboardUser = '$users/{userId}/dashboard';
  static const String userActivity = '$users/{userId}/activity';
  // static const String dashboardCourses = '/dashboard/courses';
  
  // Analytics endpoints
  static const String userAnalytics = '$analytics/user';
  static const String courseAnalytics = '$analytics/courses';
  static const String assessmentAnalytics = '$analytics/assessments';
  static const String dashboardStats = '$analytics/dashboard';

  // Utility method to replace path parameters
  static String replacePathParams(String endpoint, Map<String, String> params) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}