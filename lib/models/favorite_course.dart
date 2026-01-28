// models/favorite_course.dart
class FavoriteCourse {
  final String id;
  final String courseId;
  final String courseTitle;
  final String courseThumbnail;
  final double coursePrice;
  final DateTime addedAt;

  FavoriteCourse({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.courseThumbnail,
    required this.coursePrice,
    required this.addedAt,
  });

  factory FavoriteCourse.fromJson(Map<String, dynamic> json) {
    return FavoriteCourse(
      id: json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      courseTitle: json['courseTitle'] ?? 'Untitled Course',
      courseThumbnail: json['courseThumbnail'] ?? '',
      coursePrice: (json['coursePrice'] ?? 0.0).toDouble(),
      addedAt: DateTime.parse(json['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'courseThumbnail': courseThumbnail,
      'coursePrice': coursePrice,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}