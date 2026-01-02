// Remote Course Repository for Spring Boot backend integration
// Implements the CourseRepository interface with HTTP calls

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'course_repository.dart';
import 'models/course.dart';
import 'models/module.dart';
import 'models/video.dart';

import '../../../models/assessment/question_model.dart';
import '../../../models/assessment/assessment_model.dart';

/// Remote implementation of CourseRepository that communicates with Spring Boot backend
class RemoteCourseRepository implements CourseRepository {
  final String baseUrl;
  final String? userId;
  final Duration timeout;

  RemoteCourseRepository({
    required this.baseUrl,
    this.userId,
    this.timeout = const Duration(seconds: 10),
  }) {
    print('🔗 RemoteCourseRepository initialized with baseUrl: $baseUrl, userId: $userId');
  }

  @override
  Future<List<Course>> getCourses({String? search, int page = 1}) async {
    print('\n📡 Fetching courses from backend...');
    print('   ├─ Search: ${search ?? 'none'}');
    print('   ├─ Page: $page');
    print('   ├─ User ID: ${userId ?? "NOT SET"}');
    print('   └─ URL: $baseUrl/api/courses');

    try {
      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
      };

      // Add userId ONLY if it's available
      if (userId != null && userId!.isNotEmpty) {
        queryParams['userId'] = userId!;
      } else {
        print('   ⚠️ WARNING: No userId provided, subscription status may be incorrect');
      }

      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$baseUrl/api/courses').replace(queryParameters: queryParams);
      print('   🌐 Full request URL: $uri');

      // Make HTTP request
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      print('   📨 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('   ✅ Successfully received courses data');

        // Handle different response structures
        List<dynamic> coursesData = [];
        if (jsonResponse.containsKey('data')) {
          coursesData = jsonResponse['data'] as List;
        } else if (jsonResponse.containsKey('courses')) {
          coursesData = jsonResponse['courses'] as List;
        } else {
          // If response is not structured, try to find a list in values
          for (var value in jsonResponse.values) {
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

        // Backend already sends correct locking information - return as-is
        return courses;
      } else {
        print('   ❌ Backend returned error: ${response.statusCode}');
        print('   📄 Error response: ${response.body}');
        throw Exception('Backend returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('   🚨 Error fetching courses from backend: $e');
      rethrow;
    }
  }


  @override
  Future<List<Course>> getPublicCourses() async {
    final url = "$baseUrl/api/courses/public";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Course.fromJson(e)).toList();
    } else {
      throw Exception("Public API failed: ${response.body}");
    }
  }

  @override
  Future<Course> getCourseById(String id) async {
    print('\n📡 Fetching course details from backend...');
    print('   ├─ Course ID: $id');
    print('   ├─ User ID: ${userId ?? "NOT SET"}');
    print('   └─ URL: $baseUrl/api/courses/$id');

    try {
      // Build query parameters with actual user ID
      final Map<String, String> queryParams = {};

      // Use actual user ID if available
      if (userId != null && userId!.isNotEmpty) {
        queryParams['userId'] = userId!;
        print('   👤 Using actual user ID: $userId');
      } else {
        queryParams['userId'] = '20'; // Fallback to hardcoded ID
        print('   ⚠️ No user ID available, falling back to ID: 20');
      }

      final uri = Uri.parse('$baseUrl/api/courses/$id').replace(
        queryParameters: queryParams,
      );
      print('   🌐 Full request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      print('   📨 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('   ✅ Successfully received course details');

        // Handle different response structures
        Map<String, dynamic> courseData;
        if (jsonResponse.containsKey('data')) {
          courseData = jsonResponse['data'];
        } else if (jsonResponse.containsKey('course')) {
          courseData = jsonResponse['course'];
        } else {
          courseData = jsonResponse;
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

        // Backend already sends correct locking information - return as-is
        return course;
      } else {
        print('   ❌ Backend returned error: ${response.statusCode}');
        print('   📄 Error response: ${response.body}');
        throw Exception('Backend returned ${response.statusCode}: ${response.body}');
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
    print('   └─ URL: $baseUrl/api/courses/$courseId/enroll');

    try {
      final uri = Uri.parse('$baseUrl/api/courses/$courseId/enroll');
      print('   🌐 Full request URL: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'courseId': courseId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(timeout);

      print('   📨 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('   ✅ Successfully enrolled in course');

        return jsonResponse['success'] == true ||
            jsonResponse['enrolled'] == true ||
            response.statusCode == 201;
      } else {
        print('   ❌ Backend enrollment failed: ${response.statusCode}');
        print('   📄 Error response: ${response.body}');
        throw Exception('Backend enrollment failed: ${response.statusCode}');
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
    print('   └─ URL: $baseUrl/api/courses/$courseId/unenroll');

    try {
      final uri = Uri.parse('$baseUrl/api/courses/$courseId/unenroll');
      print('   🌐 Full request URL: $uri');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      print('   📨 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('   ✅ Successfully unenrolled from course');
        return true;
      } else {
        print('   ❌ Backend unenrollment failed: ${response.statusCode}');
        print('   📄 Error response: ${response.body}');
        throw Exception('Backend unenrollment failed: ${response.statusCode}');
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
    print('   └─ URL: $baseUrl/api/courses/$courseId/purchase');

    try {
      final uri = Uri.parse('$baseUrl/api/courses/$courseId/purchase');
      print('   🌐 Full request URL: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'courseId': courseId,
          'userId': userId ?? '1',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(timeout);

      print('   📨 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('   ✅ Successfully purchased course');

        return jsonResponse['success'] == true ||
            jsonResponse['purchased'] == true ||
            response.statusCode == 201;
      } else {
        print('   ❌ Backend purchase failed: ${response.statusCode}');
        print('   📄 Error response: ${response.body}');
        throw Exception('Backend purchase failed: ${response.statusCode}');
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
    print('   └─ URL: $baseUrl/api/assessments/$assessmentId/questions');

    try {
      final uri = Uri.parse('$baseUrl/api/assessments/$assessmentId/questions');
      print('   🌐 Full request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      print('   📨 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('   ✅ Successfully received questions data');

        // Handle different response structures
        List<dynamic> questionsData = [];
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          questionsData = jsonResponse['data'] as List;
        } else if (jsonResponse.containsKey('questions') && jsonResponse['questions'] is List) {
          questionsData = jsonResponse['questions'] as List;
        } else if (jsonResponse is List) {
          questionsData = jsonResponse as List;
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
        print('   📄 Error response: ${response.body}');
        throw Exception('Backend returned ${response.statusCode}: ${response.body}');
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
    print('   └─ URL: $baseUrl/api/modules/$moduleId/assessments');

    try {
      final uri = Uri.parse('$baseUrl/api/modules/$moduleId/assessments');
      print('   🌐 Full request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      print('   📨 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic jsonDecoded = json.decode(response.body);

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
        throw Exception('Backend returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('   🚨 Error fetching assessments from backend: $e');
      rethrow;
    }
  }
}