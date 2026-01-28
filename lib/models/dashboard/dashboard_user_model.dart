// User Dashboard Model
// Used for authenticated users to show personalized data
// Data comes from GET /api/users/{userId}/dashboard endpoint

import 'package:flutter/material.dart';

import '../course_model.dart';


@immutable
class DashboardUserModel {
  final String userId;
  final String greeting;
  final DashboardSummary summary;
  final List<CourseModel> enrolledCourses;
  final List<RecentActivity> recentActivity;
  final List<CourseModel> recommended;

  const DashboardUserModel({
    required this.userId,
    required this.greeting,
    required this.summary,
    required this.enrolledCourses,
    required this.recentActivity,
    required this.recommended,
  });

  factory DashboardUserModel.fromJson(Map<String, dynamic> json) {
    print('📊 Parsing User Dashboard JSON for user: ${json['userId']}');
    
    try {
      // Parse enrolled courses
      List<CourseModel> enrolled = [];
      if (json['enrolledCourses'] != null && json['enrolledCourses'] is List) {
        enrolled = (json['enrolledCourses'] as List)
            .map((courseJson) => CourseModel.fromJson(courseJson))
            .toList();
        print('   ├─ Found ${enrolled.length} enrolled courses');
      }

      // Parse recent activity
      List<RecentActivity> activities = [];
      if (json['recentActivity'] != null && json['recentActivity'] is List) {
        activities = (json['recentActivity'] as List)
            .map((activityJson) => RecentActivity.fromJson(activityJson))
            .toList();
        print('   ├─ Found ${activities.length} recent activities');
      }

      // Parse recommended courses
      List<CourseModel> recommendedList = [];
      if (json['recommended'] != null && json['recommended'] is List) {
        recommendedList = (json['recommended'] as List)
            .map((courseJson) => CourseModel.fromJson(courseJson))
            .toList();
        print('   ├─ Found ${recommendedList.length} recommended courses');
      }

      return DashboardUserModel(
        userId: json['userId']?.toString() ?? '',
        greeting: json['greeting']?.toString() ?? 'Welcome back!',
        summary: DashboardSummary.fromJson(json['summary'] ?? {}),
        enrolledCourses: enrolled,
        recentActivity: activities,
        recommended: recommendedList,
      );
    } catch (e) {
      print('❌ Error parsing User Dashboard JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'greeting': greeting,
      'summary': summary.toJson(),
      'enrolledCourses': enrolledCourses.map((course) => course.toJson()).toList(),
      'recentActivity': recentActivity.map((activity) => activity.toJson()).toList(),
      'recommended': recommended.map((course) => course.toJson()).toList(),
    };
  }
}

@immutable
class DashboardSummary {
  final int coursesPurchased;
  final int coursesInProgress;
  final int videosCompleted;
  final int badges;
  final int assessmentsCompleted;

  const DashboardSummary({
    required this.coursesPurchased,
    required this.coursesInProgress,
    required this.videosCompleted,
    required this.badges,
    required this.assessmentsCompleted,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      coursesPurchased: _parseIntSafely(json['coursesPurchased'], 0),
      coursesInProgress: _parseIntSafely(json['coursesInProgress'], 0),
      videosCompleted: _parseIntSafely(json['videosCompleted'], 0),
      badges: _parseIntSafely(json['badges'], 0),
      assessmentsCompleted: _parseIntSafely(json['assessmentsCompleted'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coursesPurchased': coursesPurchased,
      'coursesInProgress': coursesInProgress,
      'videosCompleted': videosCompleted,
      'badges': badges,
      'assessmentsCompleted': assessmentsCompleted,
    };
  }

  static int _parseIntSafely(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }
}

@immutable
class RecentActivity {
  final String id;
  final String type; // 'video_play', 'assessment_start', 'course_complete', etc.
  final String? courseId;
  final String? moduleId;
  final String? videoId;
  final String? assessmentId;
  final String title;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const RecentActivity({
    required this.id,
    required this.type,
    this.courseId,
    this.moduleId,
    this.videoId,
    this.assessmentId,
    required this.title,
    required this.timestamp,
    this.metadata,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    print('📝 Parsing Recent Activity: ${json['type']} - ${json['title']}');

    try {
      return RecentActivity(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'unknown',
        courseId: json['courseId']?.toString(),
        moduleId: json['moduleId']?.toString(),
        videoId: json['videoId']?.toString(),
        assessmentId: json['assessmentId']?.toString(),
        title: json['title']?.toString() ?? 'Unknown Activity',
        timestamp: _parseDateSafely(json['timestamp']) ?? DateTime.now(),
        metadata: json['metadata'] is Map<String, dynamic> 
            ? Map<String, dynamic>.from(json['metadata'])
            : null,
      );
    } catch (e) {
      print('❌ Error parsing Recent Activity JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'courseId': courseId,
      'moduleId': moduleId,
      'videoId': videoId,
      'assessmentId': assessmentId,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  static DateTime? _parseDateSafely(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Failed to parse date: $value');
        return null;
      }
    }
    return null;
  }

  // Helper methods for UI
  IconData get icon {
    switch (type) {
      case 'video_play':
        return Icons.play_circle;
      case 'assessment_start':
      case 'assessment_complete':
        return Icons.quiz;
      case 'course_complete':
        return Icons.school;
      case 'module_complete':
        return Icons.check_circle;
      default:
        return Icons.timeline;
    }
  }

  String get displayText {
    switch (type) {
      case 'video_play':
        return 'Watched: $title';
      case 'assessment_start':
        return 'Started: $title';
      case 'assessment_complete':
        return 'Completed: $title'; 
      case 'course_complete':
        return 'Finished: $title';
      case 'module_complete':
        return 'Completed: $title';
      default:
        return title;
    }
  }
}