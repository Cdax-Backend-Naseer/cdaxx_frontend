// Course Service - UPDATED WITH SEARCH METHODS
import '../constants/api_endpoints.dart';
import 'http_service.dart';

class CourseService {
  final HttpService _httpService = HttpService();

  // =============== EXISTING METHODS ===============

  // Get all courses
  Future<ApiResponse<List<Course>>> getAllCourses({
    int page = 0,
    int size = 20,
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;

      return await _httpService.get<List<Course>>(
        ApiEndpoints.allCourses,
            (data) => (data['content'] as List)
            .map((item) => Course.fromJson(item))
            .toList(),
        queryParams: queryParams,
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch courses: ${e.toString()}');
    }
  }

  // Get featured courses
  Future<ApiResponse<List<Course>>> getFeaturedCourses() async {
    try {
      return await _httpService.get<List<Course>>(
        ApiEndpoints.featuredCourses,
            (data) => (data as List)
            .map((item) => Course.fromJson(item))
            .toList(),
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch featured courses: ${e.toString()}');
    }
  }

  // Get popular courses
  Future<ApiResponse<List<Course>>> getPopularCourses() async {
    try {
      return await _httpService.get<List<Course>>(
        ApiEndpoints.popularCourses,
            (data) => (data as List)
            .map((item) => Course.fromJson(item))
            .toList(),
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch popular courses: ${e.toString()}');
    }
  }

  // Get course details
  Future<ApiResponse<Course>> getCourseDetails(String courseId) async {
    try {
      final endpoint = ApiEndpoints.replacePathParams(
        ApiEndpoints.courseDetails,
        {'id': courseId},
      );

      return await _httpService.get<Course>(
        endpoint,
            (data) => Course.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch course details: ${e.toString()}');
    }
  }

  // =============== NEW SEARCH METHODS ===============

  /// NEW: Search courses by keyword (title AND tags)
  Future<ApiResponse<List<Course>>> searchCourses(String keyword) async {
    try {
      final queryParams = <String, String>{
        'search': keyword,
      };

      return await _httpService.get<List<Course>>(
        ApiEndpoints.allCourses, // Use the same endpoint as getAllCourses
            (data) => (data['content'] as List)
            .map((item) => Course.fromJson(item))
            .toList(),
        queryParams: queryParams,
      );
    } catch (e) {
      return ApiResponse.error('Failed to search courses: ${e.toString()}');
    }
  }

  /// NEW: Get search suggestions for autocomplete
  Future<ApiResponse<List<String>>> getSearchSuggestions(String query) async {
    try {
      if (query.length < 2) {
        return ApiResponse.success([]);
      }

      final queryParams = <String, String>{
        'query': query,
      };

      // Add this endpoint to your ApiEndpoints
      return await _httpService.get<List<String>>(
        '/courses/search/suggestions', // Add to ApiEndpoints
            (data) {
          if (data['suggestions'] is List) {
            return (data['suggestions'] as List)
                .map((item) => item.toString())
                .toList();
          }
          return [];
        },
        queryParams: queryParams,
      );
    } catch (e) {
      return ApiResponse.success([]); // Return empty array on error
    }
  }

  /// NEW: Get popular tags
  Future<ApiResponse<List<String>>> getPopularTags() async {
    try {
      // Add this endpoint to your ApiEndpoints
      return await _httpService.get<List<String>>(
        '/courses/tags/popular', // Add to ApiEndpoints
            (data) {
          if (data['tags'] is List) {
            return (data['tags'] as List)
                .map((item) => item.toString())
                .toList();
          }
          return [];
        },
      );
    } catch (e) {
      return ApiResponse.success([]); // Return empty array on error
    }
  }

  /// NEW: Get courses by specific tag
  Future<ApiResponse<List<Course>>> getCoursesByTag(String tag) async {
    try {
      // Add this endpoint to your ApiEndpoints
      return await _httpService.get<List<Course>>(
        '/courses/tag/$tag', // Add to ApiEndpoints
            (data) => (data['content'] as List)
            .map((item) => Course.fromJson(item))
            .toList(),
      );
    } catch (e) {
      return ApiResponse.success([]); // Return empty array on error
    }
  }

  /// NEW: Advanced search with filters
  Future<ApiResponse<List<Course>>> advancedSearch({
    String? search,
    String? category,
    String? level,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (level != null && level.isNotEmpty) queryParams['level'] = level;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (minRating != null) queryParams['minRating'] = minRating.toString();

      // Add this endpoint to your ApiEndpoints
      return await _httpService.get<List<Course>>(
        '/courses/advanced-search', // Add to ApiEndpoints
            (data) => (data['content'] as List)
            .map((item) => Course.fromJson(item))
            .toList(),
        queryParams: queryParams,
      );
    } catch (e) {
      return ApiResponse.success([]); // Return empty array on error
    }
  }

  // =============== OTHER EXISTING METHODS ===============

  // Get course content
  Future<ApiResponse<CourseContent>> getCourseContent(String courseId) async {
    try {
      final endpoint = ApiEndpoints.replacePathParams(
        ApiEndpoints.courseContent,
        {'id': courseId},
      );

      return await _httpService.get<CourseContent>(
        endpoint,
            (data) => CourseContent.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch course content: ${e.toString()}');
    }
  }

  // Enroll in course
  Future<ApiResponse<Map<String, dynamic>>> enrollCourse(String courseId) async {
    try {
      final endpoint = ApiEndpoints.replacePathParams(
        ApiEndpoints.courseEnroll,
        {'id': courseId},
      );

      return await _httpService.post<Map<String, dynamic>>(
        endpoint,
            (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse.error('Failed to enroll in course: ${e.toString()}');
    }
  }

  // Get user's enrolled courses
  Future<ApiResponse<List<Course>>> getUserCourses() async {
    try {
      return await _httpService.get<List<Course>>(
        ApiEndpoints.userCourses,
            (data) => (data as List)
            .map((item) => Course.fromJson(item))
            .toList(),
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch user courses: ${e.toString()}');
    }
  }

  // Get course progress
  Future<ApiResponse<CourseProgress>> getCourseProgress(String courseId) async {
    try {
      final endpoint = ApiEndpoints.replacePathParams(
        ApiEndpoints.courseProgress,
        {'id': courseId},
      );

      return await _httpService.get<CourseProgress>(
        endpoint,
            (data) => CourseProgress.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch course progress: ${e.toString()}');
    }
  }

  // Update course progress
  Future<ApiResponse<Map<String, dynamic>>> updateCourseProgress({
    required String courseId,
    required String lessonId,
    required double progressPercentage,
    bool completed = false,
  }) async {
    try {
      final endpoint = ApiEndpoints.replacePathParams(
        ApiEndpoints.courseProgress,
        {'id': courseId},
      );

      return await _httpService.post<Map<String, dynamic>>(
        endpoint,
            (data) => data as Map<String, dynamic>,
        body: {
          'lessonId': lessonId,
          'progressPercentage': progressPercentage,
          'completed': completed,
        },
      );
    } catch (e) {
      return ApiResponse.error('Failed to update course progress: ${e.toString()}');
    }
  }

  // Get course reviews
  Future<ApiResponse<List<CourseReview>>> getCourseReviews(String courseId) async {
    try {
      final endpoint = ApiEndpoints.replacePathParams(
        ApiEndpoints.courseReviews,
        {'id': courseId},
      );

      return await _httpService.get<List<CourseReview>>(
        endpoint,
            (data) => (data as List)
            .map((item) => CourseReview.fromJson(item))
            .toList(),
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch course reviews: ${e.toString()}');
    }
  }

  // Add course review
  Future<ApiResponse<CourseReview>> addCourseReview({
    required String courseId,
    required int rating,
    required String comment,
  }) async {
    try {
      final endpoint = ApiEndpoints.replacePathParams(
        ApiEndpoints.courseReviews,
        {'id': courseId},
      );

      return await _httpService.post<CourseReview>(
        endpoint,
            (data) => CourseReview.fromJson(data),
        body: {
          'rating': rating,
          'comment': comment,
        },
      );
    } catch (e) {
      return ApiResponse.error('Failed to add course review: ${e.toString()}');
    }
  }

  // Get course categories
  Future<ApiResponse<List<CourseCategory>>> getCourseCategories() async {
    try {
      return await _httpService.get<List<CourseCategory>>(
        ApiEndpoints.courseCategories,
            (data) => (data as List)
            .map((item) => CourseCategory.fromJson(item))
            .toList(),
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch course categories: ${e.toString()}');
    }
  }
}

// =============== MODEL CLASSES ===============

class Course {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final double price;
  final double rating;
  final int duration;
  final String imageUrl;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.price,
    required this.rating,
    required this.duration,
    required this.imageUrl, required isLocked, required thumbnailUrl, required progressPercent,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      instructor: json['instructor'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      imageUrl: json['imageUrl'] ?? '', isLocked: null, thumbnailUrl: null, progressPercent: null,
    );
  }
}

class CourseContent {
  final String courseId;
  final List<Lesson> lessons;

  CourseContent({
    required this.courseId,
    required this.lessons,
  });

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    return CourseContent(
      courseId: json['courseId'] ?? '',
      lessons: (json['lessons'] as List? ?? [])
          .map((item) => Lesson.fromJson(item))
          .toList(),
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String type;
  final int duration;
  final String? videoUrl;
  final String? content;

  Lesson({
    required this.id,
    required this.title,
    required this.type,
    required this.duration,
    this.videoUrl,
    this.content,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      duration: json['duration'] ?? 0,
      videoUrl: json['videoUrl'],
      content: json['content'],
    );
  }
}

class CourseProgress {
  final String courseId;
  final double progressPercentage;
  final int completedLessons;
  final int totalLessons;
  final DateTime lastAccessed;

  CourseProgress({
    required this.courseId,
    required this.progressPercentage,
    required this.completedLessons,
    required this.totalLessons,
    required this.lastAccessed,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['courseId'] ?? '',
      progressPercentage: (json['progressPercentage'] ?? 0).toDouble(),
      completedLessons: json['completedLessons'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      lastAccessed: DateTime.tryParse(json['lastAccessed'] ?? '') ?? DateTime.now(),
    );
  }
}

class CourseReview {
  final String id;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  CourseReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory CourseReview.fromJson(Map<String, dynamic> json) {
    return CourseReview(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class CourseCategory {
  final String id;
  final String name;
  final String icon;

  CourseCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory CourseCategory.fromJson(Map<String, dynamic> json) {
    return CourseCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}