// lib/models/streak_model.dart
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
    return StreakModel(
      courseId: json['courseId']?.toString() ?? '',
      courseTitle: json['courseTitle'] ?? '',
      currentStreakDays: json['currentStreakDays'] ?? 0,
      longestStreakDays: json['longestStreakDays'] ?? 0,
      overallProgress: (json['overallProgress'] ?? 0).toDouble(),
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.parse(json['lastActiveDate'])
          : null,
      last30Days: (json['last30Days'] as List? ?? [])
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
      watchedSeconds: json['watchedSeconds'] ?? 0,
      totalAvailableSeconds: json['totalAvailableSeconds'] ?? 0,
      progressPercentage: (json['progressPercentage'] ?? 0).toDouble(),
      isActiveDay: json['isActiveDay'] ?? false,
      colorCode: json['colorCode'] ?? '#E5E7EB',
    );
  }
}