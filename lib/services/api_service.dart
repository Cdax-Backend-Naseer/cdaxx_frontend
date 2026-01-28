// API Service
// Main API service that coordinates all API operations
import '../core/base_api_service.dart';
import '../core/api_response.dart';
import '../models/user_model.dart';
import '../models/backend/course_model.dart';
import '../models/performance_model.dart';
import '../config/api_constants.dart';

class ApiService extends BaseApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // User operations - FIXED VERSION matching your ApiResponse class
  Future<ApiResponse<UserModel>> getCurrentUser() async {
    final response = await get<Map<String, dynamic>>(
      '/auth/profile/me',  // ✅ Correct endpoint
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      // Extract user from nested response
      final userJson = response.data!['user'];
      if (userJson != null) {
        return ApiResponse<UserModel>.success(
          UserModel.fromJson(userJson),
          message: response.message,
        );
      }
    }

    return ApiResponse<UserModel>.error(
      response.error ?? 'Failed to load profile',
    );
  }

  Future<ApiResponse<UserModel>> updateProfile(Map<String, dynamic> data) async {
    return await put<Map<String, dynamic>>(
      '/auth/profile/update',
      body: data,
      fromJson: (json) => json as Map<String, dynamic>,
    ).then((response) {
      if (response.isSuccess && response.data != null) {
        final userJson = response.data!['user'];
        if (userJson != null) {
          return ApiResponse<UserModel>.success(
            UserModel.fromJson(userJson),
            message: response.message,
          );
        }
      }
      return ApiResponse<UserModel>.error(
        response.error ?? 'Failed to update profile',
      );
    });
  }

  // Course operations
  Future<ApiResponse<List<CourseModel>>> getCourses({
    int page = 0,
    int size = 20,
    String? search,
    String? category,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (search != null) queryParams['search'] = search;
    if (category != null) queryParams['category'] = category;

    return await get<List<CourseModel>>(
      ApiConstants.courses,
      queryParameters: queryParams,
      fromJson: (json) => (json['content'] as List)
          .map((e) => CourseModel.fromJson(e))
          .toList(),
    );
  }

  Future<ApiResponse<CourseModel>> getCourseById(String courseId) async {
    final endpoint = ApiConstants.replacePathParams(
      ApiConstants.courseDetails,
      {'id': courseId},
    );

    return await get<CourseModel>(
      endpoint,
      fromJson: (json) => CourseModel.fromJson(json),
    );
  }

  // Performance operations
  Future<ApiResponse<List<PerformanceModel>>> getPerformanceData({
    String? courseId,
    String? userId,
  }) async {
    final queryParams = <String, String>{};
    if (courseId != null) queryParams['courseId'] = courseId;
    if (userId != null) queryParams['userId'] = userId;

    return await get<List<PerformanceModel>>(
      ApiConstants.performance,
      queryParameters: queryParams,
      fromJson: (json) => (json as List)
          .map((e) => PerformanceModel.fromJson(e))
          .toList(),
    );
  }

  // Streak operations - FIXED
  Future<ApiResponse<Map<String, dynamic>>> getCourseStreak(String courseId, String userId) async {
    return await get<Map<String, dynamic>>(
      '/streak/course/$courseId?userId=$userId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getStreakOverview(String userId) async {
    return await get<Map<String, dynamic>>(
      '/streak/overview?userId=$userId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // ✅ FIXED: Use correct endpoint
  Future<ApiResponse<Map<String, dynamic>>> getDayDetails(String userId, String courseId, String date) async {
    return await get<Map<String, dynamic>>(
      '/streak/day/$courseId?userId=$userId&date=$date',  // ✅ Fixed pattern
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateVideoProgress(Map<String, dynamic> data) async {
    return await post<Map<String, dynamic>>(
      '/video/progress/update',
      body: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}