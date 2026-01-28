import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../services/http_service.dart';

/// Gradient background constants from login screen
const LinearGradient _kDashboardBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF020617), // Rich dark blue/navy
    Color(0xFF0F172A), // Slightly lighter dark blue
  ],
);

/// Helper functions for transparent colors
Color _whiteWithOpacity(double opacity) {
  return Color.fromRGBO(255, 255, 255, opacity);
}

Color _blueWithOpacity(double opacity) {
  return Color.fromRGBO(56, 189, 248, opacity);
}

Color _greyWithOpacity(double opacity) {
  return Color.fromRGBO(156, 163, 175, opacity);
}

class ModulesScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const ModulesScreen({super.key, this.onNavigateToTab,});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  bool _isLoadingModules = false;
  List<dynamic> _modules = [];
  String? _error;
  String? _selectedCourseId;
  String? _selectedCourseTitle;

  @override
  void initState() {
    super.initState();
    // Don't load modules automatically anymore
    // Let user select a course first
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.08}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: _whiteWithOpacity(opacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _whiteWithOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _blueWithOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required Widget child,
    Color? backgroundColor,
    bool isOutlined = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? _whiteWithOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOutlined
                  ? const Color(0xFF38BDF8)
                  : _whiteWithOpacity(0.12),
              width: isOutlined ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _blueWithOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadModulesForCourse(String courseId, String courseTitle) async {
    final dashboardProvider =
    Provider.of<DashboardProvider>(context, listen: false);

    if (dashboardProvider.currentUserId == null) {
      setState(() {
        _error = 'User not logged in';
      });
      return;
    }

    setState(() {
      _isLoadingModules = true;
      _selectedCourseId = courseId;
      _selectedCourseTitle = courseTitle;
      _error = null;
      _modules = [];
    });

    try {
      final userId = dashboardProvider.currentUserId!;

      print('📡 Loading modules for course: $courseTitle (ID: $courseId)');
      print('👤 User ID: $userId');

      // ✅ FIXED: Use HttpService instead of raw http.get()
      final httpService = HttpService();

      final response = await httpService.get<Map<String, dynamic>>(
        '/api/modules/course/$courseId?userId=$userId',
            (data) => data as Map<String, dynamic>,
      );

      print('📡 Modules API Response status: ${response.statusCode}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        print('📦 Modules Data received successfully');

        setState(() {
          _modules = data['data'] ?? data['modules'] ?? [];
          _isLoadingModules = false;
        });

        print('✅ Loaded ${_modules.length} modules for course: $courseTitle');
      } else {
        print('❌ Failed to load modules: ${response.errorMessage}');
        setState(() {
          _error = 'Failed to load modules: ${response.errorMessage}';
          _isLoadingModules = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading modules: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = 'Error loading modules: ${e.toString()}';
        _isLoadingModules = false;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedCourseId = null;
      _selectedCourseTitle = null;
      _modules = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

    // If dashboard is still loading user data
    if (dashboardProvider.isLoadingUser) {
      return Container(
        decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
          ),
        ),
      );
    }

    // If no user ID
    if (dashboardProvider.currentUserId == null) {
      return Container(
        decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Modules',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.go('/dashboard'),
            ),
          ),
          body: Center(
            child: _buildGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Please login to access modules',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildGlassButton(
                      onPressed: () => context.go('/login'),
                      backgroundColor: const Color(0xFF38BDF8),
                      child: Text(
                        'Go to Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // If no enrolled courses
    if (dashboardProvider.enrolledCourses.isEmpty) {
      return Container(
        decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Modules',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.go('/dashboard'),
            ),
          ),
          body: Center(
            child: _buildGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'You are not enrolled in any courses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Explore our course catalog to get started',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildGlassButton(
                      onPressed: () => context.go('/dashboard/courses'),
                      backgroundColor: const Color(0xFF38BDF8),
                      child: Text(
                        'Browse Courses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Show course selection screen if no course is selected
    if (_selectedCourseId == null) {
      return Container(
        decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Select Course',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                // Call the callback to navigate to home tab (index 0)
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(0);
                }
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Courses',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a course to view its modules',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: dashboardProvider.enrolledCourses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final course = dashboardProvider.enrolledCourses[index];

                      return _buildGlassCard(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                _loadModulesForCourse(course.id!, course.title),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38BDF8)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF38BDF8)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.school,
                                      color: const Color(0xFF38BDF8),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          course.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to view modules',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: const Color(0xFF38BDF8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If we're loading modules for selected course
    if (_isLoadingModules) {
      return Container(
        decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              _selectedCourseTitle ?? 'Modules',
              style: const TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _clearSelection,
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF38BDF8)),
                const SizedBox(height: 20),
                Text(
                  'Loading modules for $_selectedCourseTitle...',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If there's an error
    if (_error != null) {
      return Container(
        decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              _selectedCourseTitle ?? 'Modules',
              style: const TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _clearSelection,
            ),
          ),
          body: Center(
            child: _buildGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Failed to load modules',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGlassButton(
                          onPressed: () => _loadModulesForCourse(
                              _selectedCourseId!, _selectedCourseTitle!),
                          backgroundColor: const Color(0xFF38BDF8),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildGlassButton(
                          onPressed: _clearSelection,
                          isOutlined: true,
                          child: Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // If no modules loaded for selected course
    if (_modules.isEmpty) {
      return Container(
        decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              _selectedCourseTitle ?? 'Modules',
              style: const TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _clearSelection,
            ),
            actions: [
              IconButton(
                onPressed: () => _loadModulesForCourse(
                    _selectedCourseId!, _selectedCourseTitle!),
                icon: Icon(
                  Icons.refresh,
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          body: Center(
            child: _buildGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 64,
                      color: _greyWithOpacity(0.7),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No modules available yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Modules will appear here once they\'re added to the course',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGlassButton(
                          onPressed: () => _loadModulesForCourse(
                              _selectedCourseId!, _selectedCourseTitle!),
                          backgroundColor: const Color(0xFF38BDF8),
                          child: Text(
                            'Refresh',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildGlassButton(
                          onPressed: _clearSelection,
                          isOutlined: true,
                          child: Text(
                            'Back to Courses',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Show modules for selected course
    return Container(
      decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _selectedCourseTitle ?? 'Modules',
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _clearSelection,
          ),
          actions: [
            IconButton(
              onPressed: () => _loadModulesForCourse(
                  _selectedCourseId!, _selectedCourseTitle!),
              icon: Icon(
                Icons.refresh,
                color: const Color(0xFF38BDF8),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          backgroundColor: const Color(0xFF38BDF8),
          color: Colors.white,
          onRefresh: () =>
              _loadModulesForCourse(_selectedCourseId!, _selectedCourseTitle!),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Modules',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_modules.length} modules found',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: _modules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final module = _modules[index];
                      final isLocked = module['isLocked'] ?? true;
                      final videos = module['videos'] as List? ?? [];
                      final unlockedVideos =
                          videos.where((v) => !(v['locked'] ?? true)).length;
                      final totalVideos = videos.length;

                      return _buildGlassCard(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (isLocked) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF38BDF8),
                                    content: Text(
                                      'Complete previous modules to unlock "${module['title']}"',
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              final userId = dashboardProvider.currentUserId;
                              if (userId != null) {
                                context.go(
                                  '/dashboard/courses/$_selectedCourseId/module/${module['id']}',
                                  extra: {'userId': userId},
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isLocked
                                          ? _greyWithOpacity(0.1)
                                          : const Color(0xFF38BDF8)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isLocked
                                            ? _greyWithOpacity(0.3)
                                            : const Color(0xFF38BDF8)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Icon(
                                      isLocked
                                          ? Icons.lock_outline
                                          : Icons.play_circle_outline,
                                      color: isLocked
                                          ? _greyWithOpacity(0.7)
                                          : const Color(0xFF38BDF8),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          module['title'] ?? 'Untitled Module',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: isLocked
                                                ? _greyWithOpacity(0.7)
                                                : Colors.white,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isLocked
                                              ? 'Locked'
                                              : '${module['videoCount'] ?? 0} videos',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isLocked
                                                ? _greyWithOpacity(0.7)
                                                : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: isLocked
                                        ? _greyWithOpacity(0.5)
                                        : const Color(0xFF38BDF8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}