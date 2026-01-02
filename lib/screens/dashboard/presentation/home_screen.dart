import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../models/dashboard/dashboard_stats_model.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/dashboard_provider.dart';
import 'new_user_dashboard_screen.dart';

/// Gradient background constants from login screen
const LinearGradient _kDashboardBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF020617), // Rich dark blue/navy
    Color(0xFF0F172A), // Slightly lighter dark blue
  ],
);

/// HomeScreen
class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key,this.onNavigateToTab,});


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen: Initializing with conditional dashboard logic');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final dashboardProvider = context.read<DashboardProvider>();

      if (userProvider.isAuthenticated && userProvider.currentUser != null) {
        final userId = userProvider.currentUser!.id;
        print('🏠 HomeScreen: Loading dashboard for authenticated user: $userId');
        dashboardProvider.loadUserDashboard();
      } else {
        print('❌ HomeScreen: User not authenticated, redirecting to login');
        Future.microtask(() {
          context.go('/login');
        });
      }
    });
  }

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

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color.fromRGBO(color.red, color.green, color.blue, 0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(color.red, color.green, color.blue, 0.2),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, DashboardProvider>(
      builder: (context, userProvider, dashboardProvider, child) {
        print('🏠 HomeScreen: Building UI - Auth: ${userProvider.isAuthenticated}, Loading: ${dashboardProvider.isLoadingUser}');

        // Handle unauthenticated users
        if (!userProvider.isAuthenticated) {
          print('❌ HomeScreen: User not authenticated');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return Container(
            decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
            ),
          );
        }

        // Handle loading state
        if (dashboardProvider.isLoadingUser) {
          print('🏠 HomeScreen: Loading user dashboard data');
          return Container(
            decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF38BDF8)),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your dashboard...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Handle error state
        if (dashboardProvider.userError != null) {
          print('❌ HomeScreen: Dashboard error: ${dashboardProvider.userError}');
          return Container(
            decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
            child: Center(
              child: _buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
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
                      Text(
                        dashboardProvider.userError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          print('🏠 HomeScreen: User tapped retry');
                          dashboardProvider.loadUserDashboard();
                        },
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
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final userCourses = dashboardProvider.userCourses;
        if (userCourses == null) {
          print('⚠️ HomeScreen: No course data available');
          return Container(
            decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
            child: Center(
              child: _buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No course data available',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // Conditional Dashboard Logic
        bool isNewUser = userProvider.currentUser?.isNewUser ?? true;
        print('🏠 HomeScreen: User is new user: $isNewUser');

        if (isNewUser) {
          print('🆕 HomeScreen: Showing NewUserDashboard (user marked as new)');
          return const NewUserDashboardScreen();
        }

        print('👤 HomeScreen: Showing ExistingUserDashboard (has enrollment history)');
        return _buildExistingUserDashboard(context, userProvider, dashboardProvider);
      },
    );
  }

  Widget _buildExistingUserDashboard(BuildContext context, UserProvider userProvider, DashboardProvider dashboardProvider) {
    final enrolledCourses = dashboardProvider.enrolledCourses;
    final availableCourses = dashboardProvider.availableCourses;
    final stats = dashboardProvider.dashboardStats;

    return Container(
      decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                  height: 1.2, // Better line spacing
                ),
              ),
              Text(
                userProvider.currentUser?.firstName ?? 'Student',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0, // Better line spacing
                ),
              ),
            ],
          ),
          actions: [
            // Notification Icon (only if it was there before - keeping minimal)
            IconButton(
              onPressed: () {},
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(255, 255, 255, 0.08),
                  border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.12)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Profile Icon - Right side
            IconButton(
              onPressed: () => context.go('/dashboard/profile'),
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(255, 255, 255, 0.08),
                  border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.12)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.account_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          backgroundColor: const Color(0xFF38BDF8),
          color: Colors.white,
          onRefresh: () {
            print('👤 ExistingUserDashboard: User pulled to refresh');
            return context.read<DashboardProvider>().loadUserDashboard();
          },
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashboard Summary Stats - Glass Card
                  _buildGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Row with Dropdown - FIXED NESTING
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Progress',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              // Course Selection Dropdown
                              if (stats?.courseStats.isNotEmpty ?? false)
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(left: 16),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(255, 255, 255, 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Color.fromRGBO(255, 255, 255, 0.2),
                                      ),
                                    ),
                                    child: DropdownButton<int?>(
                                      value: stats?.selectedCourseId,
                                      hint: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          'All Courses',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      icon: Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Icon(
                                          Icons.arrow_drop_down,
                                          color: const Color(0xFF38BDF8),
                                          size: 20,
                                        ),
                                      ),
                                      elevation: 16,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      underline: Container(height: 0),
                                      dropdownColor: const Color(0xFF0F172A),
                                      isExpanded: true,
                                      menuMaxHeight: 300,
                                      onChanged: (int? newValue) {
                                        if (newValue != null) {
                                          print('🎯 User selected course: $newValue');
                                          dashboardProvider.selectCourseForStats(newValue);
                                        } else {
                                          dashboardProvider.loadDashboardStats();
                                        }
                                      },
                                      items: [
                                        DropdownMenuItem<int?>(
                                          value: null,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Text(
                                              'All Courses',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                        ...stats!.courseStats.map((course) {
                                          return DropdownMenuItem<int?>(
                                            value: course.courseId,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Text(
                                                course.courseTitle,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                'Courses',
                                stats?.selectedCourseStat != null ? '1' : (stats?.totalCourses?.toString() ?? '0'),
                                Icons.menu_book,
                                const Color(0xFF38BDF8),
                              ),

                              _buildStatItem(
                                context,
                                'In Progress',
                                stats?.selectedCourseStat != null
                                    ? (stats!.selectedCourseStat!.isCompleted ? '0' : '1')
                                    : (stats?.inProgressCourses?.toString() ?? '0'),
                                Icons.play_circle,
                                const Color(0xFF22D3EE),
                              ),

                              _buildStatItem(
                                context,
                                'Videos',
                                stats?.selectedCourseStat != null
                                    ? '${stats!.selectedCourseStat!.completedVideos}/${stats!.selectedCourseStat!.totalVideos}'
                                    : (stats != null ? '${stats!.completedVideos}/${stats!.totalVideos}' : '0/0'),
                                Icons.video_collection,
                                Colors.white,
                              ),

                              _buildStatItem(
                                context,
                                'Progress',
                                stats?.selectedCourseStat != null
                                    ? '${stats!.selectedCourseStat!.progressPercent}%'
                                    : (stats?.overallProgress?.toString() != null ? '${stats!.overallProgress}%' : '0%'),
                                Icons.emoji_events,
                                Colors.amber[600]!,
                              ),
                            ],
                          ),

                          // Show selected course name if a course is selected
                          if (stats?.selectedCourseStat != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Row(
                                children: [
                                  Icon(Icons.school, size: 16, color: const Color(0xFF38BDF8)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Showing: ${stats!.selectedCourseStat!.courseTitle}',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      dashboardProvider.loadDashboardStats();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Show All',
                                      style: TextStyle(
                                        color: const Color(0xFF38BDF8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Your Enrolled Courses Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Courses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go(
                            '/dashboard/courses',
                            extra: {
                              'showSubscribedOnly': true,
                            },
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: const Color(0xFF38BDF8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: enrolledCourses.isEmpty
                        ? Center(
                      child: _buildGlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 48,
                                color: Colors.white70,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No enrolled courses yet',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Explore courses to get started',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        : ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: enrolledCourses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final course = enrolledCourses[index];
                        print('👤 ExistingUserDashboard: Rendering enrolled course: ${course.title}');

                        CourseStat? courseStats;
                        if (stats?.courseStats != null) {
                          try {
                            courseStats = stats!.courseStats.firstWhere(
                                  (stat) => stat.courseId.toString() == course.id.toString(),
                            );
                          } catch (e) {
                            courseStats = null;
                          }
                        }

                        return _buildEnrolledCourseCard(context, course, courseStats);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Available Courses Section
                  if (availableCourses.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Explore More Courses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/dashboard/courses');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: const Color(0xFF38BDF8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableCourses.take(3).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final course = availableCourses[index];
                          return _buildAvailableCourseCard(context, course);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Assessment Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Test Your Skills',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/dashboard/assessment');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: const Color(0xFF38BDF8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGlassCard(
                    child: InkWell(
                      onTap: () {
                        context.push('/dashboard/assessment');
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(56, 189, 248, 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color.fromRGBO(56, 189, 248, 0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.quiz,
                                color: const Color(0xFF38BDF8),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Take Assessments',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Test your knowledge with skill assessments',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: const Color(0xFF38BDF8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnrolledCourseCard(BuildContext context, dynamic course, CourseStat? courseStats) {
    // ✅ FIX: Use null-aware operators and provide defaults
    final progressPercent = courseStats?.progressPercent ?? course.progressPercent?.round() ?? 0;
    final totalVideos = courseStats?.totalVideos ?? course.totalVideos ?? 0;
    final completedVideos = courseStats?.completedVideos ?? course.completedVideos ?? 0;
    final totalModules = courseStats?.totalModules ?? course.totalModules ?? 0;
    final completedModules = courseStats?.completedModules ??
        (course.modules?.where((m) => !m.isLocked)?.length ?? 0);
    final displayModules = '$completedModules/$totalModules modules';

    return SizedBox(
      width: 260,
      child: _buildGlassCard(
        child: InkWell(
          onTap: () {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final currentUserId = userProvider.currentUser?.id?.toString();

            context.go(
              '/dashboard/courses/${course.id}',
              extra: {
                'userId': currentUserId,
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      course.thumbnailUrl ?? '',
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF020617), Color(0xFF0F172A)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 40,
                            color: Color.fromRGBO(255, 255, 255, 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(56, 189, 248, 0.8),
                            Color.fromRGBO(34, 211, 238, 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title ?? 'Untitled Course',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(
                          completedModules > 0 ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayModules,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(
                          Icons.video_library,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completedVideos/$totalVideos videos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Color.fromRGBO(255, 255, 255, 0.1),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: (progressPercent / 100) * 228,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFF22D3EE)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '$progressPercent%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableCourseCard(BuildContext context, dynamic course) {
    return SizedBox(
      width: 300,
      child: _buildGlassCard(
        child: InkWell(
          onTap: () {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final currentUserId = userProvider.currentUser?.id?.toString();

            context.go(
              '/dashboard/courses/${course.id}',
              extra: {
                'userId': currentUserId,
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color.fromRGBO(255, 255, 255, 0.12),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: const Color(0xFF38BDF8),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title ?? 'Untitled Course',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Explore this course',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color.fromRGBO(255, 255, 255, 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: const Color(0xFF38BDF8),
                    size: 16,
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