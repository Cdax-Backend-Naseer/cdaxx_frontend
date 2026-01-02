import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../factories/course_repository_factory.dart';
import '../application/course_providers.dart' as providers;
import '../../courses/data/models/module.dart';
import '../../../services/assessment_service.dart';
import '../../../models/assessment/assessment_model.dart';

class ModulePlayerScreen extends StatefulWidget {
  const ModulePlayerScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    this.userId,
  });

  final String courseId;
  final String moduleId;
  final String? userId;

  @override
  State<ModulePlayerScreen> createState() => _ModulePlayerScreenState();
}

class _ModulePlayerScreenState extends State<ModulePlayerScreen> {
  List<Assessment> _assessments = [];
  bool _assessmentsLoading = true;
  final AssessmentService _assessmentService = AssessmentService();

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    try {
      final assessments = await _assessmentService.getModuleAssessments(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
      );

      if (mounted) {
        setState(() {
          _assessments = assessments;
          _assessmentsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _assessments = [];
          _assessmentsLoading = false;
        });
      }
    }
  }

  List<Assessment> _getAssessmentsWithModuleLockState(Module module) {
    final hasLockedVideos = module.videos.any((v) => v.isLocked);
    final assessmentLocked = module.isLocked || hasLockedVideos;

    return _assessments.map((assessment) {
      if (assessment.isLocked != assessmentLocked) {
        return Assessment(
          id: assessment.id,
          title: assessment.title,
          category: assessment.category,
          duration: assessment.duration,
          difficulty: assessment.difficulty,
          description: assessment.description,
          totalQuestions: assessment.totalQuestions,
          passingScore: assessment.passingScore,
          isActive: assessment.isActive,
          isLocked: assessmentLocked,
        );
      }
      return assessment;
    }).toList();
  }

  void _navigateToModule(Module module) {
    if (!module.isLocked) {
      context.go(
        '/dashboard/courses/${widget.courseId}/module/${module.id}',
        extra: {'userId': widget.userId},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This module is locked. Purchase course to access.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = CourseRepositoryFactory.getInstance(
      context: context,
      userId: widget.userId,
    );

    return FutureBuilder(
      future: repo.getCourseById(widget.courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF020617),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(backgroundColor: const Color(0xFF0F172A)),
            backgroundColor: const Color(0xFF020617),
            body: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white))),
          );
        }

        final course = snapshot.data;
        if (course == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF020617),
            body: Center(child: Text('Course not found', style: TextStyle(color: Colors.white))),
          );
        }

        Module? module;
        for (final m in course.modules) {
          if (m.id == widget.moduleId) {
            module = m;
            break;
          }
        }
        module ??= course.modules.isNotEmpty ? course.modules.first : null;

        if (module == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Module'), backgroundColor: const Color(0xFF0F172A)),
            backgroundColor: const Color(0xFF020617),
            body: const Center(child: Text('Module not found', style: TextStyle(color: Colors.white))),
          );
        }

        providers.LastPlayedStore.instance.setLastPlayed(widget.courseId, widget.moduleId);
        final currentModule = module;
        final currentIndex = course.modules.indexOf(currentModule);

        return Scaffold(
          backgroundColor: const Color(0xFF020617),
          appBar: AppBar(
            title: Text(currentModule.title),
            backgroundColor: const Color(0xFF0F172A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/dashboard/courses/${widget.courseId}'),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      currentModule.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // Videos
                    ...currentModule.videos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final video = entry.value;

                      return Card(
                        color: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            if (video.isLocked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('This lesson is locked. Purchase course to access.')),
                              );
                              return;
                            }
                            context.go(
                              '/dashboard/courses/${widget.courseId}/module/${widget.moduleId}/video',
                              extra: {
                                'userId': widget.userId,
                                'videoId': video.id,
                                'courseId': widget.courseId,
                                'moduleId': widget.moduleId,
                                'videoUrl': video.videoUrl,
                              },
                            );
                          },
                          leading: Icon(
                            video.isLocked ? Icons.lock : Icons.play_circle_fill,
                            color: video.isLocked ? Colors.white54 : const Color(0xFF38BDF8),
                            size: 28,
                          ),
                          title: Text(
                            video.title.isNotEmpty ? video.title : 'Video ${index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                          ),
                          subtitle: Text(
                            video.durationSec > 0
                                ? '${(video.durationSec / 60).round()} min'
                                : '${(currentModule.durationSec / 60).round()} min',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          trailing: Icon(
                            video.isLocked ? Icons.lock_outline : Icons.play_arrow,
                            color: video.isLocked ? Colors.white38 : Colors.white70,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),
                    const Text(
                      'Assessment',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    if (_assessmentsLoading)
                      const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                    else if (_assessments.isEmpty)
                      const Center(
                        child: Text(
                          'No assessment available for this module',
                          style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      ..._getAssessmentsWithModuleLockState(currentModule).map((assessment) {
                        return Card(
                          color: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () {
                              if (assessment.isLocked) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Complete all videos to unlock assessment')),
                                );
                                return;
                              }
                              context.push(
                                '/dashboard/assessment/question/${assessment.id}',
                                extra: {'userId': widget.userId},
                              );
                            },
                            leading: Icon(
                              assessment.isLocked ? Icons.lock : Icons.quiz,
                              color: assessment.isLocked ? Colors.white54 : const Color(0xFF38BDF8),
                              size: 28,
                            ),
                            title: Text(
                              assessment.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                            ),
                            trailing: Icon(
                              assessment.isLocked ? Icons.lock_outline : Icons.arrow_forward_ios,
                              color: assessment.isLocked ? Colors.white38 : const Color(0xFF38BDF8),
                              size: 16,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),

              // Prev/Next navigation
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF0F172A),
                child: SafeArea(
                  child: Row(
                    children: [
                      if (currentIndex > 0)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToModule(course.modules[currentIndex - 1]),
                            icon: const Icon(Icons.skip_previous),
                            label: const Text('Previous'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      if (currentIndex > 0 && currentIndex < course.modules.length - 1)
                        const SizedBox(width: 12),
                      if (currentIndex < course.modules.length - 1)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToModule(course.modules[currentIndex + 1]),
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Next'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF38BDF8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
