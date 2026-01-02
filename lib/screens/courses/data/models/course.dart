// Enhanced Course model for Spring Boot backend integration
// Supports JSON serialization and includes comprehensive metadata

import 'package:flutter/foundation.dart';
import 'module.dart';

@immutable
class Course {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final double progressPercent; // 0..1
  final bool isSubscribed; // Whether course is purchased
  final List<Module> modules;
  final String? instructor; // Optional instructor name
  final double? rating; // Optional course rating
  final int? studentsCount; // Optional student count
  final String? category; // Optional course category
  final DateTime? createdAt; // Optional creation date
  final DateTime? updatedAt; // Optional last update

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.progressPercent,
    required this.isSubscribed,
    required this.modules,
    this.instructor,
    this.rating,
    this.studentsCount,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  // JSON serialization for API integration
  factory Course.fromJson(Map<String, dynamic> json) {
    print('🎓 Parsing Course JSON: ${json['title']} (ID: ${json['id']})');

    try {
      // Parse modules list
      List<Module> modulesList = [];
      if (json['modules'] != null && json['modules'] is List) {
        modulesList = (json['modules'] as List)
            .map((moduleJson) => Module.fromJson(moduleJson))
            .toList();
        print('   ├─ Found ${modulesList.length} modules in course');

        // Count total videos
        int totalVideos = modulesList.fold(0, (sum, module) => sum + module.videos.length);
        print('   └─ Total videos across all modules: $totalVideos');
      }

      return Course(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Untitled Course',
        description: json['description']?.toString() ?? '',
        thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
        progressPercent: _parseDoubleSafely(json['progressPercent'] ?? json['progress'], 0.0),
        isSubscribed: _parseBoolSafely(json['isSubscribed'] ?? json['setPurchased'], false),
        modules: modulesList,
        instructor: json['instructor']?.toString(),
        rating: _parseDoubleSafely(json['rating'], null),
        studentsCount: _parseIntSafely(json['studentsCount'], null),
        category: json['category']?.toString(),
        createdAt: _parseDateSafely(json['createdAt']),
        updatedAt: _parseDateSafely(json['updatedAt']),
      );
    } catch (e) {
      print('❌ Error parsing Course JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'progressPercent': progressPercent,
      'isSubscribed': isSubscribed,
      'modules': modules.map((module) => module.toJson()).toList(),
      'instructor': instructor,
      'rating': rating,
      'studentsCount': studentsCount,
      'category': category,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Legacy constructor for backward compatibility with existing mock data
  factory Course.legacy({
    required String id,
    required String title,
    required String description,
    required String thumbnailUrl,
    required double progressPercent,
    required bool isSubscribed,
    required List<Module> modules,
  }) {
    print('🔄 Creating legacy Course: $title with ${modules.length} modules');
    return Course(
      id: id,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      progressPercent: progressPercent,
      isSubscribed: isSubscribed,
      modules: modules,
    );
  }


  // ---------- FILTER SAFE GETTERS ----------

  double get safeRating => rating ?? 0.0;

  int get safeStudentsCount => studentsCount ?? 0;

  // int get totalDurationMinutes {
  //   int total = 0;
  //
  //   for (final module in modules) {
  //     for (final video in module.videos) {
  //       total += video.durationMinutes;
  //     }
  //   }
  //
  //   return total;
  // }


  bool get isFree => false; // extend later when price is added

  // Utility methods for safe parsing
  static double _parseDoubleSafely(dynamic value, double? defaultValue) {
    if (value == null) return defaultValue ?? 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? (defaultValue ?? 0.0);
    return defaultValue ?? 0.0;
  }

  static int? _parseIntSafely(dynamic value, int? defaultValue) {
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

  @override
  String toString() => 'Course(id: $id, title: $title, modules: ${modules.length})';
}


