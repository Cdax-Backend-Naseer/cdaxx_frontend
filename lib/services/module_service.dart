// module_service.dart - UPDATED VERSION

import '/services/http_service.dart';
import '../models/module_model.dart';

class ModuleService {
  final HttpService _httpService = HttpService();

  Future<List<ModuleModel>> fetchModules({
    required int courseId,
    required int userId,
  }) async {
    print('🔍 ModuleService.fetchModules() called');
    print('   Course ID: $courseId');
    print('   User ID: $userId');

    try {
      // Use HttpService with JWT token automatically added
      final response = await _httpService.get<List<ModuleModel>>(
        'modules/course/$courseId', // Endpoint path
            (json) {
          // Handle response parsing
          if (json is List) {
            return json.map((e) => ModuleModel.fromJson(e)).toList();
          } else if (json is Map && json.containsKey('data')) {
            // If response is wrapped in {success: true, data: [...]}
            final data = json['data'];
            if (data is List) {
              return data.map((e) => ModuleModel.fromJson(e)).toList();
            }
          }
          return []; // Return empty list if format is unexpected
        },
        queryParams: {'userId': userId.toString()},
      );

      if (response.isSuccess) {
        print('✅ Modules fetched successfully: ${response.data!.length} modules');
        return response.data!;
      } else {
        print('❌ Failed to fetch modules: ${response.errorMessage}');
        throw Exception(response.errorMessage);
      }
    } catch (e) {
      print('❌ Exception fetching modules: $e');
      rethrow;
    }
  }

  // Alternative method if you want to handle response differently
  Future<List<ModuleModel>> getModulesForCourse(int courseId, int userId) async {
    return fetchModules(courseId: courseId, userId: userId);
  }

  // Method to get a specific module
  Future<ModuleModel?> getModuleById(int moduleId) async {
    print('🔍 ModuleService.getModuleById() called');
    print('   Module ID: $moduleId');

    try {
      final response = await _httpService.get<ModuleModel?>(
        'modules/$moduleId',
            (json) {
          if (json != null) {
            return ModuleModel.fromJson(json);
          }
          return null;
        },
      );

      if (response.isSuccess) {
        print('✅ Module fetched successfully');
        return response.data;
      } else {
        print('❌ Failed to fetch module: ${response.errorMessage}');
        return null;
      }
    } catch (e) {
      print('❌ Exception fetching module: $e');
      return null;
    }
  }

  // Method to update module progress (if needed)
  Future<bool> updateModuleProgress({
    required int moduleId,
    required int userId,
    required double progress,
    required bool completed,
  }) async {
    print('🔍 ModuleService.updateModuleProgress() called');
    print('   Module ID: $moduleId');
    print('   User ID: $userId');
    print('   Progress: $progress');
    print('   Completed: $completed');

    try {
      final response = await _httpService.post<bool>(
        'modules/$moduleId/progress',
            (json) => json['success'] ?? false,
        body: {
          'userId': userId,
          'progress': progress,
          'completed': completed,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.isSuccess && response.data == true) {
        print('✅ Module progress updated successfully');
        return true;
      } else {
        print('❌ Failed to update module progress: ${response.errorMessage}');
        return false;
      }
    } catch (e) {
      print('❌ Exception updating module progress: $e');
      return false;
    }
  }

  // Method to mark module as completed
  Future<bool> markModuleAsCompleted(int moduleId, int userId) async {
    return updateModuleProgress(
      moduleId: moduleId,
      userId: userId,
      progress: 100.0,
      completed: true,
    );
  }
}