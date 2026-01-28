
import '../models/assessment/assessment_model.dart';
import '../models/assessment/question_model.dart';
import '../services/http_service.dart';
import '../config/environment_config.dart';

class AssessmentService {
  final HttpService _httpService;
  final String baseUrl;

  AssessmentService({HttpService? httpService})
      : _httpService = httpService ?? HttpService(),
        baseUrl = EnvironmentConfig.baseUrl;

  // Get module assessments
  Future<List<Assessment>> getModuleAssessments({
    required String courseId,
    required String moduleId,
  }) async {
    try {
      final moduleIdLong = int.tryParse(moduleId);
      if (moduleIdLong == null) {
        print('Invalid moduleId: $moduleId');
        return [];
      }

      final response = await _httpService.get<List<dynamic>>(
        '/api/modules/$moduleIdLong/assessments',
            (data) => data as List<dynamic>,
      );

      print('📡 Module assessments response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        print('✅ Successfully fetched ${data.length} assessments');

        if (data is List) {
          return data.map((a) => Assessment.fromJson(a)).toList();
        } else {
          print('Unexpected response format: $data');
          return [];
        }
      } else {
        print('Failed to get module assessments: ${response.statusCode ?? "Unknown"} - ${response.errorMessage}');
        return [];
      }
    } catch (e) {
      print('Error getting module assessments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> submitAssessment({
    required int userId,
    required int assessmentId,
    required Map<int, String> answers,
  }) async {
    try {
      print('🚀 SUBMIT ASSESSMENT CALLED');
      print('   userId: $userId');
      print('   assessmentId: $assessmentId');
      print('   answers: $answers');

      // ✅ FIXED: Add userId and assessmentId as query parameters
      String endpoint = '/api/course/assessment/submit?userId=$userId&assessmentId=$assessmentId';

      // Convert Map<int, String> to Map<String, String> for JSON serialization
      final Map<String, String> stringKeyAnswers = {};
      answers.forEach((key, value) {
        stringKeyAnswers[key.toString()] = value;
      });

      print('   🔐 Using HttpService for authenticated request...');
      print('   🌐 Endpoint: $endpoint');
      print('   📦 Request body: $stringKeyAnswers');

      final response = await _httpService.post<Map<String, dynamic>>(
        endpoint,
            (data) => data as Map<String, dynamic>,
        body: stringKeyAnswers,
      );

      print('   📨 Response status: ${response.statusCode}');
      print('   📨 Response data: ${response.data}');
      print('   📨 Response message: ${response.errorMessage}');

      if (response.isSuccess && response.data != null) {
        print('   ✅ Assessment submitted successfully!');
        return response.data!;
      } else {
        print('   ❌ Server error: ${response.statusCode ?? "Unknown"} - ${response.errorMessage}');
        if (response.statusCode == 400) {
          print('   🔍 BAD REQUEST: Check if parameters are correctly formatted');
        }
        throw Exception('Server error: ${response.errorMessage}');
      }
    } catch (e) {
      print('   ❌ Exception: $e');
      rethrow;
    }
  }

  // Get assessment status
  Future<Map<String, dynamic>> getAssessmentStatus({
    required int userId,
    required int assessmentId,
  }) async {
    try {
      // ✅ FIXED: Build endpoint with query parameters
      String endpoint = '/api/course/assessment/status';
      endpoint += '?userId=$userId&assessmentId=$assessmentId';

      print('   🔐 Using HttpService for authenticated request...');
      print('   🌐 Endpoint: $endpoint');

      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data as Map<String, dynamic>,
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        print('   ❌ Failed to get assessment status: ${response.statusCode}');
        throw Exception('Failed to get assessment status: ${response.errorMessage}');
      }
    } catch (e) {
      print('   ❌ Error getting assessment status: $e');
      rethrow;
    }
  }

