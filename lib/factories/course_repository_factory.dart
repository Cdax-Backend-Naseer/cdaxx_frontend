  // Course Repository Factory
  // Automatically chooses between remote and mock repository based on configuration

  import 'package:flutter/cupertino.dart';
  import 'package:flutter/foundation.dart';
  import '../screens/courses/data/course_repository.dart';
  import '../screens/courses/data/remote_course_repository.dart';
  import '../config/backend_config.dart';
  import '../providers/user_provider.dart'; // Add this import
  import 'package:provider/provider.dart';

import '../services/http_service.dart'; // Add this import

  /// Factory class to provide the appropriate CourseRepository implementation
  /// Automatically switches between remote backend and mock data based on configuration
  class CourseRepositoryFactory {
    static CourseRepository? _instance;
    static String? _currentUserId; // Track user ID

    /// Get the singleton instance of CourseRepository
    /// Returns RemoteCourseRepository configured with backend and user context
    static CourseRepository getInstance(
        {String? userId, BuildContext? context}) {
      // Try to get userId from context if not provided
      String? resolvedUserId = userId;

      print('🔍 CourseRepositoryFactory DEBUG:');
      print('   ├─ Input userId parameter: $userId');
      print('   ├─ Context provided: ${context != null}');

      if (resolvedUserId == null && context != null) {
        try {
          final userProvider = Provider.of<UserProvider>(
              context, listen: false);
          resolvedUserId = userProvider.currentUser?.id?.toString();

          print('   👤 UserProvider DEBUG:');
          print('      ├─ isAuthenticated: ${userProvider.isAuthenticated}');
          print('      ├─ currentUser: ${userProvider.currentUser != null ? "EXISTS" : "NULL"}');
          if (userProvider.currentUser != null) {
            print('      ├─ currentUser.id: ${userProvider.currentUser!.id}');
            print('      ├─ currentUser.email: ${userProvider.currentUser!.email}');
          }
        } catch (e) {
          print('   ⚠️ Could not get user ID from context: $e');
        }
      }

      // === ADD THIS DEBUG TO SEE FINAL RESULT ===
      print('   🎯 FINAL resolvedUserId: ${resolvedUserId ?? "NULL"}');
      // === END DEBUG ===

      // Check if we need to create a new instance
      final bool shouldCreateNew =
          _instance == null ||
              _currentUserId != resolvedUserId; // Create new if user changed

      if (!shouldCreateNew) return _instance!;

      if (kDebugMode) {
        debugPrint(
            '\n🏭 CourseRepositoryFactory: Creating repository instance...');
        debugPrint('   ├─ Creating RemoteCourseRepository');
        debugPrint('   ├─ Base URL: ${BackendConfig.baseUrl}');
        debugPrint('   ├─ Timeout: ${BackendConfig.requestTimeout}');
        debugPrint('   └─ User ID: ${resolvedUserId ?? "NOT SET"}');
      }

      _currentUserId = resolvedUserId;

      _instance = RemoteCourseRepository(
        baseUrl: BackendConfig.baseUrl,
        userId: resolvedUserId,
        timeout: BackendConfig.requestTimeout,
        httpService: HttpService(), // Add this line
      );

      return _instance!;
    }
  }