// lib/models/streak_model.dart - FIXED VERSION
class StreakModel {
  final String courseId;
  final String courseTitle;
  final int currentStreakDays;
  final int longestStreakDays;
  final double overallProgress;
  final DateTime? lastActiveDate;
  final List<StreakDayModel> last30Days;

  StreakModel({
    required this.courseId,
    required this.courseTitle,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.overallProgress,
    this.lastActiveDate,
    required this.last30Days,
  });

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    print('🔍 PARSING STREAK JSON: ${json.keys}');

    return StreakModel(
      // ✅ Handle snake_case (what API actually returns)
      courseId: (json['course_id'] ?? '').toString(),
      courseTitle: json['course_title'] ?? '',
      currentStreakDays: json['current_streak_days'] ?? 0,
      longestStreakDays: json['longest_streak_days'] ?? 0,
      overallProgress: (json['overall_progress'] ?? 0).toDouble(),
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.parse(json['last_active_date'])
          : null,
      last30Days: ((json['last30_days'] ?? json['last30Days']) as List? ?? [])
          .map((day) => StreakDayModel.fromJson(day))
          .toList(),
    );
  }
}

class StreakDayModel {
  final DateTime date;
  final int watchedSeconds;
  final int totalAvailableSeconds;
  final double progressPercentage;
  final bool isActiveDay;
  final String colorCode;

  StreakDayModel({
    required this.date,
    required this.watchedSeconds,
    required this.totalAvailableSeconds,
    required this.progressPercentage,
    required this.isActiveDay,
    required this.colorCode,
  });

  factory StreakDayModel.fromJson(Map<String, dynamic> json) {
    return StreakDayModel(
      date: DateTime.parse(json['date']),
      // ✅ Handle snake_case
      watchedSeconds: json['watched_seconds'] ?? json['watchedSeconds'] ?? 0,
      totalAvailableSeconds: json['total_available_seconds'] ?? json['totalAvailableSeconds'] ?? 0,
      progressPercentage: (json['progress_percentage'] ?? json['progressPercentage'] ?? 0).toDouble(),
      isActiveDay: json['is_active_day'] ?? json['isActiveDay'] ?? false,
      colorCode: json['color_code'] ?? json['colorCode'] ?? '#E5E7EB',
    );
  }
}