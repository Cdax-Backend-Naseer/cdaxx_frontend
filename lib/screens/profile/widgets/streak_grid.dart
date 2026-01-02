// lib/features/profile/widgets/streak_grid.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cdax_app/providers/streak_provider.dart';
import 'package:cdax_app/providers/user_provider.dart';

import '../../../models/streak_model.dart';
import '../../../services/api_service.dart';

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

      if (userId == null) {
        setState(() {
          _loading = false;
          _courses = [];
        });
        return;
      }

      final api = ApiService();
      final response = await api.get<dynamic>(
        '/api/courses/subscribed/$userId',
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final data = response.data as List<dynamic>;
        final coursesList = data.map((course) {
          return {
            'id': course['id']?.toString(),
            'title': course['title'] ?? 'Unknown Course',
          };
        }).toList();

        setState(() {
          _courses = coursesList;
          _loading = false;
        });

        // Auto-select first course if available
        if (_courses.isNotEmpty) {
          _selectedCourseId = _courses.first['id'];
          _selectedCourseTitle = _courses.first['title'];
          _loadStreakData();
        }
      } else {
        setState(() {
          _loading = false;
          _courses = [];
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _courses = [];
      });
    }
  }

  Future<void> _loadStreakData() async {
    if (_selectedCourseId == null) return;

    setState(() {
      _loadingStreak = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.currentUser?.id?.toString();

      if (userId == null) return;

      final api = ApiService();
      final response = await api.get<dynamic>(
        '/api/streak/course/$_selectedCourseId?userId=$userId',
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        setState(() {
          _streakData = response.data as Map<String, dynamic>;
          _loadingStreak = false;
        });
      } else {
        setState(() {
          _streakData = null;
          _loadingStreak = false;
        });
      }
    } catch (e) {
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
            _buildStreakContent()
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

    // Count active days
    int activeDays = 0;
    for (var day in last30Days) {
      if (day['isActiveDay'] == true) activeDays++;
    }

    return GestureDetector(
      onTap: () => _showStreakDetails(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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

          // Mini grid preview (shows current month)
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

          // Tap hint
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
      ),
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
        title: Text(courseTitle, style: TextStyle(color: Colors.white)),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Full 30-day grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.2,
                ),
                itemCount: 30,
                itemBuilder: (context, index) {
                  if (index >= last30Days.length) return Container();

                  final day = last30Days[index];
                  final date = DateTime.parse(day['date']);
                  final isActive = day['isActiveDay'] == true;
                  final progress = day['progressPercentage'] ?? 0.0;
                  final watchedSeconds = day['watchedSeconds'] ?? 0;

                  Color getColor() {
                    if (!isActive) return Colors.white.withOpacity(0.08);
                    if (progress < 25) return Color(0xFFFEF3C7);
                    if (progress < 50) return Color(0xFFFDE68A);
                    if (progress < 75) return Color(0xFFFBBF24);
                    if (progress < 100) return Color(0xFFF59E0B);
                    return Color(0xFF10B981);
                  }

                  return Tooltip(
                    message: '${date.day}/${date.month}\nProgress: ${progress.toStringAsFixed(0)}%\nWatched: ${_formatDuration(watchedSeconds)}',
                    child: Container(
                      decoration: BoxDecoration(
                        color: getColor(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 12,
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

              // Legend
              Wrap(
                spacing: 12,
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