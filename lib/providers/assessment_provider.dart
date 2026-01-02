import 'package:flutter/foundation.dart';
import '../models/assessment/assessment_model.dart';
import '../models/assessment/question_model.dart';
import '../services/assessment_service.dart';
import '../providers/user_provider.dart';

class AssessmentProvider extends ChangeNotifier {
  List<Assessment> _assessments = [];
  List<Question> _currentQuestions = [];
  final Map<String, UserAnswer> _userAnswers = {};
  Assessment? _currentAssessment;
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
  String? _error;
  DateTime? _assessmentStartTime;

  Duration _remainingTime = Duration.zero;
  bool _isTimerRunning = false;
  Map<String, dynamic>? _lastAssessmentResult;
  final AssessmentService _assessmentService = AssessmentService();
  UserProvider? _userProvider;

  // 🆕 ADD THIS: Manual user ID storage
  int? _manualUserId;

  // Initialize with UserProvider
  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  // 🆕 ADD THIS: Set manual user ID
  void setManualUserId(String userId) {
    _manualUserId = int.tryParse(userId);
    print('🎯 PROVIDER: Manual user ID set to: $_manualUserId');
  }

  List<Assessment> get assessments => List.unmodifiable(_assessments);
  List<Question> get currentQuestions => List.unmodifiable(_currentQuestions);
  Map<String, UserAnswer> get userAnswers => Map.unmodifiable(_userAnswers);
  Assessment? get currentAssessment => _currentAssessment;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Duration get remainingTime => _remainingTime;
  bool get isTimerRunning => _isTimerRunning;
  DateTime? get assessmentStartTime => _assessmentStartTime;

  Question? get currentQuestion =>
      _currentQuestions.isNotEmpty && _currentQuestionIndex < _currentQuestions.length
          ? _currentQuestions[_currentQuestionIndex]
          : null;

  int get totalQuestions => _currentQuestions.length;
  double get progress => totalQuestions > 0 ? (_currentQuestionIndex + 1) / totalQuestions : 0.0;
  int get answeredCount => _userAnswers.length;
  bool get hasNextQuestion => _currentQuestionIndex < totalQuestions - 1;
  bool get hasPreviousQuestion => _currentQuestionIndex > 0;
  bool get isCurrentQuestionAnswered =>
      currentQuestion != null && _userAnswers.containsKey(currentQuestion!.id);

  // 🆕 UPDATED: Helper method to get userId as int
  int? get _userIdAsInt {
    // First try manual user ID
    if (_manualUserId != null) {
      print('✅ PROVIDER: Using manual user ID: $_manualUserId');
      return _manualUserId;
    }

    // Then try user provider
    if (_userProvider?.currentUser?.id != null) {
      final id = int.tryParse(_userProvider!.currentUser!.id.toString());
      print('✅ PROVIDER: Using user provider ID: $id');
      return id;
    }

    print('❌ PROVIDER: No user ID available');
    return null;
  }

  Map<String, dynamic>? get lastAssessmentResult => _lastAssessmentResult;

