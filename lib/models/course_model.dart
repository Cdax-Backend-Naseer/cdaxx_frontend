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
  });

  double get effectivePrice => discountPrice ?? price;

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((price - effectivePrice) / price) * 100;
  }

  String get formattedDuration {
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  int get totalLessons => modules.fold(0, (sum, module) => sum + (module.lessons.length));

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    print('\n📦 DEBUG CourseModel.fromJson():');
    print('   ├─ Course ID: ${json['id']}');
    print('   ├─ Course Title: ${json['title']}');

    // Debug isSubscribed field
    print('   ├─ isSubscribed raw value: ${json['isSubscribed']}');
    print('   ├─ isSubscribed type: ${json['isSubscribed']?.runtimeType}');
    print('   ├─ isSubscribed is null? ${json['isSubscribed'] == null}');
    print('   ├─ isSubscribed == true? ${json['isSubscribed'] == true}');
    print('   ├─ isSubscribed == "true"? ${json['isSubscribed'] == "true"}');
    print('   ├─ isSubscribed == 1? ${json['isSubscribed'] == 1}');

    // Try to parse isSubscribed
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
      print('   ├─ Parsed isSubscribed: $isSubscribed');
    }

    return CourseModel(
      id: json['id']?.toString() ?? '',
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
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isPublished: json['isPublished'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      isPopular: json['isPopular'] ?? false,
      isSubscribed: isSubscribed,  // Use parsed value
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      modules: (json['modules'] as List<dynamic>?)
          ?.map((e) => ModuleModel.fromJson(e))
          .toList() ?? [],
      requirements: json['requirements'] != null
          ? CourseRequirements.fromJson(json['requirements'])
          : null,
      whatYouWillLearn: json['whatYouWillLearn'] != null
          ? CourseWhatYouWillLearn.fromJson(json['whatYouWillLearn'])
          : null,
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
    };
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? shortDescription,
    String? instructor,
    String? instructorId,
    String? thumbnailImage,
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
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      instructor: instructor ?? this.instructor,
      instructorId: instructorId ?? this.instructorId,
      thumbnailUrl: thumbnailImage ?? this.thumbnailUrl,
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