// Dashboard Service
// Handles dashboard-related API calls for both public and authenticated users
// Uses backend course service for compatibility with Spring Boot backend

import '../models/dashboard/dashboard_public_model.dart';

import '../models/backend/course_model.dart';
import '../models/dashboard/dashboard_stats_model.dart';
import '../services/http_service.dart';
import '../services/backend_course_service.dart';
import '../constants/api_endpoints.dart';

class DashboardService {
  final HttpService _httpService = HttpService();
  final BackendCourseService _courseService = BackendCourseService();

  /// Fetch new user dashboard data for authenticated users with no enrollment history
  /// Note: This method is deprecated - use getUserDashboard instead
  /// The conditional dashboard system now uses a single endpoint
  @deprecated
  Future<ApiResponse<NewUserDashboardModel>> getNewUserDashboard() async {
    print('\n⚠️ getNewUserDashboard is deprecated - use getUserDashboard instead');
    print('📊 The conditional dashboard system uses a single endpoint for all users');
    return ApiResponse.error('Method deprecated - use getUserDashboard instead');
  }

  /// Fetch user dashboard data using backend course service
  /// This replaces the old dashboard endpoint with direct course data from backend
  /// Endpoint: GET /api/courses?userId={userId}
  Future<ApiResponse<List<CourseModel>>> getUserDashboard(int userId) async {
    print('\n📊 Fetching user dashboard data using backend courses...');
    print('   ├─ User ID: $userId');
    print('   └─ Using Backend Course Service');

    try {
      // Get courses with user progress from backend
      final coursesResponse = await _courseService.getCoursesForUser(userId);

      if (coursesResponse.isSuccess && coursesResponse.data != null) {
        final courses = coursesResponse.data!;

        print('   ✅ Dashboard loaded with ${courses.length} courses');
        print('   ├─ Subscribed courses: ${courses.where((c) => c.isSubscribed).length}');
        print('   └─ Available courses: ${courses.where((c) => !c.isSubscribed).length}');

        return ApiResponse.success(courses);
      }

      return ApiResponse.error('Failed to load dashboard courses');
    } catch (e) {
      print('❌ Error fetching user dashboard: $e');
      return ApiResponse.error('Failed to load dashboard: ${e.toString()}');
    }
  }


// In DashboardService class
  Future<ApiResponse<DashboardStatsModel>> getDashboardStats(
      int userId, {
        int? selectedCourseId, // Add this parameter
      }) async {
    print('\n📊 Fetching dashboard statistics...');
    print('   ├─ User ID: $userId');
    if (selectedCourseId != null) {
      print('   ├─ Selected Course ID: $selectedCourseId');
    }

    try {
      // Build query parameters
      Map<String, String> queryParams = {'userId': userId.toString()};
      if (selectedCourseId != null) {
        queryParams['courseId'] = selectedCourseId.toString();
      }

      final endpoint = '/dashboard/stats?${Uri(queryParameters: queryParams).query}';
      print('   ├─ Endpoint: $endpoint');

      return await _httpService.get<DashboardStatsModel>(
        endpoint,
            (data) => DashboardStatsModel.fromJson(data),
      );
    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      return ApiResponse.error('Failed to load stats: $e');
    }
  }


  /// Get user courses data (alias for getUserDashboard for compatibility)
  Future<ApiResponse<List<CourseModel>>> getUserCourses(int userId) async {
    return await getUserDashboard(userId);
  }

  /// Record user activity for analytics
  /// Endpoint: POST /api/users/{userId}/activity
  Future<ApiResponse<Map<String, dynamic>>> recordActivity({
    required String userId,
    required String type,
    String? courseId,
    String? moduleId,
    String? videoId,
    String? assessmentId,
    Map<String, dynamic>? metadata,
  }) async {
    print('\n📝 Recording user activity...');
    print('   ├─ User ID: $userId');
    print('   ├─ Type: $type');
    print('   └─ Course ID: ${courseId ?? 'N/A'}');

    try {
      final endpoint = ApiEndpoints.userActivity.replaceAll('{userId}', userId);
      return await _httpService.post<Map<String, dynamic>>(
        endpoint,
        (data) => Map<String, dynamic>.from(data),
        body: {
          'type': type,
          'courseId': courseId,
          'moduleId': moduleId,
          'videoId': videoId,
          'assessmentId': assessmentId,
          'metadata': metadata,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('❌ Error recording activity: $e');
      return ApiResponse.error('Failed to record activity: ${e.toString()}');
    }
  }
}