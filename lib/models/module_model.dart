/// Module Model
/// Represents course module/chapter data from the backend
class ModuleModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int orderIndex;
  final int duration; // in minutes
  final bool isPublished;
  final bool isPreview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocked;
  final List<LessonModel> lessons;
  final ModuleProgress? progress;
  
  ModuleModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.duration,
    required this.isPublished,
    required this.isPreview,
    required this.createdAt,
    required this.updatedAt,
    required this.isLocked,
    required this.lessons,
    this.progress,
  });
  
  int get totalLessons => lessons.length;
  
  int get completedLessons => progress?.completedLessons ?? 0;
  
  double get progressPercentage {
    if (totalLessons == 0) return 0.0;
    return (completedLessons / totalLessons) * 100;
  }
  
  bool get isCompleted => completedLessons == totalLessons;
  
  String get formattedDuration {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }




  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      orderIndex: json['orderIndex'] ?? 0,
      duration: json['duration'] ?? 0,
      isLocked: json['isLocked'] ?? false,
      isPublished: json['isPublished'] ?? false,
      isPreview: json['isPreview'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      lessons: (json['lessons'] as List<dynamic>?)
          ?.map((e) => LessonModel.fromJson(e))
          .toList() ?? [],
      progress: json['progress'] != null 
          ? ModuleProgress.fromJson(json['progress'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'orderIndex': orderIndex,
      'duration': duration,
      'isPublished': isPublished,
      'isPreview': isPreview,
      'isLocked': isLocked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lessons': lessons.map((e) => e.toJson()).toList(),
      'progress': progress?.toJson(),
    };
  }
  
  ModuleModel copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    int? orderIndex,
    int? duration,
    bool? isPublished,
    bool? isPreview,
    bool ? isLocked,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LessonModel>? lessons,
    ModuleProgress? progress,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      duration: duration ?? this.duration,
      isPublished: isPublished ?? this.isPublished,
      isPreview: isPreview ?? this.isPreview,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lessons: lessons ?? this.lessons,
      progress: progress ?? this.progress,
    );
  }
}

class LessonModel {
  final String id;
  final String moduleId;
  final String title;
  final String description;
  final String type; // video, text, quiz, assignment
  final String? content;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int orderIndex;
  final int duration; // in minutes
  final bool isPreview;
  final bool isRequired;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LessonProgress? progress;
  
  LessonModel({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.type,
    this.content,
    this.videoUrl,
    this.thumbnailUrl,
    required this.orderIndex,
    required this.duration,
    required this.isPreview,
    required this.isRequired,
    required this.createdAt,
    required this.updatedAt,
    this.progress,
  });
  
  bool get isCompleted => progress?.isCompleted ?? false;
  
  bool get isVideo => type.toLowerCase() == 'video';
  
  bool get isQuiz => type.toLowerCase() == 'quiz';
  
  bool get isAssignment => type.toLowerCase() == 'assignment';
  
  String get formattedDuration {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }
  
  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id']?.toString() ?? '',
      moduleId: json['moduleId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      content: json['content']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      orderIndex: json['orderIndex'] ?? 0,
      duration: json['duration'] ?? 0,
      isPreview: json['isPreview'] ?? false,
      isRequired: json['isRequired'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      progress: json['progress'] != null 
          ? LessonProgress.fromJson(json['progress'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moduleId': moduleId,
      'title': title,
      'description': description,
      'type': type,
      'content': content,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'orderIndex': orderIndex,
      'duration': duration,
      'isPreview': isPreview,
      'isRequired': isRequired,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'progress': progress?.toJson(),
    };
  }
  
  LessonModel copyWith({
    String? id,
    String? moduleId,
    String? title,
    String? description,
    String? type,
    String? content,
    String? videoUrl,
    String? thumbnailUrl,
    int? orderIndex,
    int? duration,
    bool? isPreview,
    bool? isRequired,
    DateTime? createdAt,
    DateTime? updatedAt,
    LessonProgress? progress,
  }) {
    return LessonModel(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      content: content ?? this.content,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      orderIndex: orderIndex ?? this.orderIndex,
      duration: duration ?? this.duration,
      isPreview: isPreview ?? this.isPreview,
      isRequired: isRequired ?? this.isRequired,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progress: progress ?? this.progress,
    );
  }
}

class ModuleProgress {
  final String moduleId;
  final String userId;
  final int completedLessons;
  final int totalLessons;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime lastAccessedAt;
  
  ModuleProgress({
    required this.moduleId,
    required this.userId,
    required this.completedLessons,
    required this.totalLessons,
    required this.isCompleted,
    this.completedAt,
    required this.lastAccessedAt,
  });
  
  double get progressPercentage {
    if (totalLessons == 0) return 0.0;
    return (completedLessons / totalLessons) * 100;
  }
  
  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleId: json['moduleId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      completedLessons: json['completedLessons'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      lastAccessedAt: json['lastAccessedAt'] != null 
          ? DateTime.parse(json['lastAccessedAt'].toString())
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'userId': userId,
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
    };
  }
}

class LessonProgress {
  final String lessonId;
  final String userId;
  final bool isCompleted;
  final int watchedDuration; // in seconds
  final int totalDuration; // in seconds
  final DateTime? completedAt;
  final DateTime lastAccessedAt;
  
  LessonProgress({
    required this.lessonId,
    required this.userId,
    required this.isCompleted,
    required this.watchedDuration,
    required this.totalDuration,
    this.completedAt,
    required this.lastAccessedAt,
  });
  
  double get progressPercentage {
    if (totalDuration == 0) return 0.0;
    return (watchedDuration / totalDuration) * 100;
  }
  
  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      lessonId: json['lessonId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      isCompleted: json['isCompleted'] ?? false,
      watchedDuration: json['watchedDuration'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      completedAt: json['completedAt'] != null 
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      lastAccessedAt: json['lastAccessedAt'] != null 
          ? DateTime.parse(json['lastAccessedAt'].toString())
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'userId': userId,
      'isCompleted': isCompleted,
      'watchedDuration': watchedDuration,
      'totalDuration': totalDuration,
      'completedAt': completedAt?.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
    };
  }
}