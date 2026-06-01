import 'package:flutter/foundation.dart';
import '../../models/dashboard/dashboard_public_model.dart';
import '../../models/backend/course_model.dart';
import '../../models/dashboard/dashboard_stats_model.dart';
import '../../services/dashboard_service.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../services/connectivity_service.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  final AuthService _authService = AuthService();
  final CacheService _cacheService = CacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // New user dashboard state (for users with no enrollment history)
  NewUserDashboardModel? _newUserDashboard;
  bool _isLoadingNewUser = false;
  String? _newUserError;

  // User dashboard state (now using backend course models)
  List<CourseModel>? _userCourses;
  bool _isLoadingUser = false;
  String? _userError;

  // Dashboard statistics
  DashboardStatsModel? _dashboardStats;
  bool _isLoadingStats = false;
  String? _statsError;

  // Current user info
  String? _currentUserId;
  bool _isAuthenticated = false;

  // Offline mode flag
  bool _isOfflineMode = false;

  // Getters for new user dashboard
  NewUserDashboardModel? get newUserDashboard => _newUserDashboard;
  bool get isLoadingNewUser => _isLoadingNewUser;
  String? get newUserError => _newUserError;

  // Getters for user dashboard
  List<CourseModel>? get userCourses => _userCourses;
  bool get isLoadingUser => _isLoadingUser;
  String? get userError => _userError;

  // Getters for dashboard statistics
  DashboardStatsModel? get dashboardStats => _dashboardStats;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  // Helper getters for dashboard logic
  List<CourseModel> get enrolledCourses => _userCourses?.where((c) => c.isSubscribed).toList() ?? [];
  List<CourseModel> get availableCourses => _userCourses?.where((c) => !c.isSubscribed).toList() ?? [];
  bool get hasEnrolledCourses => enrolledCourses.isNotEmpty;

  // General getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  bool get hasData => _newUserDashboard != null || _userCourses != null;
  bool get isOfflineMode => _isOfflineMode;

  /// Set authentication context from UserProvider
  void setAuthenticationContext({
    required bool isAuthenticated,
    String? userId,
  }) {
    // Only update if values have actually changed
    final bool authChanged = _isAuthenticated != isAuthenticated;
    final bool userIdChanged = _currentUserId != userId;

    if (!authChanged && !userIdChanged) {
      return; // No changes, skip update
    }

    if (authChanged || userIdChanged) {
      print('🔐 DashboardProvider: Auth context changed - Authenticated: $isAuthenticated, UserId: $userId');
    }

    _isAuthenticated = isAuthenticated;
    _currentUserId = userId;

    // Clear opposite dashboard data when auth context changes
    if (isAuthenticated) {
      _newUserDashboard = null;
      _newUserError = null;
    } else {
      _userCourses = null;
      _userError = null;
      _dashboardStats = null;
      _statsError = null;
      _currentUserId = null;
    }

    notifyListeners();
  }

  /// Initialize dashboard state based on authentication
  Future<void> initialize() async {
    print('🚀 Initializing Dashboard Provider...');

    try {
      _isAuthenticated = await _authService.isAuthenticated();

      if (_isAuthenticated) {
        final user = await _authService.getCurrentUser();
        _currentUserId = user?.id?.toString();
        print('   ├─ User authenticated: $_currentUserId');

        if (_currentUserId != null) {
          await loadUserDashboardWithOfflineSupport();
        } else {
          await loadPublicDashboard();
        }
      } else {
        print('   ├─ User not authenticated, loading public dashboard');
        await loadPublicDashboard();
      }
    } catch (e) {
      print('❌ Error initializing dashboard: $e');
      await loadPublicDashboard(); // Fallback to public dashboard
    }

    notifyListeners();
  }

  /// Select a specific course to view its stats
  Future<void> selectCourseForStats(int courseId) async {
    print('🎯 Selecting course for stats: $courseId');
    await loadDashboardStatsWithOfflineSupport(null, courseId);
  }

  /// Load dashboard statistics with offline support
  Future<void> loadDashboardStatsWithOfflineSupport([int? userId, int? selectedCourseId]) async {
    final targetUserId = userId ?? (int.tryParse(_currentUserId ?? '') ?? 0);
    if (targetUserId == 0 || _isLoadingStats) return;

    final isOnline = _connectivityService.isConnected;

    print('📈 Loading dashboard statistics (Online: $isOnline)...');
    print('   ├─ User ID: $targetUserId');
    if (selectedCourseId != null) {
      print('   ├─ For course ID: $selectedCourseId');
    }

    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      if (isOnline) {
        final response = await _dashboardService.getDashboardStats(
          targetUserId,
          selectedCourseId: selectedCourseId,
        );

        if (response.isSuccess && response.data != null) {
          _dashboardStats = response.data!;
          _isOfflineMode = false;
          print('   ✅ Dashboard statistics loaded successfully');
          print('   ├─ Total Courses: ${_dashboardStats!.totalCourses}');
          print('   ├─ In Progress: ${_dashboardStats!.inProgressCourses}');
          print('   ├─ Videos: ${_dashboardStats!.completedVideos}/${_dashboardStats!.totalVideos}');
          print('   ├─ Overall Progress: ${_dashboardStats!.overallProgress}%');

          if (_dashboardStats!.selectedCourseId != null) {
            print('   └─ Selected Course: ${_dashboardStats!.selectedCourseId}');
          }
        } else {
          _statsError = response.error ?? 'Failed to load dashboard statistics';
          print('   ❌ Failed to load dashboard statistics: $_statsError');
        }
      } else {
        _statsError = 'No internet connection';
        _isOfflineMode = true;
        print('   ⚠️ Offline: Cannot load statistics');
      }
    } catch (e) {
      _statsError = 'Unexpected error: ${e.toString()}';
      print('   ❌ Exception loading dashboard statistics: $e');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Original loadDashboardStats (kept for compatibility)
  Future<void> loadDashboardStats([int? userId, int? selectedCourseId]) async {
    await loadDashboardStatsWithOfflineSupport(userId, selectedCourseId);
  }

  /// Load public dashboard (new user dashboard)
  Future<void> loadPublicDashboard() async {
    print('📊 Loading public dashboard...');
    _isLoadingNewUser = true;
    _newUserError = null;
    notifyListeners();

    try {
      final response = await _dashboardService.getNewUserDashboard();

      if (response.isSuccess && response.data != null) {
        _newUserDashboard = response.data!;
        print('   ✅ Public dashboard loaded successfully');
      } else {
        _newUserError = response.error ?? 'Failed to load public dashboard';
        print('   ❌ Failed to load public dashboard: $_newUserError');
      }
    } catch (e) {
      _newUserError = 'Unexpected error: ${e.toString()}';
      print('   ❌ Exception loading public dashboard: $e');
    } finally {
      _isLoadingNewUser = false;
      notifyListeners();
    }
  }

  /// Load user dashboard with offline support (NEW)
  Future<void> loadUserDashboardWithOfflineSupport([int? userId]) async {
    final targetUserId = userId ?? (int.tryParse(_currentUserId ?? '') ?? 0);
    if (targetUserId == 0 || _isLoadingUser) return;

    final isOnline = _connectivityService.isConnected;

    print('📊 Loading user courses for dashboard (Online: $isOnline): $targetUserId');
    _isLoadingUser = true;
    _userError = null;
    notifyListeners();

    try {
      // Try network if online
      if (isOnline) {
        final response = await _dashboardService.getUserDashboard(targetUserId);

        if (response.isSuccess && response.data != null) {
          _userCourses = response.data!;
          _isOfflineMode = false;

          // Cache the courses
          await _cacheCoursesLocally(_userCourses!);

          print('   ✅ User dashboard loaded successfully from network');
          print('   ├─ Total courses: ${_userCourses!.length}');
          print('   ├─ Enrolled courses: ${enrolledCourses.length}');
          print('   └─ Available courses: ${availableCourses.length}');

          // Log course details for debugging
          for (final course in _userCourses!) {
            print('      ├─ ${course.title} (ID: ${course.id})');
            print('      │  ├─ Subscribed: ${course.isSubscribed}');
            print('      │  └─ Progress: ${course.progressPercent.toStringAsFixed(1)}%');
          }

          // Load stats in background
          _loadStatsInBackground(targetUserId);
        } else {
          // Network failed, try cache
          print('   ⚠️ Network failed, trying cache...');
          final loadedFromCache = await _loadCoursesFromCache();
          if (!loadedFromCache) {
            _userError = response.error ?? 'Failed to load user dashboard';
            print('   ❌ Failed to load user dashboard: $_userError');
          }
        }
      } else {
        // Offline - load from cache
        print('   📴 Offline mode, loading from cache...');
        final loadedFromCache = await _loadCoursesFromCache();
        if (!loadedFromCache) {
          _userError = 'No internet connection and no cached data available';
          print('   ❌ $_userError');
        }
      }
    } catch (e) {
      print('   ❌ Exception loading user dashboard: $e');
      // Try cache as fallback
      final loadedFromCache = await _loadCoursesFromCache();
      if (!loadedFromCache) {
        _userError = 'Unexpected error: ${e.toString()}';
      }
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  /// Load courses from cache (offline mode)
  Future<bool> _loadCoursesFromCache() async {
    print('💾 Attempting to load courses from cache...');

    final cachedCourses = await _cacheService.getCachedCourses();

    if (cachedCourses != null && cachedCourses.isNotEmpty) {
      try {
        final List<CourseModel> courses = [];
        for (var courseJson in cachedCourses) {
          try {
            final course = CourseModel.fromJson(courseJson);
            courses.add(course);
          } catch (e) {
            print('⚠️ Error parsing cached course: $e');
          }
        }

        if (courses.isNotEmpty) {
          _userCourses = courses;
          _isOfflineMode = true;
          print('✅ Loaded ${courses.length} courses from cache (OFFLINE MODE)');
          print('   ├─ Enrolled: ${enrolledCourses.length}');
          print('   └─ Available: ${availableCourses.length}');
          return true;
        }
      } catch (e) {
        print('❌ Error processing cached courses: $e');
      }
    }

    print('⚠️ No cached courses found');
    return false;
  }

  /// Cache courses locally
  Future<void> _cacheCoursesLocally(List<CourseModel> courses) async {
    try {
      final coursesJson = courses.map((c) => c.toJson()).toList();
      await _cacheService.cacheCourses(coursesJson);
      await _cacheService.updateLastSync();
      print('💾 ${courses.length} courses cached');
    } catch (e) {
      print('❌ Failed to cache courses: $e');
    }
  }

  /// Load stats in background
  Future<void> _loadStatsInBackground(int userId) async {
    try {
      print('📈 Loading dashboard statistics in background...');
      final statsResponse = await _dashboardService.getDashboardStats(userId);

      if (statsResponse.isSuccess && statsResponse.data != null) {
        _dashboardStats = statsResponse.data!;
        print('   ✅ Stats loaded in background');
        print('   ├─ Progress: ${_dashboardStats!.overallProgress}%');
        print('   ├─ Videos: ${_dashboardStats!.completedVideos}/${_dashboardStats!.totalVideos}');
        print('   ├─ Courses: ${_dashboardStats!.totalCourses} total, ${_dashboardStats!.inProgressCourses} in progress');
        notifyListeners();
      } else {
        print('   ⚠️ Failed to load stats in background: ${statsResponse.error}');
      }
    } catch (e) {
      print('   ⚠️ Error loading stats in background: $e');
    }
  }

  /// Original loadUserDashboard (kept for compatibility - now uses offline version)
  Future<void> loadUserDashboard([int? userId]) async {
    await loadUserDashboardWithOfflineSupport(userId);
  }

  /// Refresh dashboard with force network (pull to refresh)
  Future<void> refreshWithNetwork() async {
    if (!_connectivityService.isConnected) {
      _userError = 'Cannot refresh: No internet connection';
      notifyListeners();
      return;
    }

    print('🔄 Force refreshing dashboard from network...');
    _isLoadingUser = true;
    notifyListeners();

    try {
      final targetUserId = int.tryParse(_currentUserId ?? '') ?? 0;
      final response = await _dashboardService.getUserDashboard(targetUserId);

      if (response.isSuccess && response.data != null) {
        _userCourses = response.data!;
        _isOfflineMode = false;
        _userError = null;

        // Update cache
        await _cacheCoursesLocally(_userCourses!);
        await _loadStatsInBackground(targetUserId);

        print('✅ Force refresh complete: ${_userCourses!.length} courses');
      } else {
        _userError = response.error ?? 'Failed to refresh';
      }
    } catch (e) {
      _userError = 'Refresh failed: ${e.toString()}';
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  /// Refresh current dashboard data
  Future<void> refresh() async {
    print('🔄 Refreshing dashboard...');

    if (_isAuthenticated && _currentUserId != null) {
      await refreshWithNetwork();
    } else if (!_isAuthenticated) {
      await loadPublicDashboard();
    } else {
      // Try cache
      await _loadCoursesFromCache();
    }
  }

  /// Record user activity (for authenticated users only)
  Future<void> recordActivity({
    required String type,
    String? courseId,
    String? moduleId,
    String? videoId,
    String? assessmentId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isAuthenticated || _currentUserId == null) {
      print('⚠️ Cannot record activity - user not authenticated');
      return;
    }

    print('📝 Recording activity: $type');
    try {
      await _dashboardService.recordActivity(
        userId: _currentUserId!,
        type: type,
        courseId: courseId,
        moduleId: moduleId,
        videoId: videoId,
        assessmentId: assessmentId,
        metadata: metadata,
      );
      print('   ✅ Activity recorded successfully');
    } catch (e) {
      print('   ❌ Failed to record activity: $e');
    }
  }

  /// Update authentication state (call after login/logout)
  Future<void> updateAuthState({String? userId}) async {
    final wasAuthenticated = _isAuthenticated;
    _isAuthenticated = await _authService.isAuthenticated();

    if (_isAuthenticated) {
      _currentUserId = userId;
      if (_currentUserId == null) {
        final user = await _authService.getCurrentUser();
        _currentUserId = user?.id?.toString();
      }

      // Switch from public to user dashboard
      if (!wasAuthenticated) {
        _newUserDashboard = null;
        _newUserError = null;
        await loadUserDashboardWithOfflineSupport();
      }
    } else {
      // User logged out - clear user data
      _currentUserId = null;
      _userCourses = null;
      _userError = null;
      _dashboardStats = null;
      _statsError = null;
      _isOfflineMode = false;
    }

    notifyListeners();
  }

  /// Clear all data and errors
  void clearData() {
    print('🧹 Clearing dashboard data...');
    _newUserDashboard = null;
    _userCourses = null;
    _dashboardStats = null;
    _newUserError = null;
    _userError = null;
    _statsError = null;
    _isLoadingNewUser = false;
    _isLoadingUser = false;
    _isLoadingStats = false;
    _isOfflineMode = false;
    notifyListeners();
  }

  /// Clear specific error
  void clearError({bool public = true, bool user = true}) {
    if (public) _newUserError = null;
    if (user) _userError = null;
    notifyListeners();
  }

  /// Set online mode (call when connection is restored)
  void setOnlineMode() {
    if (_isOfflineMode && _connectivityService.isConnected) {
      _isOfflineMode = false;
      notifyListeners();
    }
  }

  /// Check if user has cached courses
  Future<bool> hasCachedCourses() async {
    return await _cacheService.hasCachedCourses();
  }

  /// Get cache info for debugging
  Future<Map<String, dynamic>> getCacheInfo() async {
    return await _cacheService.getCacheStats();
  }
}