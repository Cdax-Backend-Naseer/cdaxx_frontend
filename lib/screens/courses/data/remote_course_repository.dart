// Remote Course Repository for Spring Boot backend integration
// Implements the CourseRepository interface with HTTP calls

import 'course_repository.dart';
import 'models/course.dart';
import '../../../services/http_service.dart';

import '../../../models/assessment/question_model.dart';
import '../../../models/assessment/assessment_model.dart';

/// Remote implementation of CourseRepository that communicates with Spring Boot backend
class RemoteCourseRepository implements CourseRepository {
  final String baseUrl;
  final String? userId;
  final Duration timeout;
  final HttpService _httpService;

  RemoteCourseRepository({
    required this.baseUrl,
    this.userId,
    this.timeout = const Duration(seconds: 10),
    required HttpService httpService,
  }) : _httpService = httpService {
    print('🔗 RemoteCourseRepository initialized with baseUrl: $baseUrl, userId: $userId');
  }

  @override
  Future<List<Course>> getCourses({String? search, int page = 1}) async {
    print('\n📡 Fetching courses from backend...');
    print('   ├─ Search: ${search ?? 'none'}');
    print('   ├─ Page: $page');
    print('   ├─ User ID: ${userId ?? "NOT SET"}');

    try {
      // Build endpoint with query parameters
      String endpoint = '/courses?page=$page';

      // Add userId ONLY if it's available
      if (userId != null && userId!.isNotEmpty) {
        endpoint += '&userId=$userId';
      } else {
        print('   ⚠️ WARNING: No userId provided, subscription status may be incorrect');
      }

      if (search != null && search.trim().isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search.trim())}';
      }

      print('   🔐 Using HttpService for authenticated request...');
      print('   🌐 Endpoint: $endpoint');

      // ✅ FIXED: Use endpoint with query parameters
      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data as Map<String, dynamic>,
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        print('   ✅ Successfully received courses data');

        // Handle different response structures
        List<dynamic> coursesData = [];
        if (response.data!.containsKey('data')) {
          coursesData = response.data!['data'] as List;
        } else if (response.data!.containsKey('courses')) {
          coursesData = response.data!['courses'] as List;
        } else {
          // If response is not structured, try to find a list in values
          for (var value in response.data!.values) {
            if (value is List) {
              coursesData = value;
              break;
            }
          }
        }

        print('   📚 Found ${coursesData.length} courses in response');

        // Parse courses
        final List<Course> courses = coursesData.map((courseJson) {
          try {
            return Course.fromJson(courseJson);
          } catch (e) {
            print('   ⚠️ Error parsing course: $e');
            print('   📄 Problematic course data: $courseJson');
            rethrow;
          }
        }).toList();

        print('   🎓 Successfully parsed ${courses.length} courses');
        for (final course in courses) {
          int totalVideos = course.modules.fold(0, (sum, module) => sum + module.videos.length);
          print('   ├─ ${course.title}: ${course.modules.length} modules, $totalVideos videos, isSubscribed: ${course.isSubscribed}');
        }

