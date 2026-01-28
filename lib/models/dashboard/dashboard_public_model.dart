// New User Dashboard Model  
// Used for authenticated users with no enrollment history to show discovery content
// Data comes from GET /api/users/{userId}/dashboard endpoint when hasEnrolledCourses = false

import 'package:flutter/foundation.dart';

import '../course_model.dart';


@immutable
class NewUserDashboardModel {
  final HeroBanner hero;
  final List<CourseModel> featuredCourses;
  final List<StarterPath> starterPaths;
  final List<String> popularCategories;
  final PublicStats stats;

  const NewUserDashboardModel({
    required this.hero,
    required this.featuredCourses,
    required this.starterPaths,
    required this.popularCategories,
    required this.stats,
  });

  factory NewUserDashboardModel.fromJson(Map<String, dynamic> json) {
    print('📊 Parsing Public Dashboard JSON');
    
    try {
      // Parse featured courses
      List<CourseModel> courses = [];
      if (json['featuredCourses'] != null && json['featuredCourses'] is List) {
        courses = (json['featuredCourses'] as List)
            .map((courseJson) => CourseModel.fromJson(courseJson))
            .toList();
        print('   ├─ Found ${courses.length} featured courses');
      }

      // Parse starter paths
      List<StarterPath> paths = [];
      if (json['starterPaths'] != null && json['starterPaths'] is List) {
        paths = (json['starterPaths'] as List)
            .map((pathJson) => StarterPath.fromJson(pathJson))
            .toList();
        print('   ├─ Found ${paths.length} starter paths');
      }

      // Parse categories
      List<String> categories = [];
      if (json['popularCategories'] != null && json['popularCategories'] is List) {
        categories = (json['popularCategories'] as List)
            .map((category) => category.toString())
            .toList();
        print('   ├─ Found ${categories.length} categories');
      }

      return NewUserDashboardModel(
        hero: HeroBanner.fromJson(json['hero'] ?? {}),
        featuredCourses: courses,
        starterPaths: paths,
        popularCategories: categories,
        stats: PublicStats.fromJson(json['stats'] ?? {}),
      );
    } catch (e) {
      print('❌ Error parsing Public Dashboard JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'hero': hero.toJson(),
      'featuredCourses': featuredCourses.map((course) => course.toJson()).toList(),
      'starterPaths': starterPaths.map((path) => path.toJson()).toList(),
      'popularCategories': popularCategories,
      'stats': stats.toJson(),
    };
  }
}

@immutable
class HeroBanner {
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String? ctaRoute;
  final String? imageUrl;

  const HeroBanner({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    this.ctaRoute,
    this.imageUrl,
  });

  factory HeroBanner.fromJson(Map<String, dynamic> json) {
    return HeroBanner(
      title: json['title']?.toString() ?? 'Learn in-demand skills',
      subtitle: json['subtitle']?.toString() ?? 'Start with a free intro module',
      ctaLabel: json['ctaLabel']?.toString() ?? 'Browse Courses',
      ctaRoute: json['ctaRoute']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'ctaLabel': ctaLabel,
      'ctaRoute': ctaRoute,
      'imageUrl': imageUrl,
    };
  }
}

@immutable
class StarterPath {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final List<StarterModule> modules;
  final String ctaLabel;

  const StarterPath({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.modules,
    required this.ctaLabel,
  });

  factory StarterPath.fromJson(Map<String, dynamic> json) {
    print('🛤️ Parsing Starter Path: ${json['title']}');

    try {
      // Parse modules
      List<StarterModule> modulesList = [];
      if (json['modules'] != null && json['modules'] is List) {
        modulesList = (json['modules'] as List)
            .map((moduleJson) => StarterModule.fromJson(moduleJson))
            .toList();
        print('   ├─ Found ${modulesList.length} modules in starter path');
      }

      return StarterPath(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Untitled Path',
        description: json['description']?.toString() ?? '',
        thumbnailUrl: json['thumbnailUrl']?.toString(),
        modules: modulesList,
        ctaLabel: json['ctaLabel']?.toString() ?? 'Start Path',
      );
    } catch (e) {
      print('❌ Error parsing Starter Path JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'modules': modules.map((module) => module.toJson()).toList(),
      'ctaLabel': ctaLabel,
    };
  }
}

@immutable
class StarterModule {
  final String id;
  final String title;
  final int durationSec;
  final bool isFree;
  final int orderIndex;

  const StarterModule({
    required this.id,
    required this.title,
    required this.durationSec,
    required this.isFree,
    required this.orderIndex,
  });

  factory StarterModule.fromJson(Map<String, dynamic> json) {
    return StarterModule(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Module',
      durationSec: _parseIntSafely(json['durationSec'] ?? json['duration'], 0),
      isFree: _parseBoolSafely(json['isFree'], false),
      orderIndex: _parseIntSafely(json['orderIndex'] ?? json['order'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'durationSec': durationSec,
      'isFree': isFree,
      'orderIndex': orderIndex,
    };
  }

  static int _parseIntSafely(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  static bool _parseBoolSafely(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return defaultValue;
  }
}

@immutable
class PublicStats {
  final int totalCourses;
  final int totalStudents;
  final String? topInstructor;
  final double? averageRating;

  const PublicStats({
    required this.totalCourses,
    required this.totalStudents,
    this.topInstructor,
    this.averageRating,
  });

  factory PublicStats.fromJson(Map<String, dynamic> json) {
    return PublicStats(
      totalCourses: _parseIntSafely(json['totalCourses'], 0),
      totalStudents: _parseIntSafely(json['totalStudents'], 0),
      topInstructor: json['topInstructor']?.toString(),
      averageRating: _parseDoubleSafely(json['averageRating'], null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCourses': totalCourses,
      'totalStudents': totalStudents,
      'topInstructor': topInstructor,
      'averageRating': averageRating,
    };
  }

  static int _parseIntSafely(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  static double? _parseDoubleSafely(dynamic value, double? defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}