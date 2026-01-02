import 'package:flutter/foundation.dart';

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.progressPercent,
    this.description = '',
    this.totalModules = 0,
    this.formattedDuration = '',
    this.isSubscribed = false,
  });

  final String id;
  final String title;
  final String thumbnailUrl;
  final double progressPercent;
  final String description;
  final int totalModules;
  final String formattedDuration;
  final bool isSubscribed;
}

class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  List<Course> _enrolledCourses = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Course> get enrolledCourses => _enrolledCourses;

  Future<void> loadDashboard() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 🔥 REPLACE with real API call
      await Future.delayed(const Duration(milliseconds: 500));

      _enrolledCourses = [
        Course(
          id: 'c1',
          title: 'Flutter Foundations',
          thumbnailUrl: '',
          progressPercent: 0.4,
          isSubscribed: true,
        ),
      ];

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

