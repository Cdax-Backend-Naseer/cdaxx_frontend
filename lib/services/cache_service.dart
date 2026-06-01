import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cache Service for offline-first architecture
/// Stores all app data locally for offline access
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Cache keys
  static const String _cachedUserKey = 'cached_user';
  static const String _cachedCoursesKey = 'cached_courses';
  static const String _cachedModulesPrefix = 'cached_modules_';
  static const String _cachedCourseDetailsPrefix = 'cached_course_';
  static const String _lastSyncKey = 'last_sync_time';
  static const String _hasCachedDataKey = 'has_cached_data';

  // ==================== USER CACHING ====================

  /// Cache user data
  Future<void> cacheUser(Map<String, dynamic> userData) async {
    try {
      await _storage.write(key: _cachedUserKey, value: jsonEncode(userData));
      await _storage.write(key: _hasCachedDataKey, value: 'true');
      debugPrint('✅ User cached successfully');
    } catch (e) {
      debugPrint('❌ Failed to cache user: $e');
    }
  }

  /// Get cached user
  Future<Map<String, dynamic>?> getCachedUser() async {
    try {
      final userJson = await _storage.read(key: _cachedUserKey);
      if (userJson != null && userJson.isNotEmpty) {
        return jsonDecode(userJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get cached user: $e');
      return null;
    }
  }

  /// Check if user exists in cache
  Future<bool> hasCachedUser() async {
    final user = await getCachedUser();
    return user != null;
  }

  // ==================== COURSES CACHING ====================

  /// Cache courses list
  Future<void> cacheCourses(List<Map<String, dynamic>> courses) async {
    try {
      await _storage.write(key: _cachedCoursesKey, value: jsonEncode(courses));
      debugPrint('✅ ${courses.length} courses cached');
    } catch (e) {
      debugPrint('❌ Failed to cache courses: $e');
    }
  }

  /// Get cached courses
  Future<List<Map<String, dynamic>>?> getCachedCourses() async {
    try {
      final coursesJson = await _storage.read(key: _cachedCoursesKey);
      if (coursesJson != null && coursesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(coursesJson);
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get cached courses: $e');
      return null;
    }
  }

  /// Check if courses are cached
  Future<bool> hasCachedCourses() async {
    final courses = await getCachedCourses();
    return courses != null && courses.isNotEmpty;
  }

  // ==================== MODULES CACHING ====================

  /// Cache modules for a specific course
  Future<void> cacheModules(String courseId, List<Map<String, dynamic>> modules) async {
    try {
      final key = '$_cachedModulesPrefix$courseId';
      await _storage.write(key: key, value: jsonEncode(modules));
      debugPrint('✅ ${modules.length} modules cached for course $courseId');
    } catch (e) {
      debugPrint('❌ Failed to cache modules for course $courseId: $e');
    }
  }

  /// Get cached modules for a specific course
  Future<List<Map<String, dynamic>>?> getCachedModules(String courseId) async {
    try {
      final key = '$_cachedModulesPrefix$courseId';
      final modulesJson = await _storage.read(key: key);
      if (modulesJson != null && modulesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(modulesJson);
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get cached modules for course $courseId: $e');
      return null;
    }
  }

  /// Check if modules are cached for a course
  Future<bool> hasCachedModules(String courseId) async {
    final modules = await getCachedModules(courseId);
    return modules != null && modules.isNotEmpty;
  }

  // ==================== COURSE DETAILS CACHING ====================

  /// Cache single course details
  Future<void> cacheCourseDetails(String courseId, Map<String, dynamic> course) async {
    try {
      final key = '$_cachedCourseDetailsPrefix$courseId';
      await _storage.write(key: key, value: jsonEncode(course));
      debugPrint('✅ Course $courseId details cached');
    } catch (e) {
      debugPrint('❌ Failed to cache course details: $e');
    }
  }

  /// Get cached course details
  Future<Map<String, dynamic>?> getCachedCourseDetails(String courseId) async {
    try {
      final key = '$_cachedCourseDetailsPrefix$courseId';
      final courseJson = await _storage.read(key: key);
      if (courseJson != null && courseJson.isNotEmpty) {
        return jsonDecode(courseJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get cached course details: $e');
      return null;
    }
  }

  // ==================== SYNC MANAGEMENT ====================

  /// Update last sync time
  Future<void> updateLastSync() async {
    final now = DateTime.now().toIso8601String();
    await _storage.write(key: _lastSyncKey, value: now);
    debugPrint('🕐 Last sync updated: $now');
  }

  /// Get last sync time
  Future<DateTime?> getLastSync() async {
    try {
      final syncTime = await _storage.read(key: _lastSyncKey);
      if (syncTime != null && syncTime.isNotEmpty) {
        return DateTime.parse(syncTime);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get last sync time: $e');
      return null;
    }
  }

  /// Check if cache is stale (older than X hours)
  Future<bool> isCacheStale({int maxHours = 24}) async {
    final lastSync = await getLastSync();
    if (lastSync == null) return true;

    final difference = DateTime.now().difference(lastSync);
    return difference.inHours > maxHours;
  }

  /// Check if any cached data exists
  Future<bool> hasAnyCachedData() async {
    final hasData = await _storage.read(key: _hasCachedDataKey);
    return hasData == 'true';
  }

  // ==================== CLEAR CACHE ====================

  /// Clear all cached data (for logout)
  Future<void> clearAllCache() async {
    try {
      await _storage.delete(key: _cachedUserKey);
      await _storage.delete(key: _cachedCoursesKey);
      await _storage.delete(key: _lastSyncKey);
      await _storage.delete(key: _hasCachedDataKey);

      // Clear all module caches (can't delete by pattern, so we need to list)
      final allKeys = await _storage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith(_cachedModulesPrefix) ||
            key.startsWith(_cachedCourseDetailsPrefix)) {
          await _storage.delete(key: key);
        }
      }

      debugPrint('🗑️ All cache cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear cache: $e');
    }
  }

  /// Clear only courses cache (for refresh)
  Future<void> clearCoursesCache() async {
    try {
      await _storage.delete(key: _cachedCoursesKey);

      // Clear module caches too since they depend on courses
      final allKeys = await _storage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith(_cachedModulesPrefix) ||
            key.startsWith(_cachedCourseDetailsPrefix)) {
          await _storage.delete(key: key);
        }
      }

      debugPrint('🗑️ Courses cache cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear courses cache: $e');
    }
  }

  // ==================== DEBUG ====================

  /// Get cache statistics (for debugging)
  Future<Map<String, dynamic>> getCacheStats() async {
    final allKeys = await _storage.readAll();
    final moduleKeys = allKeys.keys.where((k) => k.startsWith(_cachedModulesPrefix)).length;
    final courseDetailKeys = allKeys.keys.where((k) => k.startsWith(_cachedCourseDetailsPrefix)).length;

    return {
      'hasUser': await hasCachedUser(),
      'hasCourses': await hasCachedCourses(),
      'cachedModuleCount': moduleKeys,
      'cachedCourseDetailCount': courseDetailKeys,
      'lastSync': await getLastSync(),
      'isStale': await isCacheStale(),
    };
  }
}