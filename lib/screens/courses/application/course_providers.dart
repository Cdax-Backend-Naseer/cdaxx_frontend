// Enhanced course providers with Spring Boot backend integration
// Automatically uses remote repository with mock fallback

import 'package:flutter/material.dart';
import '../../../factories/course_repository_factory.dart';
import '../data/course_repository.dart';
export '../data/course_repository.dart';

/// Course provider utilities for backend integration
class CourseProviders {
  /// Get the configured course repository instance
  /// Returns RemoteCourseRepository (with mock fallback) or MockCourseRepository
  static CourseRepository getCourseRepository({BuildContext? context, String? userId}) {
    final repo = CourseRepositoryFactory.getInstance(
      context: context,
      userId: userId,
    );
    print('📚 Using repository type: RemoteCourseRepository');
    print('👤 Repository created for user: $userId');
    return repo;
  }
}

/// Simple last-played store without external dependencies; can be swapped for provider later.
class LastPlayedStore {
  LastPlayedStore._();
  static final LastPlayedStore instance = LastPlayedStore._();
  final Map<String, String?> _courseToModule = <String, String?>{};

  void setLastPlayed(String courseId, String moduleId) {
    _courseToModule[courseId] = moduleId;
  }

  String? lastForCourse(String courseId) => _courseToModule[courseId];
}