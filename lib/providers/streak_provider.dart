// lib/providers/streak_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cdax_app/services/api_service.dart';
import 'package:cdax_app/models/streak_model.dart';

class StreakProvider with ChangeNotifier {
  final ApiService _apiService;

  StreakModel? _courseStreak;
  Map<String, dynamic>? _overviewStreak;
  bool _isLoading = false;
  String? _error;

  StreakProvider(this._apiService);

  // Getters
  StreakModel? get courseStreak => _courseStreak;
  Map<String, dynamic>? get overviewStreak => _overviewStreak;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch streak for a course
  Future<void> fetchCourseStreak(String courseId, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getCourseStreak(courseId, userId);

      if (response.success && response.data != null) {
        _courseStreak = StreakModel.fromJson(response.data!);
      } else {
        throw Exception(response.error ?? 'Failed to fetch streak');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch overview for all courses
  Future<void> fetchStreakOverview(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getStreakOverview(userId);

      if (response.success && response.data != null) {
        _overviewStreak = response.data!;
      } else {
        throw Exception(response.error ?? 'Failed to fetch streak overview');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear data
  void clear() {
    _courseStreak = null;
    _overviewStreak = null;
    _error = null;
    notifyListeners();
  }
}