import 'dart:convert';

import 'package:cdax_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../application/profile_provider.dart';
import '../../courses/application/course_providers.dart';
import 'profile_edit_screen.dart';
import 'package:http/http.dart' as http;
import '/config/environment_config.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const ProfileScreen({super.key,this.onNavigateToTab,});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final userEmail = Provider.of<UserProvider>(context, listen: false)
        .currentUser!
        .email;
    Provider.of<ProfileProvider>(context, listen: false).fetchProfile(userEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profile = profileProvider.profile;
        final initials = profile.name.isNotEmpty
            ? profile.name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            : '?';

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Dark theme background
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Profile',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: profileProvider.isLoading
                    ? null
                    : () async {
                  final updated = await Navigator.of(context)
                      .push<UserProfile>(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProfileEditScreen(initial: profile),
                    ),
                  );
                  if (updated != null && mounted) {
                    await profileProvider.updateProfile(updated);
                  }
                },
                child: const Text('✏️', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(initials, style: const TextStyle(color: Colors.white)),
                    backgroundColor: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        Text(profile.email,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white70)),
                        Text(profile.phone,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      profile.subscribed ? 'Pro' : 'Free',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: profile.subscribed
                        ? const Color(0xFF22C55E)
                        : Colors.grey.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF1E293B),
                child: ListTile(
                  leading: const Icon(Icons.school, color: Colors.white),
                  title: const Text('Enrolled courses',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => const _EnrolledCoursesSheet(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text('Streak',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                    ),
                  );
                },
                child: _StreakGrid(),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF1E293B),
                child: Column(
                  children: [
                    const Divider(height: 1, color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.white),
                      title:
                      const Text('Settings', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings coming soon')),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.menu_book, color: Colors.white),
                      title: const Text('Courses', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () => context.push('/dashboard/courses'),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    ListTile(
                      leading:
                      const Icon(Icons.workspace_premium, color: Colors.white),
                      title: const Text('Certifications',
                          style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () => context.push('/dashboard/certifications'),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.credit_card, color: Colors.white),
                      title:
                      const Text('Payment', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () => context.push('/dashboard/subscription/methods'),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.work, color: Colors.white),
                      title:
                      const Text('Placement', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () => context.push('/dashboard/placement/eligibility'),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip, color: Colors.white),
                      title:
                      const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Privacy Policy coming soon')),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white),
                      title: const Text('Logout', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                      onTap: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: const Color(0xFF1E293B),
                              title: const Text('Logout', style: TextStyle(color: Colors.white)),
                              content: const Text(
                                'Are you sure you want to logout?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            );
                          },
                        );

                        if (shouldLogout == true && context.mounted) {
                          final userProvider =
                          Provider.of<UserProvider>(context, listen: false);
                          try {
                            await userProvider.logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Logout failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StreakGrid extends StatefulWidget {
  @override
  State<_StreakGrid> createState() => _StreakGridState();
}

class _StreakGridState extends State<_StreakGrid> {
  Map<String, dynamic>? _streakData;
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;
  bool _loadingStreak = false;
  String? _selectedCourseId;
  String? _selectedCourseTitle;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.currentUser?.id?.toString();

      print('DEBUG: User ID = $userId');

      if (userId == null) {
        print('DEBUG: User ID is null');
        setState(() {
          _loading = false;
          _courses = [];
        });
        return;
      }

      // Try direct HTTP call instead of ApiService
      final url = Uri.parse('${EnvironmentConfig.baseUrl}/api/courses/subscribed/$userId');
      print('DEBUG: Calling URL = $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Status Code = ${response.statusCode}');
      print('DEBUG: Response Body = ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        print('DEBUG: Parsed ${data.length} courses');

        final coursesList = data.map((course) {
          return {
            'id': course['id']?.toString() ?? '',
            'title': course['title']?.toString() ?? 'Unknown Course',
          };
        }).where((c) => c['id']!.isNotEmpty).toList();

        print('DEBUG: Final courses list = $coursesList');

        setState(() {
          _courses = coursesList;
          _loading = false;
        });

        // Auto-select first course
        if (_courses.isNotEmpty) {
          _selectedCourseId = _courses.first['id'];
          _selectedCourseTitle = _courses.first['title'];
          print('DEBUG: Auto-selected course ${_selectedCourseId}');
          _loadStreakData();
        }
      } else {
        print('DEBUG: HTTP Error ${response.statusCode}');
        setState(() {
          _loading = false;
          _courses = [];
        });
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error loading courses: $e');
      print('DEBUG: Stack trace: $stackTrace');
      setState(() {
        _loading = false;
        _courses = [];
      });
    }
  }

  Future<void> _loadStreakData() async {
    if (_selectedCourseId == null) {
      print('DEBUG STREAK: No course selected');
      return;
    }

    setState(() {
      _loadingStreak = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.currentUser?.id?.toString();

      print('DEBUG STREAK: User ID = $userId');
      print('DEBUG STREAK: Course ID = $_selectedCourseId');

      if (userId == null) {
        print('DEBUG STREAK: User ID is null');
        setState(() {
          _streakData = null;
          _loadingStreak = false;
        });
        return;
      }

      // Direct HTTP call for streak data
      final url = Uri.parse(
          '${EnvironmentConfig.baseUrl}/api/streak/course/$_selectedCourseId?userId=$userId'
      );
      print('DEBUG STREAK: Calling URL = $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG STREAK: Status Code = ${response.statusCode}');
      print('DEBUG STREAK: Response Body = ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('DEBUG STREAK: Parsed data keys = ${data.keys}');

        setState(() {
          _streakData = data;
          _loadingStreak = false;
        });

        print('DEBUG STREAK: Successfully loaded streak data');
      } else {
        print('DEBUG STREAK: HTTP Error ${response.statusCode}');
        setState(() {
          _streakData = null;
          _loadingStreak = false;
        });
      }
    } catch (e, stackTrace) {
      print('DEBUG STREAK: Error loading streak: $e');
      print('DEBUG STREAK: Stack trace: $stackTrace');
      setState(() {
        _streakData = null;
        _loadingStreak = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, color: Colors.white70, size: 40),
              SizedBox(height: 12),
              Text(
                'No enrolled courses',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 4),
              Text(
                'Enroll in courses to track your streak',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course dropdown
          DropdownButtonFormField<String>(
            value: _selectedCourseId,
            decoration: InputDecoration(
              labelText: 'Select Course',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF38BDF8)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Color(0xFF0F172A),
            ),
            dropdownColor: Color(0xFF1E293B),
            style: TextStyle(color: Colors.white, fontSize: 14),
            items: _courses.map((course) {
              return DropdownMenuItem<String>(
                value: course['id'],
                child: Text(
                  course['title'],
                  style: TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCourseId = value;
                _selectedCourseTitle = _courses.firstWhere(
                      (c) => c['id'] == value,
                  orElse: () => {'title': 'Selected Course'},
                )['title'];
                _streakData = null;
              });
              _loadStreakData();
            },
          ),

          SizedBox(height: 16),

          // Streak content
          if (_loadingStreak)
            Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          else if (_streakData != null)
            GestureDetector(
              onTap: () => _showStreakDetails(context),
              child: _buildStreakContent(),
            )
          else if (_selectedCourseId != null)
              _buildEmptyStreak(),
        ],
      ),
    );
  }

  Widget _buildStreakContent() {
    final courseTitle = _streakData!['courseTitle'] ?? _selectedCourseTitle ?? 'Course';
    final currentStreak = _streakData!['currentStreakDays'] ?? 0;
    final overallProgress = _streakData!['overallProgress'] ?? 0.0;
    final last30Days = _streakData!['last30Days'] as List<dynamic>? ?? [];

    int activeDays = 0;
    for (var day in last30Days) {
      if (day['isActiveDay'] == true) activeDays++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '$currentStreak day streak • ${activeDays}/30 active days',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF38BDF8).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${overallProgress.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1.0,
          ),
          itemCount: 30,
          itemBuilder: (context, index) {
            if (index >= last30Days.length) return Container();

            final day = last30Days[index];
            final isActive = day['isActiveDay'] == true;
            final progress = day['progressPercentage'] ?? 0.0;

            Color getColor() {
              if (!isActive) return Colors.white.withOpacity(0.08);
              if (progress < 25) return Color(0xFFFEF3C7);
              if (progress < 50) return Color(0xFFFDE68A);
              if (progress < 75) return Color(0xFFFBBF24);
              if (progress < 100) return Color(0xFFF59E0B);
              return Color(0xFF10B981);
            }

            return Container(
              decoration: BoxDecoration(
                color: getColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),

        SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 14, color: Colors.white70),
            SizedBox(width: 4),
            Text(
              'Tap for detailed view',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyStreak() {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department, color: Colors.white70, size: 40),
            SizedBox(height: 12),
            Text(
              'No streak data yet',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 4),
            Text(
              'Start watching videos to build your streak',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakDetails(BuildContext context) {
    if (_streakData == null) return;

    final courseTitle = _streakData!['courseTitle'] ?? _selectedCourseTitle;
    final last30Days = _streakData!['last30Days'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(courseTitle, style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(height: 4),
            Text(
              'Last 30 Days Activity',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    if (index >= last30Days.length) return Container();

                    final day = last30Days[index];
                    final date = DateTime.parse(day['date']);
                    final isActive = day['isActiveDay'] == true;
                    final progress = day['progressPercentage'] ?? 0.0;

                    Color getColor() {
                      if (!isActive) return Colors.white.withOpacity(0.08);
                      if (progress < 25) return Color(0xFFFEF3C7);
                      if (progress < 50) return Color(0xFFFDE68A);
                      if (progress < 75) return Color(0xFFFBBF24);
                      if (progress < 100) return Color(0xFFF59E0B);
                      return Color(0xFF10B981);
                    }

                    void _showDayDetails(BuildContext context, Map<String, dynamic> dayData) {
                      final date = DateTime.parse(dayData['date']);
                      final isActive = dayData['isActiveDay'] == true;
                      final progress = dayData['progressPercentage'] ?? 0.0;
                      final watchedSeconds = dayData['watchedSeconds'] ?? 0;
                      final videosWatched = dayData['videosWatched'] as List<dynamic>? ?? [];

                      // Month names
                      const months = [
                        'January', 'February', 'March', 'April', 'May', 'June',
                        'July', 'August', 'September', 'October', 'November', 'December'
                      ];

                      Color getDayColor() {
                        if (!isActive) return Colors.white.withOpacity(0.08);
                        if (progress < 25) return Color(0xFFFEF3C7);
                        if (progress < 50) return Color(0xFFFDE68A);
                        if (progress < 75) return Color(0xFFFBBF24);
                        if (progress < 100) return Color(0xFFF59E0B);
                        return Color(0xFF10B981);
                      }
                      String _getColorExplanation(double progress, bool isActive) {
                        if (!isActive) return 'Gray: No activity on this day';
                        if (progress < 25) return 'Light Yellow: 1-25% daily progress';
                        if (progress < 50) return 'Yellow: 25-50% daily progress';
                        if (progress < 75) return 'Orange: 50-75% daily progress';
                        if (progress < 100) return 'Dark Orange: 75-99% daily progress';
                        return 'Green: 100% daily goal achieved! 🎉';
                      }

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF1E293B),
                          title: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: getDayColor(),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Center(
                                  child: Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isActive ? Colors.black87 : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${months[date.month - 1]} ${date.day}, ${date.year}',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                    Text(
                                      isActive ? 'Active Day' : 'No Activity',
                                      style: TextStyle(
                                        color: isActive ? Color(0xFF10B981) : Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          content: Container(
                            width: double.maxFinite,
                            constraints: BoxConstraints(maxHeight: 400),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Progress Summary Card
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Progress',
                                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '${progress.toStringAsFixed(1)}%',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Watch Time',
                                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  _formatDuration(watchedSeconds),
                                                  style: TextStyle(
                                                    color: Color(0xFF38BDF8),
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        LinearProgressIndicator(
                                          value: progress / 100,
                                          backgroundColor: Colors.white.withOpacity(0.1),
                                          valueColor: AlwaysStoppedAnimation<Color>(getDayColor()),
                                          minHeight: 6,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 16),

                                  // Videos Watched Section
                                  if (videosWatched.isNotEmpty) ...[
                                    Text(
                                      'Videos Watched (${videosWatched.length})',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ...videosWatched.map((video) {
                                      final videoTitle = video['title'] ?? 'Unknown Video';
                                      final videoProgress = video['progressPercentage'] ?? 0.0;
                                      final videoWatchedSeconds = video['watchedSeconds'] ?? 0;

                                      return Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.play_circle_outline,
                                                    color: Color(0xFF38BDF8), size: 20),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    videoTitle,
                                                    style: TextStyle(color: Colors.white, fontSize: 13),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${videoProgress.toStringAsFixed(0)}% completed',
                                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                                ),
                                                Text(
                                                  _formatDuration(videoWatchedSeconds),
                                                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            LinearProgressIndicator(
                                              value: videoProgress / 100,
                                              backgroundColor: Colors.white.withOpacity(0.1),
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                                              minHeight: 4,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ] else if (isActive) ...[
                                    Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'No video details available',
                                          style: TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            Icon(Icons.event_busy, color: Colors.white54, size: 40),
                                            SizedBox(height: 8),
                                            Text(
                                              'No activity on this day',
                                              style: TextStyle(color: Colors.white54, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Color Explanation
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: getDayColor().withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: getDayColor().withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: getDayColor(), size: 20),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _getColorExplanation(progress, isActive),
                                            style: TextStyle(color: Colors.white70, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }


                    return InkWell(
                      onTap: () => _showDayDetails(context, day),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: getColor(),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: isActive ? Colors.black87 : Colors.white54,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildLegendItem('0%', Colors.white.withOpacity(0.08)),
                    _buildLegendItem('1-25%', Color(0xFFFEF3C7)),
                    _buildLegendItem('25-50%', Color(0xFFFDE68A)),
                    _buildLegendItem('50-75%', Color(0xFFFBBF24)),
                    _buildLegendItem('75-99%', Color(0xFFF59E0B)),
                    _buildLegendItem('100%', Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}h';
    }
    return '${duration.inMinutes}m';
  }


}
class _EnrolledCoursesSheet extends StatelessWidget {
  const _EnrolledCoursesSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Your enrolled courses',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white)),
            ),
            Expanded(
              child: FutureBuilder(
                future: _loadEnrolled(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  }
                  final courses = snapshot.data as List<_MiniCourse>;
                  if (courses.isEmpty) {
                    return const Center(
                        child: Text('No courses yet', style: TextStyle(color: Colors.white70)));
                  }
                  return ListView.separated(
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, i) {
                      final c = courses[i];
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: NetworkImage(c.thumb)),
                        title: Text(c.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text('Progress ${(c.progress * 100).round()}%',
                            style: const TextStyle(color: Colors.white70)),
                        onTap: () => context.push('/dashboard/courses/${c.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<_MiniCourse>> _loadEnrolled() async {
    final repo = CourseProviders.getCourseRepository();
    final all = await repo.getCourses();
    return all
        .where((c) => c.isSubscribed)
        .map((c) => _MiniCourse(c.id, c.title, c.thumbnailUrl, c.progressPercent))
        .toList();
  }
}

class _MiniCourse {
  _MiniCourse(this.id, this.title, this.thumb, this.progress);
  final String id;
  final String title;
  final String thumb;
  final double progress;
}
