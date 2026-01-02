/// Module Model - Combined Version
/// Works with both video-based and lesson-based structures
import '../module_model.dart';
import 'video_model.dart';

class ModuleModel {
  final String id; // Changed from int to String for compatibility
  final String title;
  final int order; // For first model compatibility
  final int orderIndex; // For second model compatibility
  final int durationSec; // For first model (seconds)
  final int duration; // For second model (minutes)
  final List<VideoModel> videos; // First model uses videos
  final List<LessonModel>? lessons; // Second model uses lessons
  final bool isLocked;
  final bool assessmentLocked;
  final String? description;
  final String? courseId;
  final bool? isPublished;
  final bool? isPreview;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ModuleProgress? progress;

  ModuleModel({
    required this.id,
    required this.title,
    this.order = 0,
    this.orderIndex = 0,
    this.durationSec = 0,
    this.duration = 0,
    required this.videos,
    this.lessons,
    required this.isLocked,
    this.assessmentLocked = true,
    this.description,
    this.courseId,
    this.isPublished,
    this.isPreview,
    this.createdAt,
    this.updatedAt,
    this.progress,
  });

  // Getters for consistent access
  bool get isModuleLocked => isLocked;
  bool get isAssessmentLocked => assessmentLocked;

  // Duration formatting - works with both seconds and minutes
  String get formattedDuration {
    // Use durationSec if available, otherwise convert minutes to seconds
    final totalSeconds = durationSec > 0 ? durationSec : duration * 60;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  // Progress calculations
  int get totalVideos => videos.length;
  int get completedVideos => videos.where((v) => v.isCompleted).length;

  // For lesson-based modules
  int get totalLessons => lessons?.length ?? 0;
  int get completedLessons => progress?.completedLessons ?? 0;

  double get progressPercentage {
    if (videos.isNotEmpty) {
      // Video-based calculation
      if (totalVideos == 0) return 0.0;
      return (completedVideos / totalVideos) * 100;
    } else if (lessons != null && lessons!.isNotEmpty) {
      // Lesson-based calculation
      if (totalLessons == 0) return 0.0;
      return (completedLessons / totalLessons) * 100;
    }
    return 0.0;
  }

  bool get isCompleted {
    if (videos.isNotEmpty) {
      return completedVideos == totalVideos && totalVideos > 0;
    } else if (lessons != null && lessons!.isNotEmpty) {
      return progress?.isCompleted ?? false;
    }
    return false;
  }

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    // Determine if we have a video-based or lesson-based module
    final hasVideos = json['videos'] != null && (json['videos'] as List).isNotEmpty;
    final hasLessons = json['lessons'] != null && (json['lessons'] as List).isNotEmpty;

    // Parse videos if available
    List<VideoModel> videos = [];
    if (hasVideos) {
      videos = (json['videos'] as List<dynamic>)
          .map((e) => VideoModel.fromJson(e))
          .toList();
    }

    // Parse lessons if available
    List<LessonModel>? lessons;
    if (hasLessons) {
      lessons = (json['lessons'] as List<dynamic>)
          .map((e) => LessonModel.fromJson(e))
          .toList();
    }

    // Handle ID - could be int or string
    String id;
    if (json['id'] is String) {
      id = json['id'];
    } else if (json['id'] is int) {
      id = json['id'].toString();
    } else {
      id = '0';
    }

    // Handle dates
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        createdAt = null;
      }
    }

    DateTime? updatedAt;
    if (json['updatedAt'] != null) {
      try {
        updatedAt = DateTime.parse(json['updatedAt'].toString());
      } catch (e) {
        updatedAt = null;
      }
    }

    return ModuleModel(
      id: id,
      title: json['title']?.toString() ?? '',
      order: (json['order'] ?? 0) as int,
      orderIndex: (json['orderIndex'] ?? 0) as int,
      durationSec: (json['durationSec'] ?? 0) as int,
      duration: (json['duration'] ?? 0) as int,
      videos: videos,
      lessons: lessons,
      isLocked: json['isLocked'] ?? json['locked'] ?? true,
      assessmentLocked: json['assessmentLocked'] ?? true,
      description: json['description']?.toString(),
      courseId: json['courseId']?.toString(),
      isPublished: json['isPublished'],
      isPreview: json['isPreview'],
      createdAt: createdAt,
      updatedAt: updatedAt,
      progress: json['progress'] != null
          ? ModuleProgress.fromJson(json['progress'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'order': order,
      'orderIndex': orderIndex,
      'durationSec': durationSec,
      'duration': duration,
      'videos': videos.map((e) => e.toJson()).toList(),
      'lessons': lessons?.map((e) => e.toJson()).toList(),
      'isLocked': isLocked,
      'assessmentLocked': assessmentLocked,
      'description': description,
      'courseId': courseId,
      'isPublished': isPublished,
      'isPreview': isPreview,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'progress': progress?.toJson(),
    };
  }

  ModuleModel copyWith({
    String? id,
    String? title,
    int? order,
    int? orderIndex,
    int? durationSec,
    int? duration,
    List<VideoModel>? videos,
    List<LessonModel>? lessons,
    bool? isLocked,
    bool? assessmentLocked,
    String? description,
    String? courseId,
    bool? isPublished,
    bool? isPreview,
    DateTime? createdAt,
    DateTime? updatedAt,
    ModuleProgress? progress,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      order: order ?? this.order,
      orderIndex: orderIndex ?? this.orderIndex,
      durationSec: durationSec ?? this.durationSec,
      duration: duration ?? this.duration,
      videos: videos ?? this.videos,
      lessons: lessons ?? this.lessons,
      isLocked: isLocked ?? this.isLocked,
      assessmentLocked: assessmentLocked ?? this.assessmentLocked,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      isPublished: isPublished ?? this.isPublished,
      isPreview: isPreview ?? this.isPreview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progress: progress ?? this.progress,
    );
  }
}

// Keep all your existing LessonModel, ModuleProgress, LessonProgress classes
// They remain exactly as you provided