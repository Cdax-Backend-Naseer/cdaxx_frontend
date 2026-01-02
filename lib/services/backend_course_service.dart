/// Backend Course Service - Fixed Version
import 'dart:convert';
import '../models/backend/course_model.dart';
import '../services/http_service.dart';

class BackendCourseService {
  final HttpService _httpService = HttpService();

  /// Get all courses for a user with their progress/unlock status
  /// Endpoint: GET /api/courses?userId={userId}
  /// Returns: {"data": [CourseModel...]}
  Future<ApiResponse<List<CourseModel>>> getCoursesForUser(int userId) async {
    // FIX: Remove /api prefix since it's already in base URL
    final endpoint = '/courses?userId=$userId';  // Changed from '/api/courses'

    print('\n📚 ================================');
    print('📚 Fetching courses for user from backend...');
    print('📚 User ID: $userId');
    print('📚 Endpoint: $endpoint');  // Updated logging
    print('📚 ================================\n');

    try {
      print('🔍 Step 1: Making HTTP request to: $endpoint');
      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,  // Use the fixed endpoint
            (data) => data,
      );

      print('\n🔍 Step 2: HTTP Response Received');
      print('🔍 Response isSuccess: ${response.isSuccess}');

      // FIX: Use response.error instead of response.errorMessage
      final errorMsg = response.error ?? response.errorMessage ?? 'Unknown error';
      print('🔍 Response error: $errorMsg');
      print('🔍 Response data type: ${response.data?.runtimeType}');

      if (!response.isSuccess) {
        print('❌ HTTP request failed: $errorMsg');
        // FIX: Use the correct error field
        return ApiResponse.error(errorMsg);
      }

      if (response.data == null) {
        print('❌ Response data is null');
        return ApiResponse.error('No data received from server');
      }

      // Print the complete response for debugging
      print('\n🔍 Step 3: Full API Response JSON:');
      print('${'═' * 60}');
      try {
        final prettyJson = JsonEncoder.withIndent('  ').convert(response.data);
        print(prettyJson);
      } catch (e) {
        print(response.data.toString());
      }
      print('${'═' * 60}\n');

      // Backend returns {"data": [...]}
      final coursesData = response.data!['data'];
      print('🔍 Step 4: Extracting courses data');
      print('🔍 coursesData type: ${coursesData.runtimeType}');
      print('🔍 coursesData value: $coursesData');

      if (coursesData == null) {
        print('❌ No "data" field found in response');
        return ApiResponse.error('No courses data found');
      }

      if (coursesData is! List) {
        print('❌ Courses data is not a List, it\'s: ${coursesData.runtimeType}');
        return ApiResponse.error('Invalid courses data format: expected List');
      }

      print('\n✅ Found ${coursesData.length} courses in response\n');

      // Debug each course before parsing
      final List<CourseModel> courses = [];
      for (var i = 0; i < coursesData.length; i++) {
        print('\n🔍 Step 5: Processing Course ${i + 1}/${coursesData.length}');
        print('${'─' * 40}');

        final courseJson = coursesData[i];
        print('🔍 Raw course data type: ${courseJson.runtimeType}');

        if (courseJson is! Map<String, dynamic>) {
          print('❌ Course $i is not a Map, skipping...');
          print('❌ Actual type: ${courseJson.runtimeType}');
          continue;
        }

        // Debug individual fields
        print('\n🔍 Course $i Field Analysis:');
        print('├─ id: ${courseJson['id']} (type: ${courseJson['id']?.runtimeType})');
        print('├─ title: ${courseJson['title']}');
        print('├─ description: ${courseJson['description']}');
        print('├─ thumbnailUrl: ${courseJson['thumbnailUrl']}');
        print('├─ thumbnailImage: ${courseJson['thumbnailImage']}');
        print('├─ isSubscribed: ${courseJson['isSubscribed']}');
        print('├─ purchased: ${courseJson['purchased']}');
        print('├─ modules exists: ${courseJson.containsKey('modules')}');

        if (courseJson.containsKey('modules')) {
          final modules = courseJson['modules'];
          print('├─ modules type: ${modules.runtimeType}');
          if (modules is List) {
            print('├─ modules count: ${modules.length}');
            if (modules.isNotEmpty) {
              print('└─ First module keys: ${(modules[0] as Map).keys.toList()}');
            }
          }
        }

        print('\n🔍 Attempting to parse CourseModel...');
        try {
          final course = CourseModel.fromJson(courseJson);
          courses.add(course);
          print('✅ Successfully parsed: "${course.title}" (ID: ${course.id})');
          print('   ├─ Modules: ${course.modules.length}');
          print('   ├─ Subscribed: ${course.isSubscribed}');
          print('   └─ Thumbnail: ${course.thumbnailUrl}');
        } catch (e, stackTrace) {
          print('\n❌ ERROR parsing course $i:');
          print('❌ Error type: ${e.runtimeType}');
          print('❌ Error message: $e');
          print('\n❌ Stack trace:');
          print(stackTrace);
          print('\n❌ Problematic JSON:');
          print(JsonEncoder.withIndent('  ').convert(courseJson));
          print('${'─' * 40}');

          // Try to continue with other courses
          continue;
        }
      }

      if (courses.isEmpty) {
        print('\n❌❌❌ CRITICAL ERROR ❌❌❌');
        print('❌ No courses could be parsed successfully');
        print('❌ Please check the field names and types above');
        print('❌ The backend response structure likely doesn\'t match CourseModel');
        return ApiResponse.error('Failed to parse any courses data');
      }

      print('\n🎉 ================================');
      print('🎉 FINAL RESULT:');
      print('🎉 Successfully loaded ${courses.length} courses');
      print('🎉 ================================');

      for (final course in courses) {
        print('   📘 ${course.title}');
        print('      ├─ ID: ${course.id}');
        print('      ├─ Subscribed: ${course.isSubscribed}');
        print('      ├─ Modules: ${course.modules.length}');
        print('      ├─ Total Videos: ${course.totalVideos}');
        print('      ├─ Progress: ${course.progressPercent.toStringAsFixed(1)}%');
        print('      └─ Duration: ${course.formattedDuration}');
      }

      return ApiResponse.success(courses);

    } catch (e, stackTrace) {
      print('\n❌❌❌ UNEXPECTED ERROR ❌❌❌');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error message: $e');
      print('❌ Stack trace:');
      print(stackTrace);
      return ApiResponse.error('Unexpected error: ${e.toString()}');
    }
  }

  /// Get a single course for a user with their progress/unlock status
  /// Endpoint: GET /api/courses/{id}?userId={userId}
  /// Returns: {"data": CourseModel}
  Future<ApiResponse<CourseModel>> getCourseForUser(int userId, int courseId) async {
    // FIX: Remove /api prefix
    final endpoint = '/courses/$courseId?userId=$userId';  // Changed from '/api/courses/$courseId'

    print('\n📖 Fetching single course for user from backend...');
    print('   ├─ User ID: $userId');
    print('   ├─ Course ID: $courseId');
    print('   └─ Endpoint: $endpoint');

    try {
      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        final courseData = response.data!['data'];
        if (courseData != null) {
          final course = CourseModel.fromJson(courseData);
          print('   ✅ Loaded course: ${course.title}');
          return ApiResponse.success(course);
        }
      }

      print('   ❌ Failed to parse course data');
      return ApiResponse.error('Failed to load course');

    } catch (e) {
      print('   ❌ Error fetching course: $e');
      return ApiResponse.error('Failed to load course: ${e.toString()}');
    }
  }

  /// Purchase a course for a user
  /// Endpoint: POST /api/purchase?userId={userId}&courseId={courseId}
  /// Returns: {"message": "Purchase successful"}
  Future<ApiResponse<String>> purchaseCourse(int userId, int courseId) async {
    // FIX: Remove /api prefix
    final endpoint = '/purchase?userId=$userId&courseId=$courseId';  // Changed from '/api/purchase'

    print('\n💳 Purchasing course...');
    print('   ├─ User ID: $userId');
    print('   ├─ Course ID: $courseId');
    print('   └─ Endpoint: $endpoint');

    try {
      final response = await _httpService.post<Map<String, dynamic>>(
        endpoint,
            (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        final message = response.data!['message']?.toString() ?? 'Purchase successful';
        print('   ✅ $message');
        return ApiResponse.success(message);
      }

      print('   ❌ Failed to purchase course');
      return ApiResponse.error('Failed to purchase course');

    } catch (e) {
      print('   ❌ Error purchasing course: $e');
      return ApiResponse.error('Failed to purchase course: ${e.toString()}');
    }
  }

  /// Mark a video as completed and unlock next video
  /// Endpoint: POST /api/videos/{videoId}/complete?userId={userId}&courseId={courseId}&moduleId={moduleId}
  /// Returns: {"success": true}
  Future<ApiResponse<bool>> completeVideo({
    required int userId,
    required int videoId,
    int? courseId,
    int? moduleId,
  }) async {
    // FIX: Remove /api prefix
    String endpoint = '/videos/$videoId/complete?userId=$userId';  // Changed from '/api/videos/$videoId/complete'
    if (courseId != null) endpoint += '&courseId=$courseId';
    if (moduleId != null) endpoint += '&moduleId=$moduleId';

    print('\n✅ Marking video as completed...');
    print('   ├─ User ID: $userId');
    print('   ├─ Video ID: $videoId');
    print('   ├─ Course ID: ${courseId ?? 'N/A'}');
    print('   └─ Module ID: ${moduleId ?? 'N/A'}');
    print('   └─ Endpoint: $endpoint');

    try {
      final response = await _httpService.post<Map<String, dynamic>>(
        endpoint,
            (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        final success = response.data!['success'] == true;
        print('   ${success ? '✅' : '❌'} Video completion: $success');
        return ApiResponse.success(success);
      }

      print('   ❌ Failed to complete video');
      return ApiResponse.error('Failed to complete video');

    } catch (e) {
      print('   ❌ Error completing video: $e');
      return ApiResponse.error('Failed to complete video: ${e.toString()}');
    }
  }

  /// Unlock next module after passing assessment
  /// Endpoint: POST /api/modules/{moduleId}/unlock-next?userId={userId}&courseId={courseId}
  /// Returns: {"success": true}
  Future<ApiResponse<bool>> unlockNextModule({
    required int userId,
    required int moduleId,
    required int courseId,
  }) async {
    // FIX: Remove /api prefix
    final endpoint = '/modules/$moduleId/unlock-next?userId=$userId&courseId=$courseId';  // Changed from '/api/modules/$moduleId/unlock-next'

    print('\n🔓 Unlocking next module...');
    print('   ├─ User ID: $userId');
    print('   ├─ Module ID: $moduleId');
    print('   └─ Course ID: $courseId');
    print('   └─ Endpoint: $endpoint');

    try {
      final response = await _httpService.post<Map<String, dynamic>>(
        endpoint,
            (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        final success = response.data!['success'] == true;
        print('   ${success ? '✅' : '❌'} Module unlock: $success');
        return ApiResponse.success(success);
      }

      print('   ❌ Failed to unlock next module');
      return ApiResponse.error('Failed to unlock next module');

    } catch (e) {
      print('   ❌ Error unlocking next module: $e');
      return ApiResponse.error('Failed to unlock next module: ${e.toString()}');
    }
  }

  // ==================== NEW SEARCH METHODS ====================

  /// NEW: Search courses by keyword (title AND tags)
  /// Endpoint: GET /api/courses?search={keyword}&userId={userId}
  /// Returns: {"data": [CourseModel...]}
  Future<ApiResponse<List<CourseModel>>> searchCourses(String keyword, {int? userId}) async {
    final endpoint = '/courses';
    final Map<String, String> queryParams = {'search': keyword};
    if (userId != null) {
      queryParams['userId'] = userId.toString();
    }

    print('\n🔍 ================================');
    print('🔍 Searching courses from backend...');
    print('🔍 Search keyword: "$keyword"');
    print('🔍 User ID: ${userId ?? "Not provided"}');
    print('🔍 Endpoint: $endpoint');
    print('🔍 Query params: $queryParams');
    print('🔍 ================================\n');

    try {
      print('🔍 Step 1: Making HTTP request');
      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data,
        queryParams: queryParams,
      );

      print('\n🔍 Step 2: HTTP Response Received');
      print('🔍 Response isSuccess: ${response.isSuccess}');

      final errorMsg = response.error ?? response.errorMessage ?? 'Unknown error';
      print('🔍 Response error: $errorMsg');

      if (!response.isSuccess) {
        print('❌ HTTP request failed: $errorMsg');
        return ApiResponse.error(errorMsg);
      }

      if (response.data == null) {
        print('❌ Response data is null');
        return ApiResponse.error('No data received from server');
      }

      // Extract courses data
      final coursesData = response.data!['data'];
      print('🔍 Step 4: Extracting courses data');
      print('🔍 coursesData type: ${coursesData.runtimeType}');

      if (coursesData == null) {
        print('❌ No "data" field found in response');
        return ApiResponse.error('No courses data found');
      }

      if (coursesData is! List) {
        print('❌ Courses data is not a List');
        return ApiResponse.error('Invalid courses data format');
      }

      print('\n✅ Found ${coursesData.length} courses\n');

      // Parse courses
      final List<CourseModel> courses = [];
      for (var i = 0; i < coursesData.length; i++) {
        final courseJson = coursesData[i];

        if (courseJson is! Map<String, dynamic>) {
          print('❌ Course $i is not a Map, skipping...');
          continue;
        }

        try {
          final course = CourseModel.fromJson(courseJson);
          courses.add(course);
          print('   ✅ "${course.title}"');
        } catch (e) {
          print('   ❌ Error parsing course $i: $e');
          continue;
        }
      }

      if (courses.isEmpty) {
        print('\n❌ No courses found for search: "$keyword"');
        return ApiResponse.error('No courses found for "$keyword"');
      }

      print('\n🎉 Search Results:');
      print('🎉 Found ${courses.length} courses for "$keyword"');
      print('🎉 First course: "${courses.first.title}"');
      print('🎉 Last course: "${courses.last.title}"');

      return ApiResponse.success(courses);

    } catch (e, stackTrace) {
      print('\n❌❌❌ UNEXPECTED ERROR ❌❌❌');
      print('❌ Error searching courses: $e');
      print('❌ Stack trace: $stackTrace');
      return ApiResponse.error('Search error: ${e.toString()}');
    }
  }

  /// NEW: Get search suggestions for autocomplete
  /// Endpoint: GET /api/courses/search/suggestions?query={query}
  /// Returns: {"suggestions": ["suggestion1", "suggestion2", ...]}
  Future<ApiResponse<List<String>>> getSearchSuggestions(String query) async {
    if (query.length < 2) {
      return ApiResponse.success([]);
    }

    final endpoint = '/courses/search/suggestions';
    final queryParams = {'query': query};

    print('\n💡 Getting search suggestions...');
    print('💡 Query: "$query"');
    print('💡 Endpoint: $endpoint');

    try {
      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data,
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        final suggestionsData = response.data!['suggestions'];
        if (suggestionsData is List) {
          final suggestions = suggestionsData.map((item) => item.toString()).toList();
          print('💡 Got ${suggestions.length} suggestions');
          print('💡 Suggestions: $suggestions');
          return ApiResponse.success(suggestions);
        }
      }

      print('💡 No suggestions found or error');
      return ApiResponse.success([]);

    } catch (e) {
      print('💡 Error getting suggestions: $e');
      return ApiResponse.success([]);
    }
  }

  /// NEW: Get popular tags
  /// Endpoint: GET /api/courses/tags/popular
  /// Returns: {"tags": ["tag1", "tag2", ...]}
  Future<ApiResponse<List<String>>> getPopularTags() async {
    final endpoint = '/courses/tags/popular';

    print('\n🏷️ Getting popular tags...');
    print('🏷️ Endpoint: $endpoint');

    try {
      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data,
      );

      if (response.isSuccess && response.data != null) {
        final tagsData = response.data!['tags'];
        if (tagsData is List) {
          final tags = tagsData.map((item) => item.toString()).toList();
          print('🏷️ Got ${tags.length} popular tags');
          print('🏷️ Tags: $tags');
          return ApiResponse.success(tags);
        }
      }

      print('🏷️ No tags found or error');
      return ApiResponse.success([]);

    } catch (e) {
      print('🏷️ Error getting popular tags: $e');
      return ApiResponse.success([]);
    }
  }

  /// NEW: Get courses by specific tag
  /// Endpoint: GET /api/courses/tag/{tagName}?userId={userId}
  /// Returns: {"data": [CourseModel...]}
  Future<ApiResponse<List<CourseModel>>> getCoursesByTag(String tag, {int? userId}) async {
    final endpoint = '/courses/tag/$tag';
    final Map<String, String> queryParams = {};
    if (userId != null) {
      queryParams['userId'] = userId.toString();
    }

    print('\n🏷️ Getting courses by tag...');
    print('🏷️ Tag: "$tag"');
    print('🏷️ User ID: ${userId ?? "Not provided"}');
    print('🏷️ Endpoint: $endpoint');

    try {
      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data,
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        final coursesData = response.data!['data'];
        if (coursesData is List) {
          final List<CourseModel> courses = [];
          for (var courseJson in coursesData) {
            if (courseJson is Map<String, dynamic>) {
              try {
                final course = CourseModel.fromJson(courseJson);
                courses.add(course);
              } catch (e) {
                print('   ❌ Error parsing course: $e');
              }
            }
          }
          print('🏷️ Found ${courses.length} courses with tag "$tag"');
          return ApiResponse.success(courses);
        }
      }

      print('🏷️ No courses found for tag "$tag"');
      return ApiResponse.success([]);

    } catch (e) {
      print('🏷️ Error getting courses by tag: $e');
      return ApiResponse.success([]);
    }
  }

  /// NEW: Advanced search with filters
  /// Endpoint: GET /api/courses/advanced-search?search={}&category={}&level={}&minPrice={}&maxPrice={}&minRating={}&userId={}
  /// Returns: {"data": [CourseModel...]}
  Future<ApiResponse<List<CourseModel>>> advancedSearch({
    String? search,
    String? category,
    String? level,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    int? userId,
  }) async {
    final endpoint = '/courses/advanced-search';
    final Map<String, String> queryParams = {};

    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (level != null && level.isNotEmpty) queryParams['level'] = level;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (minRating != null) queryParams['minRating'] = minRating.toString();
    if (userId != null) queryParams['userId'] = userId.toString();

    print('\n🔍🔍 ADVANCED SEARCH 🔍🔍');
    print('🔍 Search: "$search"');
    print('🔍 Category: $category');
    print('🔍 Level: $level');
    print('🔍 Price: ${minPrice != null ? '\$$minPrice' : ''} - ${maxPrice != null ? '\$$maxPrice' : ''}');
    print('🔍 Min Rating: $minRating');
    print('🔍 User ID: ${userId ?? "Not provided"}');
    print('🔍 Endpoint: $endpoint');
    print('🔍 Query params: $queryParams');

    try {
      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data,
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        final coursesData = response.data!['data'];
        if (coursesData is List) {
          final List<CourseModel> courses = [];
          for (var courseJson in coursesData) {
            if (courseJson is Map<String, dynamic>) {
              try {
                final course = CourseModel.fromJson(courseJson);
                courses.add(course);
              } catch (e) {
                print('   ❌ Error parsing course: $e');
              }
            }
          }
          print('🔍 Found ${courses.length} courses');
          return ApiResponse.success(courses);
        }
      }

      print('🔍 No courses found with filters');
      return ApiResponse.success([]);

    } catch (e) {
      print('🔍 Error in advanced search: $e');
      return ApiResponse.success([]);
    }
  }

  /// NEW: Quick search for dashboard suggestions
  Future<ApiResponse<List<CourseModel>>> quickSearch(String query, {int limit = 5}) async {
    final result = await searchCourses(query);
    if (result.isSuccess && result.data != null) {
      final limitedResults = result.data!.take(limit).toList();
      return ApiResponse.success(limitedResults);
    }
    return result;
  }

  /// NEW: Get all courses with optional user ID
  Future<ApiResponse<List<CourseModel>>> getAllCourses({int? userId}) async {
    return await searchCourses('', userId: userId);
  }
}