  /// Load all available assessments
  Future<void> loadAssessments() async {
    _setLoading(true);
    _clearError();

    try {
      // For now, return empty list until backend provides assessment list endpoint
      _assessments = [];
      notifyListeners();
    } catch (e) {
      _setError('Failed to load assessments: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Start a specific assessment
  Future<void> startAssessment(int assessmentId) async {
    _setLoading(true);
    _clearError();

    try {
      // Get current user ID as int
      final userId = _userIdAsInt;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Find the assessment (if it's already loaded)
      if (_assessments.isNotEmpty) {
        _currentAssessment = _assessments.firstWhere(
              (a) => a.id == assessmentId.toString(),
          orElse: () => throw Exception('Assessment not found'),
        );
      } else {
        // If not loaded, create a temporary assessment object
        _currentAssessment = Assessment(
          id: assessmentId.toString(),
          title: 'Assessment',
          duration: 30,
          category: '',
          difficulty: '',
          description: '',
          totalQuestions: 10,
          passingScore: 70,
        );
      }

      // Load questions using instance method
      _currentQuestions = await _assessmentService.getAssessmentWithQuestions(
        userId: userId,
        assessmentId: assessmentId,
      );

      // Reset state
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _assessmentStartTime = DateTime.now();

      // Start timer if assessment has duration
      if (_currentAssessment!.duration > 0) {
        _remainingTime = Duration(minutes: _currentAssessment!.duration);
        _isTimerRunning = true;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to start assessment: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  /// Start assessment with explicit user ID
  Future<void> startAssessmentWithUserId(int assessmentId, int userId) async {
    print('🎯 startAssessmentWithUserId called');
    print('   assessmentId: $assessmentId');
    print('   userId: $userId');

    _setLoading(true);
    _clearError();

    // Store the user ID
    _manualUserId = userId;
    print('   _manualUserId set to: $_manualUserId');
    print('   _userIdAsInt now returns: $_userIdAsInt');

    try {
      // Find the assessment
      if (_assessments.isNotEmpty) {
        _currentAssessment = _assessments.firstWhere(
              (a) => a.id == assessmentId.toString(),
          orElse: () => throw Exception('Assessment not found'),
        );
      } else {
        _currentAssessment = Assessment(
          id: assessmentId.toString(),
          title: 'Assessment',
          duration: 30,
          category: '',
          difficulty: '',
          description: '',
          totalQuestions: 10,
          passingScore: 70,
        );
      }

      // Load questions
      _currentQuestions = await _assessmentService.getAssessmentWithQuestions(
        userId: userId,  // Use the passed userId directly
        assessmentId: assessmentId,
      );

      // Reset state
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _assessmentStartTime = DateTime.now();

      if (_currentAssessment!.duration > 0) {
        _remainingTime = Duration(minutes: _currentAssessment!.duration);
        _isTimerRunning = true;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to start assessment: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Submit the entire assessment
  Future<Map<String, dynamic>> submitAssessment() async {
    print('🔴 PROVIDER: submitAssessment() STARTED');
    _setLoading(true);
    _clearError();

    try {
      // Get current user ID as int
      final userId = _userIdAsInt;
      if (userId == null) {
        print('❌ PROVIDER: User not logged in');
        throw Exception('User not logged in');
      }

      print('   User ID: $userId');

      if (_currentAssessment == null) {
        print('❌ PROVIDER: No active assessment');
        throw Exception('No active assessment');
      }

      // Parse assessment ID from string to int
      final assessmentId = int.tryParse(_currentAssessment!.id);
      if (assessmentId == null) {
        print('❌ PROVIDER: Invalid assessment ID format: ${_currentAssessment!.id}');
        throw Exception('Invalid assessment ID format');
      }

      print('   Assessment ID: $assessmentId');
      print('   User answers count: ${_userAnswers.length}');
      print('   User answers: $_userAnswers');

      // Prepare answers for submission
      print('   Assessment ID: $assessmentId');
      print('   User answers count: ${_userAnswers.length}');
      print('   User answers: $_userAnswers');

// 🆕 DEBUG: Check current questions and their correct answers
      print('   Current questions loaded: ${_currentQuestions.length}');
      for (final question in _currentQuestions) {
        final qId = int.tryParse(question.id);
        print('       Options: ${question.options}');
        print('       Correct answer: ${question.correctAnswer}');

        final userAnswer = _userAnswers[question.id];
        if (userAnswer != null) {
          print('       User answer: ${userAnswer.answer}');
        } else {
          print('       User answer: Not answered');
        }
      }

// Prepare answers for submission
      final Map<int, String> answers = {};
      for (final entry in _userAnswers.entries) {
        // Parse question ID from string to int
        final questionId = int.tryParse(entry.key);
        print('   Processing answer: ${entry.key} -> ${entry.value.answer}');
        print('     Question ID parsed: $questionId');
        print('     Answer type: ${entry.value.answer.runtimeType}');

        if (questionId != null && entry.value.answer != null) {
          String answerString = entry.value.answer.toString();

          // 🆕 CONVERT NUMERIC ANSWERS TO LETTERS
          print('     🔍 Raw answer: $answerString');

          // Format 1: Try as letter directly (A, B, C, D)
          if (answerString.length == 1 && RegExp(r'^[A-D]$', caseSensitive: false).hasMatch(answerString)) {
            // Already a letter, use uppercase
            answerString = answerString.toUpperCase();
            print('     Format 1: Letter answer -> $answerString');
          }
          // Format 2: Convert from index number (0-3) to letter A-D
          else if (answerString.length == 1 && RegExp(r'^[0-3]$').hasMatch(answerString)) {
            int index = int.parse(answerString);
            List<String> letters = ['A', 'B', 'C', 'D'];

            // Try as 0-based index
            if (index >= 0 && index < letters.length) {
              answerString = letters[index];
              print('     Format 2a: 0-based index $index -> letter $answerString');
            }
          }
          // Format 3: Convert from index number (1-4) to letter A-D
          else if (answerString.length == 1 && RegExp(r'^[1-4]$').hasMatch(answerString)) {
            int index = int.parse(answerString);
            List<String> letters = ['A', 'B', 'C', 'D'];

            // Try as 1-based index
            if (index >= 1 && index <= letters.length) {
              answerString = letters[index - 1];
              print('     Format 2b: 1-based index $index -> letter $answerString');
            }
          }
          // Format 4: Could be option text (keep as-is)
          else {
            // Just use as-is
            print('     Format 3: Using as-is -> $answerString');
          }

          answers[questionId] = answerString;
          print('     ✅ Final: $questionId -> "$answerString"');
        } else {
          print('     ❌ Skipped - questionId: $questionId, answer: ${entry.value.answer}');
        }
      }

      print('   Final answers map for submission: $answers');
      print('   Answers map size: ${answers.length}');

      print('   Final answers map for submission: $answers');
      print('   Answers map size: ${answers.length}');

      // Submit to backend
      print('   Calling _assessmentService.submitAssessment()...');
      final result = await _assessmentService.submitAssessment(
        userId: userId,
        assessmentId: assessmentId,
        answers: answers,
      );

      print('   ✅ Service returned result: $result');

      final bool passed = result['passed'] ?? false;
      final bool nextModuleUnlocked = result['nextModuleUnlocked'] ?? false;
      final double percentage = (result['percentage'] ?? 0.0).toDouble();
      final int obtainedMarks = (result['obtainedMarks'] ?? 0).toInt();
      final int totalMarks = (result['totalMarks'] ?? 0).toInt();

      print('🎯 PROVIDER: Assessment Result Summary:');
      print('   ├─ Passed: $passed (${percentage.toStringAsFixed(1)}%)');
      print('   ├─ Score: $obtainedMarks/$totalMarks');
      print('   ├─ Next Module Unlocked: $nextModuleUnlocked');
      print('   └─ Full Result: $result');

      // Stop timer
      _isTimerRunning = false;

      // Store the result before clearing state
      _lastAssessmentResult = {
        ...result,
        'assessmentId': assessmentId,
        'assessmentTitle': _currentAssessment?.title,
        'passed': passed,
        'percentage': percentage,
        'obtainedMarks': obtainedMarks,
        'totalMarks': totalMarks,
        'nextModuleUnlocked': nextModuleUnlocked,
        'message': passed
            ? nextModuleUnlocked
            ? 'Congratulations! You passed with ${percentage.toStringAsFixed(1)}%. Next module unlocked! 🎉'
            : 'Congratulations! You passed with ${percentage.toStringAsFixed(1)}%!'
            : 'You scored ${percentage.toStringAsFixed(1)}%. Need 70% to pass. Try again!',
      };

      // Clear assessment state (but keep the result)
      resetAssessment();

      notifyListeners();

      print('✅ PROVIDER: submitAssessment() COMPLETED SUCCESSFULLY');
      return _lastAssessmentResult!;

    } catch (e) {
      print('❌ PROVIDER ERROR in submitAssessment:');
      print('   Error: ${e.toString()}');
      print('   Stack trace: ${e is Error ? e.stackTrace : "No stack trace"}');

      _setError('Failed to submit assessment: ${e.toString()}');
      rethrow;
    } finally {
      print('🔴 PROVIDER: submitAssessment() ENDED (finally block)');
      _setLoading(false);
    }
  }

  /// Check if user can attempt assessment
  Future<bool> canAttemptAssessment(int assessmentId) async {
    try {
      // Get current user ID as int
      final userId = _userIdAsInt;
      if (userId == null) return false;

      return await _assessmentService.canAttemptAssessment(
        userId: userId,
        assessmentId: assessmentId,
      );
    } catch (e) {
      return false;
    }
  }

  /// Get assessment status
  Future<Map<String, dynamic>> getAssessmentStatus(int assessmentId) async {
    try {
      // Get current user ID as int
      final userId = _userIdAsInt;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      return await _assessmentService.getAssessmentStatus(
        userId: userId,
        assessmentId: assessmentId,
      );
    } catch (e) {
      throw Exception('Failed to get assessment status: $e');
    }
  }

  /// Submit answer for current question
  /// Submit answer for current question
  void submitAnswer(dynamic answer) {
    if (currentQuestion == null) return;

    print('🔴 PROVIDER: submitAnswer called');
    print('   Question ID: ${currentQuestion!.id}');
    print('   Answer received: $answer (type: ${answer.runtimeType})');
    print('   Answer options: ${currentQuestion!.options}');

    final userAnswer = UserAnswer(
      questionId: currentQuestion!.id,
      answer: answer,
      timestamp: DateTime.now(),
    );

    _userAnswers[currentQuestion!.id] = userAnswer;

    // Debug: Print current user answers
    print('   Current user answers:');
    for (final entry in _userAnswers.entries) {
      print('     Q${entry.key}: ${entry.value.answer}');
    }

    notifyListeners();
  }

  /// Navigate to next question
  void goToNextQuestion() {
    if (hasNextQuestion) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  /// Navigate to previous question
  void goToPreviousQuestion() {
    if (hasPreviousQuestion) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void clearLastResult() {
    _lastAssessmentResult = null;
    notifyListeners();
  }

  /// Navigate to specific question
  void goToQuestion(int index) {
    if (index >= 0 && index < totalQuestions) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  /// Update timer (called externally by timer)
  void updateTimer(Duration newRemainingTime) {
    _remainingTime = newRemainingTime;

    if (_remainingTime.inSeconds <= 0 && _isTimerRunning) {
      _isTimerRunning = false;
    }

    notifyListeners();
  }

  /// Stop the timer
  void stopTimer() {
    _isTimerRunning = false;
    notifyListeners();
  }

  /// Reset assessment state
  void resetAssessment() {
    _currentAssessment = null;
    _currentQuestions.clear();
    _userAnswers.clear();
    _currentQuestionIndex = 0;
    _assessmentStartTime = null;
    _remainingTime = Duration.zero;
    _isTimerRunning = false;
    _clearError();
    notifyListeners();
  }

  /// Get answer for specific question
  UserAnswer? getAnswerForQuestion(String questionId) {
    return _userAnswers[questionId];
  }

  /// Check if all questions are answered
  bool get areAllQuestionsAnswered =>
      _userAnswers.length == _currentQuestions.length;

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isTimerRunning = false;
    super.dispose();
  }
}

// Helper class for user answers
class UserAnswer {
  final String questionId;
  final dynamic answer;
  final DateTime timestamp;

  UserAnswer({
    required this.questionId,
    required this.answer,
    required this.timestamp,
  });
}