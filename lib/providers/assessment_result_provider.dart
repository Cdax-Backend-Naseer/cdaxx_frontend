import 'package:flutter/foundation.dart';
import '../models/assessment/assessment_result_model.dart';
import '../models/assessment/question_model.dart';



class AssessmentResultProvider extends ChangeNotifier {
  // Assessment result submission will use backend endpoint
  
  // State variables
  AssessmentResult? _result;
  bool _isSubmitting = false;
  String? _error;
  
  // Getters
  AssessmentResult? get result => _result;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  
  // Computed getters
  bool get hasResult => _result != null;
  
  /// Submit assessment and calculate result
  Future<void> submitAssessment({
    required String assessmentId,
    required String userId,
    required Map<String, UserAnswer> userAnswers,
    required DateTime startTime,
  }) async {
    _setSubmitting(true);
    _clearError();
    
    try {
      final endTime = DateTime.now();
      
      // TODO: Implement backend assessment result submission
      // For now, create a simple result
      _result = AssessmentResult(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        assessmentId: assessmentId,
        userId: userId,
        score: 0,
        totalQuestions: userAnswers.length,
        correctAnswers: 0,
        wrongAnswers: 0,
        skippedAnswers: 0,
        percentage: 0.0,
        passed: false,
        startTime: startTime,
        endTime: endTime,
        timeTaken: endTime.difference(startTime),
        answers: userAnswers.map((k, v) => MapEntry(k, v.toJson())),
      );
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to submit assessment: ${e.toString()}');
    } finally {
      _setSubmitting(false);
    }
  }

  /// Clear current result
  void clearResult() {
    _result = null;
    _clearError();
    notifyListeners();
  }

  /// Retry submission with same data
  Future<void> retrySubmission() async {
    if (_result != null) {
      // If we have a result, we don't need to retry
      return;
    }
    
    // This would need the original data to retry
    // For now, just clear the error to allow UI to handle retry
    _clearError();
  }

  // Private helper methods
  void _setSubmitting(bool submitting) {
    _isSubmitting = submitting;
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
}
