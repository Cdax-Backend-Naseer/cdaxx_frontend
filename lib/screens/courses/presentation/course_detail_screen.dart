import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../factories/course_repository_factory.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../courses/data/models/module.dart';
import '../../courses/presentation/module_row.dart';
import '../data/course_repository.dart';

/// Same gradient as HomeScreen
const LinearGradient _kDashboardBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF020617),
    Color(0xFF0F172A),
  ],
);

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.userId,
  });

  final String courseId;
  final String? userId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  CourseRepository? _repo;

  Widget _glassCard({required Widget child, double opacity = 0.08}) {
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
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _repo ??= CourseRepositoryFactory.getInstance(
      context: context,
      userId: widget.userId,
    );

    final asyncCourse = _repo!.getCourseById(widget.courseId);

    return Container(
      decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Course Details',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Consumer<DashboardProvider>(
          builder: (context, dashboardProvider, _) {
            return FutureBuilder(
              future: asyncCourse,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(
                    child: Text(
                      'Failed to load course',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final course = snapshot.data!;
                final stats = dashboardProvider.dashboardStats;

                final courseStats = stats?.courseStats
                    ?.where((s) => s.courseId.toString() == course.id)
                    .toList()
                    .firstOrNull;

                final progressPercent =
                    courseStats?.progressPercent ?? course.progressPercent ?? 0;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    /// Thumbnail
                    GestureDetector(
                      onTap: () {
                        final firstUnlocked = course.modules
                            .firstWhere((m) => !(m.isLocked ?? true),
                            orElse: () => course.modules.first);

                        context.go(
                          '/dashboard/courses/${course.id}/module/${firstUnlocked.id}',
                          extra: {'userId': widget.userId},
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              course.thumbnailUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                Icons.play_arrow,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Course Info
                    _glassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course.description,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Progress: $progressPercent%',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            /// Subscribe / Start Button
                            SizedBox(
                              width: double.infinity,
                              child: course.isSubscribed
                                  ? FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF22C55E),
                                ),
                                onPressed: () {
                                  final firstUnlocked = course.modules
                                      .firstWhere(
                                          (m) => !(m.isLocked ?? true),
                                      orElse: () =>
                                      course.modules.first);

                                  context.go(
                                    '/dashboard/courses/${course.id}/module/${firstUnlocked.id}',
                                    extra: {'userId': widget.userId},
                                  );
                                },
                                child: const Text('Start Learning'),
                              )
                                  : FilledButton.tonal(
                                onPressed: () {
                                  SubscriptionController.instance
                                      .setPurchaseContext(
                                    courseId: course.id,
                                    courseTitle: course.title,
                                    amount: 399.0,
                                  );
                                  context.push(
                                      '/dashboard/subscription/summary');
                                },
                                child: const Text('Buy Course'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Modules
                    Text(
                      'Modules',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...course.modules.map((m) {
                      final isLocked = m.isLocked ?? true;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _glassCard(
                          child: ModuleRow(
                            module: m,
                            titleColor: Colors.white,
                            subtitleColor: Colors.white70,
                            lockedTextColor: const Color(0xFF38BDF8),
                            onPlay: isLocked
                                ? null
                                : () {
                              context.go(
                                '/dashboard/courses/${course.id}/module/${m.id}',
                                extra: {'userId': widget.userId},
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