        return courses;
      } else {
        print('   ❌ Backend returned error: ${response.statusCode}');
        print('   📄 Error response: ${response.errorMessage}');
        throw Exception('Backend returned ${response.statusCode}: ${response.errorMessage}');
      }
    } catch (e) {
      print('   🚨 Error fetching courses from backend: $e');
      rethrow;
    }
  }

  @override
  Future<List<Course>> getPublicCourses() async {
    try {
      print('🌐 Fetching public courses...');

      // Backend returns a MAP {"data": [...], "success": true, etc.}
      final response = await _httpService.get<Map<String, dynamic>>(
        'courses/public',
            (data) => data as Map<String, dynamic>, // ✅ Expecting a Map, not List
      );

      print('📡 Public courses response:');
      print('   ├─ Success: ${response.isSuccess}');
      print('   ├─ Status: ${response.statusCode}');
      print('   ├─ Has Data: ${response.data != null}');
      print('   ├─ Data Type: ${response.data?.runtimeType}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        // ✅ Debug: Print all keys in the response
        print('   ├─ Response keys: ${data.keys}');

        // ✅ Extract the list from the map
        List<dynamic> coursesData = [];

        if (data.containsKey('data') && data['data'] is List) {
          coursesData = data['data'] as List<dynamic>;
          print('✅ Found ${coursesData.length} courses in "data" field');
        }
        else if (data.containsKey('courses') && data['courses'] is List) {
          coursesData = data['courses'] as List<dynamic>;
          print('✅ Found ${coursesData.length} courses in "courses" field');
        }
        else if (data.containsKey('items') && data['items'] is List) {
          coursesData = data['items'] as List<dynamic>;
          print('✅ Found ${coursesData.length} courses in "items" field');
        }
        else {
          print('❌ No course list found in response. Available keys: ${data.keys}');
          print('❌ Full response: $data');
          return [];
        }

        // ✅ Parse courses from the list
        final courses = coursesData.map((json) => Course.fromJson(json as Map<String, dynamic>)).toList();
        print('✅ Parsed ${courses.length} public courses');
        return courses;
      } else {
        print('❌ Failed to fetch public courses: ${response.errorMessage}');
        print('❌ Response: ${response.data}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Exception fetching public courses: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  @override
  Future<Course> getCourseById(String id) async {
    print('\n📡 Fetching course details from backend...');
    print('   ├─ Course ID: $id');
    print('   ├─ User ID: ${userId ?? "NOT SET"}');

    try {
      // Build endpoint with query parameters
      String endpoint = '/courses/$id';

      // Use actual user ID if available
      final actualUserId = userId ?? '20';
      endpoint += '?userId=$actualUserId';

      if (userId != null && userId!.isNotEmpty) {
        print('   👤 Using actual user ID: $userId');
      } else {
        print('   ⚠️ No user ID available, falling back to ID: 20');
      }

      print('   🔐 Using HttpService for authenticated request...');
      print('   🌐 Endpoint: $endpoint');

      // ✅ Already uses HttpService correctly
      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data as Map<String, dynamic>,
      );

      print('   📨 Response status code from HttpService: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        print('   ✅ Successfully received course details');

        // Handle different response structures
        Map<String, dynamic> courseData;
        if (response.data!.containsKey('data')) {
          courseData = response.data!['data'];
        } else if (response.data!.containsKey('course')) {
          courseData = response.data!['course'];
        } else {
          courseData = response.data!;
        }

        final Course course = Course.fromJson(courseData);
        int totalVideos = course.modules.fold(0, (sum, module) => sum + module.videos.length);
        print('   🎓 Course: ${course.title} (${course.modules.length} modules, $totalVideos videos)');
        print('   🔐 Subscription status: ${course.isSubscribed ? "SUBSCRIBED" : "NOT SUBSCRIBED"}');

        // Debug: Print backend locking status
        print('   🔒 Backend Locking Status:');
        for (var mIndex = 0; mIndex < course.modules.length; mIndex++) {
          final m = course.modules[mIndex];
          print('      📝 Module $mIndex: ${m.title} - Backend isLocked: ${m.isLocked}');

          for (var vIndex = 0; vIndex < m.videos.length; vIndex++) {
            final v = m.videos[vIndex];
            print('         🎥 Video $vIndex: ${v.title} - Backend isLocked: ${v.isLocked}');
          }
        }

        return course;
      } else {
        print('   ❌ Backend returned error: ${response.statusCode ?? "Unknown"}');
        print('   📄 Error response: ${response.errorMessage}');
        throw Exception('Backend returned ${response.statusCode}: ${response.errorMessage}');
      }
    } catch (e) {
      print('   🚨 Error fetching course details from backend: $e');
      rethrow;
    }
  }

  @override
  Future<bool> enrollInCourse(String courseId) async {
    print('\n📡 Enrolling in course via backend...');
    print('   ├─ Course ID: $courseId');

    try {
      print('   🔐 Using HttpService for authenticated request...');

      // ✅ FIXED: Use endpoint with parameters
      final endpoint = '/api/courses/$courseId/enroll';

      final response = await _httpService.post<Map<String, dynamic>>(
        endpoint,
            (data) => data as Map<String, dynamic>,
        body: {
          'courseId': courseId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        print('   ✅ Successfully enrolled in course');

        return response.data!['success'] == true ||
            response.data!['enrolled'] == true ||
            response.statusCode == 201;
      } else {
        print('   ❌ Backend enrollment failed: ${response.statusCode}');
        print('   📄 Error response: ${response.errorMessage}');
        throw Exception('Backend enrollment failed: ${response.errorMessage}');
      }
    } catch (e) {
      print('   🚨 Error enrolling in course via backend: $e');
      rethrow;
    }
  }

  @override
  Future<bool> unenrollFromCourse(String courseId) async {
    print('\n📡 Unenrolling from course via backend...');
    print('   ├─ Course ID: $courseId');

    try {
      print('   🔐 Using HttpService for authenticated request...');

      // ✅ FIXED: Use HttpService instead of raw http.delete()
      final response = await _httpService.delete<Map<String, dynamic>>(
        '/api/courses/$courseId/unenroll',
            (data) => data as Map<String, dynamic>,
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess) {
        print('   ✅ Successfully unenrolled from course');
        return true;
      } else {
        print('   ❌ Backend unenrollment failed: ${response.statusCode}');
        print('   📄 Error response: ${response.errorMessage}');
        throw Exception('Backend unenrollment failed: ${response.errorMessage}');
      }
    } catch (e) {
      print('   🚨 Error unenrolling from course via backend: $e');
      rethrow;
    }
  }

  @override
  Future<bool> purchaseCourse(String courseId) async {
    print('\n📡 Purchasing course via backend...');
    print('   ├─ Course ID: $courseId');
    print('   ├─ User ID: ${userId ?? "NOT SET"}');

    try {
      print('   🔐 Using HttpService for authenticated request...');

      // ✅ FIXED: Build URL with query parameters
      final endpoint = '/purchase?userId=${userId ?? '1'}&courseId=$courseId';

      final response = await _httpService.post<Map<String, dynamic>>(
        endpoint,  // Use the full endpoint with query params
            (data) => data as Map<String, dynamic>,
        // No queryParams parameter needed - they're in the endpoint
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        print('   ✅ Successfully purchased course');

        return response.data!['success'] == true ||
            response.data!['purchased'] == true ||
            response.statusCode == 201;
      } else {
        print('   ❌ Backend purchase failed: ${response.statusCode}');
        print('   📄 Error response: ${response.errorMessage}');
        throw Exception('Backend purchase failed: ${response.errorMessage}');
      }
    } catch (e) {
      print('   🚨 Error purchasing course via backend: $e');
      rethrow;
    }
  }

  @override
  Future<List<Question>> getAssessmentQuestions(String assessmentId) async {
    print('\n📡 Fetching assessment questions from backend...');
    print('   ├─ Assessment ID: $assessmentId');

    try {
      print('   🔐 Using HttpService for authenticated request...');

      // ✅ FIXED: Use HttpService instead of raw http.get()
      final response = await _httpService.get<Map<String, dynamic>>(
        '/api/assessments/$assessmentId/questions',
            (data) => data as Map<String, dynamic>,
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        print('   ✅ Successfully received questions data');

        // Handle different response structures
        List<dynamic> questionsData = [];
        if (response.data!.containsKey('data') && response.data!['data'] is List) {
          questionsData = response.data!['data'] as List;
        } else if (response.data!.containsKey('questions') && response.data!['questions'] is List) {
          questionsData = response.data!['questions'] as List;
        } else if (response.data is List) {
          questionsData = response.data as List;
        }

        print('   📋 Found ${questionsData.length} questions in response');

        // Parse questions
        final List<Question> questions = questionsData.map((questionJson) {
          try {
            return Question.fromJson(questionJson);
          } catch (e) {
            print('   ⚠️ Error parsing question: $e');
            print('   📄 Problematic question data: $questionJson');
            rethrow;
          }
        }).toList();

        print('   ❓ Successfully parsed ${questions.length} questions');

        return questions;
      } else {
        print('   ❌ Backend returned error: ${response.statusCode}');
        print('   📄 Error response: ${response.errorMessage}');
        throw Exception('Backend returned ${response.statusCode}: ${response.errorMessage}');
      }
    } catch (e) {
      print('   🚨 Error fetching questions from backend: $e');
      rethrow;
    }
  }

  @override
  Future<List<Assessment>> getModuleAssessments(String moduleId) async {
    print('\n📡 Fetching module assessments from backend...');
    print('   ├─ Module ID: $moduleId');

    try {
      print('   🔐 Using HttpService for authenticated request...');

      // ✅ FIXED: Use HttpService instead of raw http.get()
      final response = await _httpService.get<dynamic>(
        '/api/modules/$moduleId/assessments',
            (data) => data,
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        final dynamic jsonDecoded = response.data;

        List<dynamic> jsonResponse = [];
        if (jsonDecoded is List) {
          jsonResponse = jsonDecoded;
        } else if (jsonDecoded is Map<String, dynamic>) {
          if (jsonDecoded.containsKey('data')) {
            jsonResponse = jsonDecoded['data'] as List;
          } else if (jsonDecoded.containsKey('questions')) {
            jsonResponse = jsonDecoded['questions'] as List;
          } else {
            jsonResponse = [];
          }
        }

        print('   ✅ Successfully received questions data');
        print('   📋 Found ${jsonResponse.length} questions in response');

        // Parse assessments
        final List<Assessment> assessments = jsonResponse.map((assessmentJson) {
          try {
            return Assessment.fromJson(assessmentJson);
          } catch (e) {
            print('   ⚠️ Error parsing assessment: $e');
            rethrow;
          }
        }).toList();

        print('   📝 Successfully parsed ${assessments.length} assessments');

        return assessments;
      } else {
        print('   ❌ Backend returned error: ${response.statusCode}');
        throw Exception('Backend returned ${response.statusCode}: ${response.errorMessage}');
      }
    } catch (e) {
      print('   🚨 Error fetching assessments from backend: $e');
      rethrow;
    }
  }
}