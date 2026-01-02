// Course Model
// Represents course data from the backend
import 'module_model.dart';

String safeUrl(String? url) {
  if (url == null) return '';
  final trimmed = url.trim();
  if (trimmed.isEmpty || trimmed == 'null' || trimmed.startsWith('file:///')) {
    return '';
  }
  if (!trimmed.startsWith('http')) return '';
  return trimmed;
}

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String shortDescription;
  final String instructor;
  final String instructorId;
  final String? thumbnailUrl;
  final String? bannerImage;
  final double price;
  final double? discountPrice;
  final double rating;
  final int totalRatings;
  final int enrolledStudents;
  final int totalDuration; // in minutes
  final String level; // beginner, intermediate, advanced
  final String category;
  final String subCategory;
  final List<String> tags;
  final bool isPublished;
  final bool isFeatured;
  final bool isPopular;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final List<ModuleModel> modules;
  final CourseRequirements? requirements;
  final CourseWhatYouWillLearn? whatYouWillLearn;
  final bool isSubscribed;

  // NEW: Added fields from the first file
  final double progressPercent;
  final int totalVideos;
  final int completedVideos;
  final int totalDurationSec;
  final bool isPurchased;
  final String formattedDuration;
  final int totalModules;
  final int unlockedModules;
  final bool isCompleted;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.shortDescription,
    required this.instructor,
    required this.instructorId,
    this.thumbnailUrl,
    this.bannerImage,
    required this.price,
    this.discountPrice,
    required this.rating,
    required this.totalRatings,
    required this.enrolledStudents,
    required this.totalDuration,
    required this.level,
    required this.category,
    required this.subCategory,
    required this.tags,
    required this.isPublished,
    required this.isFeatured,
    required this.isPopular,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    required this.modules,
    this.requirements,
    this.whatYouWillLearn,
    required this.isSubscribed,

    // NEW: Initialize new fields with default values
    this.progressPercent = 0.0,
    this.totalVideos = 0,
    this.completedVideos = 0,
    this.totalDurationSec = 0,
    this.isPurchased = false,
    this.formattedDuration = '0m',
    this.totalModules = 0,
    this.unlockedModules = 0,
    this.isCompleted = false,
  });

  double get effectivePrice => discountPrice ?? price;

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((price - effectivePrice) / price) * 100;
  }

  String get durationFormatted {
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  int get totalLessons => modules.fold(0, (sum, module) => sum + (module.videos.length ?? 0));

  // NEW: Helper method to check if course has specific tag
  bool hasTag(String tag) {
    if (tags.isEmpty) return false;
    return tags.any((courseTag) =>
        courseTag.toLowerCase().contains(tag.toLowerCase()));
  }

  // NEW: Helper method to get first few tags
  List<String> getDisplayTags({int limit = 3}) {
    if (tags.isEmpty) return [];
    return tags.take(limit).toList();
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    print('\n📦 DEBUG CourseModel.fromJson():');
    print('   ├─ Course ID: ${json['id']}');
    print('   ├─ Course Title: ${json['title']}');

    // Parse tags
    List<String> tags = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tags = (json['tags'] as List).map((tag) => tag.toString()).toList();
      }
    }
    print('   ├─ Tags found: $tags');

    // Debug isSubscribed field
    bool isSubscribed = false;
    if (json['isSubscribed'] != null) {
      final raw = json['isSubscribed'];
      if (raw is bool) {
        isSubscribed = raw;
      } else if (raw is int) {
        isSubscribed = raw == 1;
      } else if (raw is String) {
        isSubscribed = raw.toLowerCase() == 'true';
      }
    }

    // Also check purchased field
    bool isPurchased = false;
    if (json['purchased'] != null) {
      final raw = json['purchased'];
      if (raw is bool) {
        isPurchased = raw;
      } else if (raw is int) {
        isPurchased = raw == 1;
      } else if (raw is String) {
        isPurchased = raw.toLowerCase() == 'true';
      }
    }

    // Use either isSubscribed or purchased
    final finalIsSubscribed = isSubscribed || isPurchased;

    // Parse modules
    List<ModuleModel> modules = [];
    if (json['modules'] != null && json['modules'] is List) {
      modules = (json['modules'] as List).map((e) {
        try {
          return ModuleModel.fromJson(e);
        } catch (e) {
          print('   ├─ Error parsing module: $e');
          return ModuleModel(
            id: '0', // Changed from 0 to '0' for String id
            title: 'Unknown Module',
            order: 0,
            durationSec: 0, // ADD THIS
            videos: [],     // ADD THIS - this is the missing parameter
            lessons: null,  // Changed from [] to null
            isLocked: true,
            assessmentLocked: true,
          );
        }
      }).toList();
    }

    // Calculate derived fields
    final totalVideos = modules.fold<int>(0, (sum, module) => sum + module.totalVideos);
    final completedVideos = modules.fold<int>(0, (sum, module) => sum + module.completedVideos);
    final totalModules = modules.length;
    final unlockedModules = modules.where((m) => !m.isLocked).length;
    final progressPercent = totalVideos > 0 ? (completedVideos / totalVideos) * 100 : 0.0;
    final totalDurationSec = json['totalDuration'] != null ? (json['totalDuration'] as int) * 60 : 0;
    final isCompleted = completedVideos == totalVideos && totalVideos > 0;

    // Format duration
    String formattedDuration = '0m';
    if (json['totalDuration'] != null) {
      final hours = (json['totalDuration'] as int) ~/ 60;
      final minutes = (json['totalDuration'] as int) % 60;
      if (hours > 0) {
        formattedDuration = minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
      } else {
        formattedDuration = '${minutes}m';
      }
    }

    // Parse dates
    DateTime createdAt;
    try {
      createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }

    DateTime updatedAt;
    try {
      updatedAt = json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now();
    } catch (e) {
      updatedAt = DateTime.now();
    }

    DateTime? publishedAt;
    if (json['publishedAt'] != null) {
      try {
        publishedAt = DateTime.tryParse(json['publishedAt'].toString());
      } catch (e) {
        publishedAt = null;
      }
    }

    return CourseModel(
      id: json['id']?.toString() ?? '0',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      shortDescription: json['shortDescription']?.toString() ?? '',
      instructor: json['instructor']?.toString() ?? '',
      instructorId: json['instructorId']?.toString() ?? '',
      thumbnailUrl: safeUrl(json['thumbnailUrl']?.toString()),
      bannerImage: safeUrl(json['bannerImage']?.toString()),
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discountPrice']?.toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      enrolledStudents: json['enrolledStudents'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      level: json['level']?.toString() ?? 'beginner',
      category: json['category']?.toString() ?? '',
      subCategory: json['subCategory']?.toString() ?? '',
      tags: tags,
      isPublished: json['isPublished'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      isPopular: json['isPopular'] ?? false,
      isSubscribed: finalIsSubscribed,
      createdAt: createdAt,
      updatedAt: updatedAt,
      publishedAt: publishedAt,
      modules: modules,
      requirements: json['requirements'] != null
          ? CourseRequirements.fromJson(json['requirements'])
          : null,
      whatYouWillLearn: json['whatYouWillLearn'] != null
          ? CourseWhatYouWillLearn.fromJson(json['whatYouWillLearn'])
          : null,

      // NEW: Add calculated fields
      progressPercent: progressPercent,
      totalVideos: totalVideos,
      completedVideos: completedVideos,
      totalDurationSec: totalDurationSec,
      isPurchased: isPurchased,
      formattedDuration: formattedDuration,
      totalModules: totalModules,
      unlockedModules: unlockedModules,
      isCompleted: isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'shortDescription': shortDescription,
      'instructor': instructor,
      'instructorId': instructorId,
      'thumbnailUrl': thumbnailUrl,
      'bannerImage': bannerImage,
      'price': price,
      'discountPrice': discountPrice,
      'rating': rating,
      'totalRatings': totalRatings,
      'enrolledStudents': enrolledStudents,
      'totalDuration': totalDuration,
      'level': level,
      'category': category,
      'subCategory': subCategory,
      'tags': tags,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'isPopular': isPopular,
      'isSubscribed': isSubscribed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'modules': modules.map((e) => e.toJson()).toList(),
      'requirements': requirements?.toJson(),
      'whatYouWillLearn': whatYouWillLearn?.toJson(),
      'progressPercent': progressPercent,
      'totalVideos': totalVideos,
      'completedVideos': completedVideos,
      'totalDurationSec': totalDurationSec,
      'isPurchased': isPurchased,
      'formattedDuration': formattedDuration,
      'totalModules': totalModules,
      'unlockedModules': unlockedModules,
      'isCompleted': isCompleted,
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? shortDescription,
    String? instructor,
    String? instructorId,
    String? thumbnailUrl,
    String? bannerImage,
    double? price,
    double? discountPrice,
    double? rating,
    int? totalRatings,
    int? enrolledStudents,
    int? totalDuration,
    String? level,
    String? category,
    String? subCategory,
    List<String>? tags,
    bool? isPublished,
    bool? isFeatured,
    bool? isPopular,
    bool? isSubscribed,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    List<ModuleModel>? modules,
    CourseRequirements? requirements,
    CourseWhatYouWillLearn? whatYouWillLearn,
    double? progressPercent,
    int? totalVideos,
    int? completedVideos,
    int? totalDurationSec,
    bool? isPurchased,
    String? formattedDuration,
    int? totalModules,
    int? unlockedModules,
    bool? isCompleted,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      instructor: instructor ?? this.instructor,
      instructorId: instructorId ?? this.instructorId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      bannerImage: bannerImage ?? this.bannerImage,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      totalDuration: totalDuration ?? this.totalDuration,
      level: level ?? this.level,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      tags: tags ?? this.tags,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      isPopular: isPopular ?? this.isPopular,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      modules: modules ?? this.modules,
      requirements: requirements ?? this.requirements,
      whatYouWillLearn: whatYouWillLearn ?? this.whatYouWillLearn,
      progressPercent: progressPercent ?? this.progressPercent,
      totalVideos: totalVideos ?? this.totalVideos,
      completedVideos: completedVideos ?? this.completedVideos,
      totalDurationSec: totalDurationSec ?? this.totalDurationSec,
      isPurchased: isPurchased ?? this.isPurchased,
      formattedDuration: formattedDuration ?? this.formattedDuration,
      totalModules: totalModules ?? this.totalModules,
      unlockedModules: unlockedModules ?? this.unlockedModules,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class CourseRequirements {
  final List<String> prerequisites;
  final List<String> equipment;
  final String minimumLevel;

  CourseRequirements({
    required this.prerequisites,
    required this.equipment,
    required this.minimumLevel,
  });

  factory CourseRequirements.fromJson(Map<String, dynamic> json) {
    return CourseRequirements(
      prerequisites: (json['prerequisites'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      equipment: (json['equipment'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      minimumLevel: json['minimumLevel']?.toString() ?? 'beginner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prerequisites': prerequisites,
      'equipment': equipment,
      'minimumLevel': minimumLevel,
    };
  }
}

class CourseWhatYouWillLearn {
  final List<String> outcomes;
  final List<String> skills;
  final String certificate;

  CourseWhatYouWillLearn({
    required this.outcomes,
    required this.skills,
    required this.certificate,
  });

  factory CourseWhatYouWillLearn.fromJson(Map<String, dynamic> json) {
    return CourseWhatYouWillLearn(
      outcomes: (json['outcomes'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      skills: (json['skills'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      certificate: json['certificate']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outcomes': outcomes,
      'skills': skills,
      'certificate': certificate,
    };
  }
}