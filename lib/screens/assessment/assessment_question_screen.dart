import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/assessment_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/assessment_service.dart';
import 'widgets/question_card.dart';
import 'widgets/progress_bar.dart';

// Import the UserAnswer class from the correct location
import '../../models/assessment/question_model.dart' as question_models;

class AssessmentQuestionScreen extends StatefulWidget {
  final String assessmentId;
  final String? userId;

  const AssessmentQuestionScreen({
    super.key,
    required this.assessmentId,
    this.userId,
  });

  @override
  State<AssessmentQuestionScreen> createState() => _AssessmentQuestionScreenState();
}

class _AssessmentQuestionScreenState extends State<AssessmentQuestionScreen> {
  Timer? _timer;
  bool _isSubmitting = false;
  final AssessmentService _assessmentService = AssessmentService();

  @override
  void initState() {
    super.initState();
    print('🎯 REAL AssessmentQuestionScreen loaded');
    print('📝 Assessment ID: ${widget.assessmentId}');
    print('👤 Passed User ID: ${widget.userId}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAssessment();
    });
  }

  @override
  void dispose() {
    print('🛑 AssessmentQuestionScreen disposing...');
    _timer?.cancel();

    // Also stop timer in provider if still running
    if (mounted) {
      try {
        final assessmentProvider = Provider.of<AssessmentProvider>(context, listen: false);
        assessmentProvider.stopTimer();
      } catch (e) {
        print('⚠️ Error stopping timer in dispose: $e');
      }
    }

    super.dispose();
  }

  Future<void> _startAssessment() async {
    print('🎯 _startAssessment() CALLED');

    final assessmentProvider = Provider.of<AssessmentProvider>(context, listen: false);
    final assessmentId = int.tryParse(widget.assessmentId);

    if (assessmentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid assessment ID')),
        );
        context.pop();
      }
      return;
    }

    // Set manual user ID if provided
    if (widget.userId != null) {
      print('🎯 Setting manual user ID: ${widget.userId}');
      assessmentProvider.setManualUserId(widget.userId!);
    }

    try {
      // 🆕 Use the startAssessmentWithUserId method directly
      final userId = _getUserId();

      if (userId != null) {
        print('🎯 Starting assessment with userId: $userId, assessmentId: $assessmentId');
        await assessmentProvider.startAssessmentWithUserId(assessmentId, userId);
      } else {
        // Fallback to original method
        print('⚠️ No userId found, using original startAssessment');
        await assessmentProvider.startAssessment(assessmentId);
      }

      if (assessmentProvider.currentAssessment != null && mounted) {
        _startTimer();
      }
    } catch (e) {
      print('❌ Error starting assessment: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start assessment: ${e.toString().split('\n').first}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Helper method to get userId as int
  int? _getUserId() {
    // First try the passed userId
    if (widget.userId != null) {
      final userIdInt = int.tryParse(widget.userId!);
      if (userIdInt != null) {
        print('✅ Using passed userId: $userIdInt');
        return userIdInt;
      }
    }

    // Then try UserProvider
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;
      if (userId != null) {
        final userIdInt = int.tryParse(userId.toString());
        print('✅ Using UserProvider userId: $userIdInt');
        return userIdInt;
      }
    } catch (e) {
      print('⚠️ Error getting UserProvider: $e');
    }

    print('❌ No userId available');
    return null;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final assessmentProvider = Provider.of<AssessmentProvider>(context, listen: false);

      if (!assessmentProvider.isTimerRunning) {
        timer.cancel();
        return;
      }

      final newRemainingTime = Duration(
        seconds: assessmentProvider.remainingTime.inSeconds - 1,
      );

      assessmentProvider.updateTimer(newRemainingTime);

      if (newRemainingTime.inSeconds <= 0) {
        timer.cancel();
        _submitAssessment();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<AssessmentProvider>(
            builder: (context, provider, child) {
              if (provider.currentAssessment == null) {
                return const Text('Assessment');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.currentAssessment!.title,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    'Question ${provider.currentQuestionIndex + 1} of ${provider.totalQuestions}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showExitConfirmation,
          ),
          actions: [
            Consumer<AssessmentProvider>(
              builder: (context, provider, child) {
                if (!provider.isTimerRunning) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: provider.remainingTime.inMinutes < 5
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: provider.remainingTime.inMinutes < 5
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(provider.remainingTime),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: provider.remainingTime.inMinutes < 5
                              ? theme.colorScheme.onErrorContainer
                              : theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<AssessmentProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading assessment...'),
                  ],
                ),
              );
            }

            if (provider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to Load Assessment',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Go Back'),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: _startAssessment,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            if (provider.currentQuestion == null) {
              return const Center(
                child: Text('No questions available'),
              );
            }

            return Column(
              children: [
                AssessmentProgressBar(
                  progress: provider.progress,
                  answeredCount: provider.answeredCount,
                  totalQuestions: provider.totalQuestions,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: QuestionCard(
                      question: provider.currentQuestion!,
                      userAnswer: _convertUserAnswer(provider),
                      onAnswerChanged: (answer) {
                        provider.submitAnswer(answer);
                      },
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: _buildNavigationButtons(provider),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  question_models.UserAnswer? _convertUserAnswer(AssessmentProvider provider) {
    if (provider.currentQuestion == null) return null;

    final providerAnswer = provider.getAnswerForQuestion(provider.currentQuestion!.id);
    if (providerAnswer == null) return null;

    return question_models.UserAnswer(
      questionId: providerAnswer.questionId,
      answer: providerAnswer.answer,
      timestamp: providerAnswer.timestamp,
    );
  }

  Widget _buildNavigationButtons(AssessmentProvider provider) {
    return Row(
      children: [
        if (provider.hasPreviousQuestion)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: provider.goToPreviousQuestion,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
          )
        else
          const Spacer(),

        const SizedBox(width: 16),

        Expanded(
          flex: 2,
          child: _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : FilledButton.icon(
            onPressed: provider.isCurrentQuestionAnswered
                ? () {
              print('🔴 SUBMIT BUTTON PRESSED!');
              _handleNext(provider);
            }
                : null,
            icon: Icon(
              provider.hasNextQuestion
                  ? Icons.arrow_forward
                  : Icons.check,
            ),
            label: Text(
              provider.hasNextQuestion
                  ? 'Next'
                  : 'Submit Assessment',
            ),
          ),
        ),
      ],
    );
  }

  void _handleNext(AssessmentProvider provider) {
    print('🔴 _handleNext() called');
    print('   hasNextQuestion: ${provider.hasNextQuestion}');

    if (provider.hasNextQuestion) {
      print('   Going to next question');
      provider.goToNextQuestion();
    } else {
      print('   Showing submit confirmation');
      _showSubmitConfirmation();
    }
  }

  void _showSubmitConfirmation() {
    print('🔴 _showSubmitConfirmation() CALLED');

    final provider = Provider.of<AssessmentProvider>(context, listen: false);

    print('📊 Assessment stats:');
    print('   answeredCount: ${provider.answeredCount}');
    print('   totalQuestions: ${provider.totalQuestions}');
    print('   remainingTime: ${_formatTime(provider.remainingTime)}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Submit Assessment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to submit your assessment?'),
            const SizedBox(height: 12),
            Text(
              'Answered: ${provider.answeredCount}/${provider.totalQuestions} questions\n'
                  'Remaining time: ${_formatTime(provider.remainingTime)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (provider.answeredCount < provider.totalQuestions) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Warning: You have ${provider.totalQuestions - provider.answeredCount} unanswered questions. These will be marked as incorrect.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ User cancelled submission');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              print('✅ User confirmed submission');
              Navigator.of(context).pop();
              _submitAssessment();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Assessment?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost and you won\'t be able to resume this assessment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exitAssessment();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _exitAssessment() {
    final assessmentProvider = Provider.of<AssessmentProvider>(context, listen: false);
    assessmentProvider.stopTimer();
    assessmentProvider.resetAssessment();
    context.pop();
  }

  Future<void> _submitAssessment() async {
    print('🎯 _submitAssessment() STARTED');
    print('   assessmentId from widget: ${widget.assessmentId}');

    setState(() => _isSubmitting = true);

    try {
      final assessmentProvider = Provider.of<AssessmentProvider>(context, listen: false);
      assessmentProvider.stopTimer();

      print('📤 Step 1: Getting user answers before submission...');

      // DEBUG: Check what answers are being submitted
      final userAnswers = assessmentProvider.userAnswers;
      print('   User answers count: ${userAnswers.length}');

      for (final entry in userAnswers.entries) {
        print('   Q${entry.key}: ${entry.value.answer}');
      }

      print('📤 Step 2: Calling assessmentProvider.submitAssessment()...');

      final Map<String, dynamic> result = await assessmentProvider.submitAssessment();

      print('📥 Step 3: Received result from provider:');
      print('   $result');

      final bool success = result['success'] ?? false;
      final bool passed = result['passed'] ?? false;
      final bool nextModuleUnlocked = result['nextModuleUnlocked'] ?? false;
      final double percentage = (result['percentage'] ?? 0.0).toDouble();
      final int obtainedMarks = (result['obtainedMarks'] ?? 0).toInt();
      final int totalMarks = (result['totalMarks'] ?? 0).toInt();
      final String message = result['message'] ?? '';

      // NEW: Check detailed score breakdown
      final List<dynamic>? questionResults = result['questionResults'] as List<dynamic>?;
      if (questionResults != null) {
        print('📊 Question-by-question results:');
        for (int i = 0; i < questionResults.length; i++) {
          final qResult = questionResults[i];
          print('   Q${i + 1}: ${qResult}');
        }
      }

      print('📊 Step 4: Parsed result:');
      print('   ├─ Success: $success');
      print('   ├─ Passed: $passed');
      print('   ├─ Next Module Unlocked: $nextModuleUnlocked');
      print('   ├─ Percentage: $percentage%');
      print('   ├─ Marks: $obtainedMarks/$totalMarks');
      print('   └─ Message: $message');

      if (!success) {
        throw Exception('Assessment submission failed in provider');
      }

      print('🗺️  Step 5: Attempting navigation...');
      print('   Widget mounted: $mounted');

      if (!mounted) {
        print('⚠️  Widget not mounted, cannot navigate');
        return;
      }

      // Show the result in dialog FIRST
      await _showResultInDialog(
        result: result,
        passed: passed,
        percentage: percentage,
        obtainedMarks: obtainedMarks,
        totalMarks: totalMarks,
        nextModuleUnlocked: nextModuleUnlocked,
        message: message,
        questionResults: questionResults,
      );

      // After dialog closes, navigate back
      print('   Navigating back after dialog closes...');

      if (mounted) {
        // Add a small delay for better UX
        await Future.delayed(const Duration(milliseconds: 300));

        if (Navigator.canPop(context)) {
          context.pop(); // Go back to dashboard
          print('✅ Successfully navigated back');
        } else {
          context.go('/dashboard'); // Fallback to dashboard
          print('✅ Fallback: Went to dashboard');
        }
      }

    } catch (e, stackTrace) {
      print('❌ ERROR in _submitAssessment:');
      print('   Type: ${e.runtimeType}');
      print('   Message: ${e.toString()}');
      print('   Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit assessment: ${e.toString().split('\n').first}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _submitAssessment,
            ),
          ),
        );
      }
    } finally {
      print('🎯 _submitAssessment() ENDED');
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showResultInDialog({
    required Map<String, dynamic> result,
    required bool passed,
    required double percentage,
    required int obtainedMarks,
    required int totalMarks,
    required bool nextModuleUnlocked,
    required String message,
    List<dynamic>? questionResults,
  }) async {
    print('📊 Showing result in dialog...');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(passed ? '🎉 Assessment Passed!' : 'Assessment Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: passed ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Score:', style: TextStyle(fontSize: 16)),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: passed ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Marks:', style: TextStyle(fontSize: 16)),
                        Text(
                          '$obtainedMarks/$totalMarks',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // NEW: Show question results if available
              if (questionResults != null && questionResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Question Results:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...questionResults.asMap().entries.map((entry) {
                  final index = entry.key;
                  final qResult = entry.value as Map<String, dynamic>;
                  final isCorrect = qResult['correct'] ?? false;
                  final yourAnswer = qResult['userAnswer'] ?? 'No answer';
                  final correctAnswer = qResult['correctAnswer'] ?? 'Unknown';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCorrect ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check : Icons.close,
                          color: isCorrect ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q${index + 1}: ${isCorrect ? 'Correct' : 'Incorrect'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isCorrect ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                              if (!isCorrect) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Your answer: $yourAnswer',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                                Text(
                                  'Correct answer: $correctAnswer',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],

              if (nextModuleUnlocked) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_open, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next module has been unlocked!',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}