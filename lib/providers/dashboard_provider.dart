/// Dashboard Provider - Fixed Version
import 'package:flutter/foundation.dart';
import '../../models/dashboard/dashboard_public_model.dart';
import '../../models/backend/course_model.dart';
import '../../models/dashboard/dashboard_stats_model.dart'; // ADD THIS
import '../../services/dashboard_service.dart';
import '../../services/auth_service.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  final AuthService _authService = AuthService();

  // New user dashboard state (for users with no enrollment history)
  NewUserDashboardModel? _newUserDashboard;
  bool _isLoadingNewUser = false;
  String? _newUserError;

  // User dashboard state (now using backend course models)
  List<CourseModel>? _userCourses;
  bool _isLoadingUser = false;
  String? _userError;

  // ADD THIS: Dashboard statistics
  DashboardStatsModel? _dashboardStats;
  bool _isLoadingStats = false;
  String? _statsError;

  // Current user info
  String? _currentUserId;
  bool _isAuthenticated = false;

  // Getters for new user dashboard
  NewUserDashboardModel? get newUserDashboard => _newUserDashboard;
  bool get isLoadingNewUser => _isLoadingNewUser;
  String? get newUserError => _newUserError;

  // Getters for user dashboard
  List<CourseModel>? get userCourses => _userCourses;
  bool get isLoadingUser => _isLoadingUser;
  String? get userError => _userError;

  // ADD THIS: Getters for dashboard statistics
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
      _dashboardStats = null; // ADD THIS: Clear stats too
      _statsError = null; // ADD THIS: Clear stats error
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
          await loadUserDashboard();
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

    // Reload stats with the selected course
    await loadDashboardStats(null, courseId);
  }

  /// Updated: Load dashboard statistics with optional course selection
  Future<void> loadDashboardStats([int? userId, int? selectedCourseId]) async {
    final targetUserId = userId ?? (int.tryParse(_currentUserId ?? '') ?? 0);
    if (targetUserId == 0 || _isLoadingStats) return;

    print('📈 Loading dashboard statistics...');
    print('   ├─ User ID: $targetUserId');
    if (selectedCourseId != null) {
      print('   ├─ For course ID: $selectedCourseId');
    }

    _isLoadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      final response = await _dashboardService.getDashboardStats(
        targetUserId,
        selectedCourseId: selectedCourseId, // Pass the course ID
      );

      if (response.isSuccess && response.data != null) {
        _dashboardStats = response.data!;
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
    } catch (e) {
      _statsError = 'Unexpected error: ${e.toString()}';
      print('   ❌ Exception loading dashboard statistics: $e');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Load new user dashboard data (deprecated - use getUserDashboard instead)
  /// This method is kept for backward compatibility but no longer used
  /// The conditional dashboard system handles this via getUserDashboard
  @deprecated
  Future<void> loadPublicDashboard() async {
    print('⚠️ loadPublicDashboard is deprecated - use loadUserDashboard instead');
    print('📊 The conditional dashboard system handles new vs existing users automatically');
  }

  /// Load user dashboard data using backend course service
  Future<void> loadUserDashboard([int? userId]) async {
    final targetUserId = userId ?? (int.tryParse(_currentUserId ?? '') ?? 0);
    if (targetUserId == 0 || _isLoadingUser) return;

    print('📊 Loading user courses for dashboard: $targetUserId');
    _isLoadingUser = true;
    _userError = null;
    notifyListeners();

    try {
      final response = await _dashboardService.getUserDashboard(targetUserId);

      if (response.isSuccess && response.data != null) {
        _userCourses = response.data!;
        print('   ✅ User dashboard loaded successfully');
        print('   ├─ Total courses: ${_userCourses!.length}');
        print('   ├─ Enrolled courses: ${enrolledCourses.length}');
        print('   └─ Available courses: ${availableCourses.length}');

        // Log course details for debugging
        for (final course in _userCourses!) {
          print('      ├─ ${course.title} (ID: ${course.id})');
          print('      │  ├─ Subscribed: ${course.isSubscribed}');
          print('      │  └─ Progress: ${course.progressPercent.toStringAsFixed(1)}%');
        }

        // ADD THIS: Load stats in background after courses load
        _loadStatsInBackground(targetUserId);
      } else {
        // FIX: Use response.error instead of response.errorMessage
        _userError = response.error ?? 'Failed to load user dashboard';
        print('   ❌ Failed to load user dashboard: $_userError');
      }
    } catch (e) {
      _userError = 'Unexpected error: ${e.toString()}';
      print('   ❌ Exception loading user dashboard: $e');
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  /// ADD THIS: Load stats in background (doesn't affect loading state)
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
        notifyListeners(); // Update UI with new stats
      } else {
        print('   ⚠️ Failed to load stats in background: ${statsResponse.error}');
      }
    } catch (e) {
      print('   ⚠️ Error loading stats in background: $e');
    }
  }

  /// Refresh current dashboard data
  Future<void> refresh() async {
    print('🔄 Refreshing dashboard...');

    if (_isAuthenticated && _currentUserId != null) {
      await loadUserDashboard();
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
      // Don't throw error - activity recording is optional
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
        await loadUserDashboard();
      }
    } else {
      // User logged out - clear user data
      _currentUserId = null;
      _userCourses = null;
      _userError = null;
      _dashboardStats = null; // ADD THIS: Clear stats
      _statsError = null; // ADD THIS: Clear stats error
    }

    notifyListeners();
  }

  /// Clear all data and errors
  void clearData() {
    print('🧹 Clearing dashboard data...');
    _newUserDashboard = null;
    _userCourses = null;
    _dashboardStats = null; // ADD THIS: Clear stats
    _newUserError = null;
    _userError = null;
    _statsError = null; // ADD THIS: Clear stats error
    _isLoadingNewUser = false;
    _isLoadingUser = false;
    _isLoadingStats = false; // ADD THIS: Reset stats loading
    notifyListeners();
  }

  /// Clear specific error
  void clearError({bool public = true, bool user = true}) {
    if (public) _newUserError = null;
    if (user) _userError = null;
    notifyListeners();
  }
}