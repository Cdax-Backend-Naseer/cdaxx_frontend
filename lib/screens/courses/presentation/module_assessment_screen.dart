import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../application/course_providers.dart';
import '../../../models/assessment/question_model.dart';

class ModuleAssessmentScreen extends StatefulWidget {
  const ModuleAssessmentScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.assessmentId,
  });

  final String courseId;
  final String moduleId;
  final String assessmentId;

  @override
  State<ModuleAssessmentScreen> createState() => _ModuleAssessmentScreenState();
}

class _ModuleAssessmentScreenState extends State<ModuleAssessmentScreen> {
  int currentQuestionIndex = 0;
  List<int?> userAnswers = [];
  List<Question> questions = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('🎯 ModuleAssessmentScreen: initState() called');
      debugPrint('   ├─ Course ID: ${widget.courseId}');
      debugPrint('   ├─ Module ID: ${widget.moduleId}');
      debugPrint('   └─ Assessment ID: ${widget.assessmentId}');
    }
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    print(
      '🎯 ModuleAssessmentScreen: Loading questions for assessment ${widget.assessmentId}',
    );
    try {
      final repo = CourseProviders.getCourseRepository();
      print('📚 Using repository: ${repo.runtimeType}');

      final fetchedQuestions = await repo.getAssessmentQuestions(
        widget.assessmentId,
      );
      print('✅ Fetched ${fetchedQuestions.length} questions');

      for (int i = 0; i < fetchedQuestions.length; i++) {
        final q = fetchedQuestions[i];
        print('   Q${i + 1}: ${q.question}');
        print('        Options: ${q.options}');
        print('        Correct: ${q.correctAnswer}');
      }

      setState(() {
        questions = fetchedQuestions;
        userAnswers = List<int?>.filled(fetchedQuestions.length, null);
        isLoading = false;
      });

      print('📝 Questions loaded successfully into UI');
    } catch (e) {
      print('❌ Error loading questions: $e');
      setState(() {
        error = 'Failed to load questions: $e';
        isLoading = false;
      });
    }
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      userAnswers[currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  void _submitAssessment() {
    // Calculate score
    int correctAnswers = 0;
    print('\n🎯 Assessment Scoring Debug:');
    for (int i = 0; i < questions.length; i++) {
      final userAnswer = userAnswers[i];
      final correctAnswer = questions[i].correctAnswer;

      // Robust comparison - handle type mismatches
      bool isCorrect = false;
      if (userAnswer != null) {
        // Convert both to int for comparison
        try {
          int userInt = userAnswer;
          int correctInt =
              correctAnswer is int
                  ? correctAnswer
                  : int.parse(correctAnswer.toString());
          isCorrect = userInt == correctInt;
        } catch (e) {
          // Fallback to direct comparison
          isCorrect = userAnswer == correctAnswer;
        }
      }

      print(
        '   Q${i + 1}: User answered ${userAnswer} | Correct: ${correctAnswer} | Match: ${isCorrect}',
      );
      print(
        '       User answer type: ${userAnswer.runtimeType} | Correct answer type: ${correctAnswer.runtimeType}',
      );

      if (isCorrect) {
        correctAnswers++;
      }
    }
    print('   Final score: $correctAnswers/${questions.length}');

    final double percentage = (correctAnswers / questions.length) * 100;

    // Show results dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Assessment Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  percentage >= 70 ? Icons.check_circle : Icons.cancel,
                  size: 64,
                  color: percentage >= 70 ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'You scored ${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$correctAnswers out of ${questions.length} questions correct',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  percentage >= 70
                      ? 'Congratulations! You passed!'
                      : 'Please review the material and try again.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(
                    '/dashboard/courses/${widget.courseId}/module/${widget.moduleId}',
                  );
                },
                child: const Text('Back to Module'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assessment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed:
                () => context.go(
                  '/dashboard/courses/${widget.courseId}/module/${widget.moduleId}',
                ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    () => context.go(
                      '/dashboard/courses/${widget.courseId}/module/${widget.moduleId}',
                    ),
                child: const Text('Back to Module'),
              ),
            ],
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assessment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed:
                () => context.go(
                  '/dashboard/courses/${widget.courseId}/module/${widget.moduleId}',
                ),
          ),
        ),
        body: const Center(
          child: Text('No questions available for this assessment'),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final selectedAnswer = userAnswers[currentQuestionIndex];
    final totalQuestions = questions.length;
    final isLastQuestion = currentQuestionIndex == totalQuestions - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentQuestionIndex + 1} of $totalQuestions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => context.go(
                '/dashboard/courses/${widget.courseId}/module/${widget.moduleId}',
              ),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / totalQuestions,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),

          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        currentQuestion.question,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Answer options
                  ...currentQuestion.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = selectedAnswer == index;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                      child: InkWell(
                        onTap: () => _selectAnswer(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: index,
                                groupValue: selectedAnswer,
                                onChanged: (value) {
                                  if (value != null) {
                                    _selectAnswer(value);
                                  }
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Previous button
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          currentQuestionIndex > 0 ? _previousQuestion : null,
                      child: const Text('Previous'),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Next/Submit button
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          selectedAnswer != null
                              ? (isLastQuestion
                                  ? _submitAssessment
                                  : _nextQuestion)
                              : null,
                      child: Text(isLastQuestion ? 'Submit' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
