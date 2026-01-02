import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/assessment_provider.dart';
// Remove the incorrect import
// import '../../providers/dashboard_provider.dart_provider.dart';

class AssessmentResultScreen extends StatefulWidget {
  final String assessmentId;

  const AssessmentResultScreen({
    super.key,
    required this.assessmentId,
  });

  @override
  State<AssessmentResultScreen> createState() => _AssessmentResultScreenState();
}

class _AssessmentResultScreenState extends State<AssessmentResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _celebrationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Map<String, dynamic>? _result;
  bool _isLoading = true;
  String? _error;
  Timer? _autoNavigateTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadResult();
  }

  void _setupAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.elasticOut,
    ));

    _mainAnimationController.forward();
  }

  Future<void> _loadResult() async {
    try {
      final assessmentProvider = context.read<AssessmentProvider>();

      // Try to get result from provider first
      if (assessmentProvider.lastAssessmentResult != null) {
        _result = assessmentProvider.lastAssessmentResult;
        _handleResult();
      } else {
        // Fallback: Fetch result from backend
        final assessmentId = int.tryParse(widget.assessmentId);
        if (assessmentId != null) {
          _result = await assessmentProvider.getAssessmentStatus(assessmentId);
          _handleResult();
        } else {
          setState(() {
            _error = 'Invalid assessment ID';
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load result: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _handleResult() {
    if (_result == null) return;

    final bool passed = _result!['passed'] ?? false;
    final bool nextModuleUnlocked = _result!['nextModuleUnlocked'] ?? false;

    // Trigger celebration for passed results
    if (passed && _celebrationController.status == AnimationStatus.dismissed) {
      _celebrationController.forward();
    }

    // If next module unlocked, show success message
    if (nextModuleUnlocked && passed) {
      // Show success message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Next module unlocked! You can now continue learning.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Auto-navigate after 5 seconds if user passed and next module unlocked
        if (passed && nextModuleUnlocked) {
          _autoNavigateTimer = Timer(Duration(seconds: 5), () {
            if (mounted) {
              _goToNextModule();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // Clear stored result when leaving screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final assessmentProvider = context.read<AssessmentProvider>();
      assessmentProvider.clearLastResult();
    });

    _autoNavigateTimer?.cancel();
    _mainAnimationController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading results...', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                SizedBox(height: 16),
                Text(
                  'Error Loading Results',
                  style: theme.textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadResult,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_result == null) {
      return Scaffold(
        body: Center(
          child: Text('No result data available'),
        ),
      );
    }

    // Extract result data
    final bool passed = _result!['passed'] ?? false;
    final bool nextModuleUnlocked = _result!['nextModuleUnlocked'] ?? false;
    final double percentage = (_result!['percentage'] ?? 0.0).toDouble();
    final int obtainedMarks = (_result!['obtainedMarks'] ?? 0).toInt();
    final int totalMarks = (_result!['totalMarks'] ?? 0).toInt();
    final String message = _result!['message'] ?? '';
    final String assessmentTitle = _result!['assessmentTitle'] ?? 'Assessment';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _mainAnimationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: _buildResultContent(
                  context,
                  theme,
                  passed: passed,
                  nextModuleUnlocked: nextModuleUnlocked,
                  percentage: percentage,
                  obtainedMarks: obtainedMarks,
                  totalMarks: totalMarks,
                  message: message,
                  assessmentTitle: assessmentTitle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultContent(
      BuildContext context,
      ThemeData theme, {
        required bool passed,
        required bool nextModuleUnlocked,
        required double percentage,
        required int obtainedMarks,
        required int totalMarks,
        required String message,
        required String assessmentTitle,
      }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header section
            ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                children: [
                  // Result icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: passed
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: passed
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        child: Icon(
                          passed
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      if (passed)
                        AnimatedBuilder(
                          animation: _celebrationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_celebrationController.value * 0.3),
                              child: Opacity(
                                opacity: 1.0 - _celebrationController.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.success,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Assessment title
                  Text(
                    assessmentTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Result status
                  Text(
                    passed ? 'Congratulations!' : 'Better Luck Next Time!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: passed
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Custom message based on result
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Next module unlocked badge
                  if (nextModuleUnlocked) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.success,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_open,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Next Module Unlocked!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Score display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Score',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Score circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 12,
                          backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                          color: percentage >= 70
                              ? AppColors.success
                              : percentage >= 50
                              ? AppColors.warning
                              : AppColors.error,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$obtainedMarks/$totalMarks',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Passing requirement
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        percentage >= 70 ? Icons.check_circle : Icons.cancel,
                        color: percentage >= 70 ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Passing Requirement: ≥70%',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Column(
              children: [
                if (passed && nextModuleUnlocked) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _goToNextModule,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue to Next Module'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Auto-navigating in 5 seconds...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (!passed)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _retakeAssessment,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _goToDashboard,
                    icon: const Icon(Icons.home),
                    label: const Text('Back to Dashboard'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Footer info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your assessment results are automatically saved. You can view them anytime from your profile.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToNextModule() {
    // Cancel auto-navigation timer
    _autoNavigateTimer?.cancel();

    // Navigate to the next module (adjust based on your app structure)
    // Since you don't have CourseProvider, you can navigate to the course/modules screen
    // or refresh the course data by navigating to dashboard and then back to course
    context.go('/dashboard');

    // Show a message that next module is available
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Next module is now available in your course!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _retakeAssessment() {
    // Cancel auto-navigation timer
    _autoNavigateTimer?.cancel();

    // Go back to assessment screen
    context.pushReplacement(
      '/dashboard/assessment/question/${widget.assessmentId}',
    );
  }

  void _goToDashboard() {
    // Cancel auto-navigation timer
    _autoNavigateTimer?.cancel();

    // Clear result and go to dashboard
    context.read<AssessmentProvider>().clearLastResult();
    context.go('/dashboard');
  }
}