// new_user_dashboard_screen.dart - COMPLETE FIXED VERSION
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/dashboard_provider.dart';

/// Gradient background constants from login screen
const LinearGradient _kDashboardBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF020617),
    Color(0xFF0F172A),
  ],
);

/// Helper functions for transparent colors
Color _whiteWithOpacity(double opacity) {
  return Color.fromRGBO(255, 255, 255, opacity);
}

Color _blueWithOpacity(double opacity) {
  return Color.fromRGBO(56, 189, 248, opacity);
}

class NewUserDashboardScreen extends StatefulWidget {
  const NewUserDashboardScreen({super.key});

  @override
  State<NewUserDashboardScreen> createState() => _NewUserDashboardScreenState();
}

class _NewUserDashboardScreenState extends State<NewUserDashboardScreen> {
  bool _hasLoadedInitialData = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    print('🆕 NewUserDashboard: INIT called');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    print('🆕 NewUserDashboard: didChangeDependencies called');

    // Load data once when dependencies are ready
    if (!_hasLoadedInitialData) {
      _hasLoadedInitialData = true;
      final dashboardProvider = Provider.of<DashboardProvider>(
        context,
        listen: false,
      );

      // Only load if no data exists
      if (dashboardProvider.availableCourses.isEmpty &&
          !dashboardProvider.isLoadingUser) {
        print('🆕 NewUserDashboard: Loading initial data');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          dashboardProvider.loadUserDashboard();
        });
      } else {
        print('🆕 NewUserDashboard: Data already loaded, skipping');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    print('🆕 NewUserDashboard: BUILD called');

    return Container(
      decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Discover Amazing Courses',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _whiteWithOpacity(0.08),
              border: Border.all(color: _whiteWithOpacity(0.12)),
            ),
            child: IconButton(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _whiteWithOpacity(0.08),
                border: Border.all(color: _whiteWithOpacity(0.12)),
              ),
              child: IconButton(
                onPressed: () => context.push('/dashboard/profile'),
                icon: const Icon(Icons.account_circle, color: Colors.white),
              ),
            ),
          ],
        ),
        body: Consumer<DashboardProvider>(
          builder: (context, dashboardProvider, child) {
            print('🆕 NewUserDashboard: Consumer BUILD - Loading: ${dashboardProvider.isLoadingUser}');

            return _DashboardContent(
              dashboardProvider: dashboardProvider,
              onRefresh: () => _handleRefresh(context),
              isRefreshing: _isRefreshing,
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    if (_isRefreshing) return;

    print('🔄 NewUserDashboard: Manual refresh triggered');
    setState(() => _isRefreshing = true);

    try {
      final dashboardProvider = Provider.of<DashboardProvider>(
        context,
        listen: false,
      );
      await dashboardProvider.loadUserDashboard();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardProvider dashboardProvider;
  final Future<void> Function() onRefresh;
  final bool isRefreshing;

  const _DashboardContent({
    required this.dashboardProvider,
    required this.onRefresh,
    required this.isRefreshing,
  });

  Widget _buildGlassCard({required Widget child, double opacity = 0.08}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, opacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.fromRGBO(255, 255, 255, 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(56, 189, 248, 0.15),
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

  @override
  Widget build(BuildContext context) {
    // Handle loading state
    if (dashboardProvider.isLoadingUser && !isRefreshing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF38BDF8)),
            SizedBox(height: 16),
            Text(
              'Loading your personalized dashboard...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (dashboardProvider.userError != null) {
      return Center(
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
                const SizedBox(height: 16),
                Text(
                  'Failed to load dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    dashboardProvider.userError!,
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRefresh,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.black,
                    elevation: 12,
                    shadowColor: const Color(0xFF38BDF8).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final availableCourses = dashboardProvider.availableCourses;
    if (availableCourses.isEmpty) {
      return Center(
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: const Color(0xFF38BDF8),
                ),
                const SizedBox(height: 16),
                Text(
                  'No courses available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new courses',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRefresh,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    print('✅ NewUserDashboard: Rendering ${availableCourses.length} courses');

    return RefreshIndicator(
      backgroundColor: const Color(0xFF38BDF8),
      color: Colors.white,
      onRefresh: onRefresh,
      child: _buildDashboardContent(context, availableCourses),
    );
  }

  Widget _buildDashboardContent(BuildContext context,
      List<dynamic> availableCourses) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Message
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildGlassCard(
              opacity: 0.1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Your Learning Journey! 🚀',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start with our recommended courses below or explore by category.',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Available Courses Section
          if (availableCourses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Start Your Learning Journey',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: availableCourses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final course = availableCourses[index];
                  return _buildCourseCard(context, course);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Browse Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browse by Category',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    'Mobile Development',
                    'Web Development',
                    'Data Science',
                    'AI & Machine Learning',
                    'Cloud Computing',
                    'DevOps'
                  ].map((category) =>
                      _buildCategoryChip(context, category)).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassCard(
                        child: InkWell(
                          onTap: () => context.push('/dashboard/courses'),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.explore,
                                  size: 32,
                                  color: const Color(0xFF38BDF8),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Browse All Courses',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGlassCard(
                        child: InkWell(
                          onTap: () => context.push('/dashboard/assessment'),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.quiz,
                                  size: 32,
                                  color: const Color(0xFF38BDF8),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Take Assessment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, dynamic course) {
    return SizedBox(
      width: 280,
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: Image.network(
                    course.thumbnailUrl,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 140,
                        decoration: const BoxDecoration(
                          gradient: _kDashboardBgGradient,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 140,
                        decoration: const BoxDecoration(
                          gradient: _kDashboardBgGradient,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 48,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Course Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Course Description
                    Expanded(
                      child: Text(
                        course.description,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Course Metadata
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.library_books,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.totalModules} modules',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course.formattedDuration,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            context.push('/dashboard/courses/${course.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.black,
                          elevation: 8,
                          shadowColor: const Color(0xFF38BDF8).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          course.isSubscribed ? 'Continue Learning' : 'View Course',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String category) {
    return InkWell(
      onTap: () =>
          context.push(
              '/dashboard/courses?category=${Uri.encodeComponent(category)}'),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.08),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Color.fromRGBO(255, 255, 255, 0.12),
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}