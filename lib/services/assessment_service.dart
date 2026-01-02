import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/assessment/assessment_model.dart';
import '../models/assessment/question_model.dart';
import '../providers/user_provider.dart';
import '/config/environment_config.dart';

class AssessmentService {
  final String baseUrl = EnvironmentConfig.baseUrl;

// In assessment_service.dart, update the getModuleAssessments method:
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

      // CORRECT ENDPOINT: /api/modules/{moduleId}/assessments
      final uri = Uri.parse('$baseUrl/api/modules/$moduleIdLong/assessments');

      print('📡 Calling module assessments: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // The endpoint returns List<Assessment> directly
        if (data is List) {
          return data.map((a) => Assessment.fromJson(a)).toList();
        } else {
          print('Unexpected response format: $data');
          return [];
        }
      } else {
        print('Failed to get module assessments: ${response.statusCode} - ${response.body}');
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

      // Convert to simple Map<String, String>
      final Map<String, String> jsonBody = {};
      answers.forEach((key, value) {
        jsonBody[key.toString()] = value;
      });

      print('   JSON Body to send: $jsonBody');

      final uri = Uri.parse('$baseUrl/api/course/assessment/submit')
          .replace(queryParameters: {
        'userId': userId.toString(),
        'assessmentId': assessmentId.toString(),
      });

      print('   URL: ${uri.toString()}');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(jsonBody),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Server error: ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAssessmentStatus({
    required int userId,
    required int assessmentId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/course/assessment/status')
          .replace(queryParameters: {
        'userId': userId.toString(),
        'assessmentId': assessmentId.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get assessment status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get assessment status: $e');
    }
  }

  Future<List<Question>> getAssessmentWithQuestions({
    required int userId,
    required int assessmentId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/assessments/$assessmentId/questions')
          .replace(queryParameters: {
        'userId': userId.toString(),
        'assessmentId': assessmentId.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> questionsData = data['questions'] ?? [];

        return questionsData.map((q) => Question.fromJson(q)).toList();
      } else {
        throw Exception('Failed to get assessment questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get assessment questions: $e');
    }
  }

  Future<Assessment?> getAssessmentDetails(int assessmentId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/course/assessment/$assessmentId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Assessment.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> canAttemptAssessment({
    required int userId,
    required int assessmentId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/course/assessment/can-attempt')
          .replace(queryParameters: {
        'userId': userId.toString(),
        'assessmentId': assessmentId.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['canAttempt'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Add this method to check if assessment exists
  Future<bool> checkAssessmentExists(int assessmentId) async {
    try {
      final assessment = await getAssessmentDetails(assessmentId);
      return assessment != null;
    } catch (e) {
      return false;
    }
  }

  // Add this method to get assessment progress
  Future<Map<String, dynamic>> getAssessmentProgress({
    required int userId,
    required int assessmentId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/course/assessment/progress')
          .replace(queryParameters: {
        'userId': userId.toString(),
        'assessmentId': assessmentId.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get assessment progress: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get assessment progress: $e');
    }
  }
}