  // Get assessment with questions
  Future<List<Question>> getAssessmentWithQuestions({
    required int userId,
    required int assessmentId,
  }) async {
    try {
      // ✅ FIXED: Build endpoint with query parameters
      String endpoint = '/api/assessments/$assessmentId/questions';
      endpoint += '?userId=$userId';

      print('   🔐 Using HttpService for authenticated request...');
      print('   🌐 Endpoint: $endpoint');

      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data as Map<String, dynamic>,
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final List<dynamic> questionsData = data['questions'] ?? data['data'] ?? [];
        return questionsData.map((q) => Question.fromJson(q)).toList();
      } else {
        print('   ❌ Failed to get assessment questions: ${response.statusCode}');
        print('   📄 Error response: ${response.errorMessage}');
        throw Exception('Failed to get assessment questions: ${response.errorMessage}');
      }
    } catch (e) {
      print('   ❌ Error getting assessment questions: $e');
      rethrow;
    }
  }

  // Get assessment details
  Future<Assessment?> getAssessmentDetails(int assessmentId) async {
    try {
      // ✅ FIXED: Build endpoint with query parameters
      String endpoint = '/api/course/assessment/$assessmentId';

      print('   🔐 Using HttpService for authenticated request...');
      print('   🌐 Endpoint: $endpoint');

      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data as Map<String, dynamic>,
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return Assessment.fromJson(data);
      } else {
        print('   ❌ Failed to get assessment details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('   ❌ Error getting assessment details: $e');
      return null;
    }
  }

  // Check if can attempt assessment
  Future<bool> canAttemptAssessment({
    required int userId,
    required int assessmentId,
  }) async {
    try {
      // ✅ FIXED: Build endpoint with query parameters
      String endpoint = '/api/course/assessment/can-attempt';
      endpoint += '?userId=$userId&assessmentId=$assessmentId';

      print('   🔐 Using HttpService for authenticated request...');
      print('   🌐 Endpoint: $endpoint');

      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data as Map<String, dynamic>,
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return data['canAttempt'] ?? false;
      } else {
        print('   ❌ Failed to check if can attempt: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('   ❌ Error checking if can attempt assessment: $e');
      return false;
    }
  }

  // Check if assessment exists
  Future<bool> checkAssessmentExists(int assessmentId) async {
    try {
      final assessment = await getAssessmentDetails(assessmentId);
      return assessment != null;
    } catch (e) {
      return false;
    }
  }

  // Get assessment progress
  Future<Map<String, dynamic>> getAssessmentProgress({
    required int userId,
    required int assessmentId,
  }) async {
    try {
      // ✅ FIXED: Build endpoint with query parameters
      String endpoint = '/api/course/assessment/progress';
      endpoint += '?userId=$userId&assessmentId=$assessmentId';

      print('   🔐 Using HttpService for authenticated request...');
      print('   🌐 Endpoint: $endpoint');

      final response = await _httpService.get<Map<String, dynamic>>(
        endpoint,
            (data) => data as Map<String, dynamic>,
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        print('   ❌ Failed to get assessment progress: ${response.statusCode}');
        print('   📄 Error response: ${response.errorMessage}');
        throw Exception('Failed to get assessment progress: ${response.errorMessage}');
      }
    } catch (e) {
      print('   ❌ Error getting assessment progress: $e');
      rethrow;
    }
  }

  // New method: Get all assessments for a course
  Future<List<Assessment>> getCourseAssessments(int courseId) async {
    try {
      // ✅ FIXED: Build endpoint with query parameters
      String endpoint = '/api/courses/$courseId/assessments';

      print('   🔐 Using HttpService for authenticated request...');
      print('   🌐 Endpoint: $endpoint');

      final response = await _httpService.get<List<dynamic>>(
        endpoint,
            (data) => data as List<dynamic>,
      );

      print('   📨 Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        if (data is List) {
          return data.map((a) => Assessment.fromJson(a)).toList();
        }
      }
      return [];
    } catch (e) {
      print('   ❌ Error getting course assessments: $e');
      return [];
    }
  }
}