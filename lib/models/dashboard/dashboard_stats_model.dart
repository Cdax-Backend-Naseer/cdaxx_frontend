class DashboardStatsModel {
  final int totalCourses;
  final int completedCourses;
  final int inProgressCourses;
  final int totalVideos;
  final int completedVideos;
  final int overallProgress;
  final int completedModules;

  // NEW: Add course breakdown
  final List<CourseStat> courseStats;
  final int? selectedCourseId; // Which course is currently selected
  final CourseStat? selectedCourseStat; // Stats for selected course

  DashboardStatsModel({
    required this.totalCourses,
    required this.completedCourses,
    required this.inProgressCourses,
    required this.totalVideos,

    required this.completedVideos,
    required this.overallProgress,
    required this.completedModules,
    this.courseStats = const [], // NEW
    this.selectedCourseId, // NEW
    this.selectedCourseStat, // NEW
  });

  // NEW: Helper method to get course stat by ID
  CourseStat? getCourseStat(int courseId) {
    return courseStats.firstWhere(
          (stat) => stat.courseId == courseId,
    );
  }

  // NEW: Method to create a copy with selected course
  DashboardStatsModel copyWithSelectedCourse(int? courseId) {
    return DashboardStatsModel(
      totalCourses: totalCourses,
      completedCourses: completedCourses,
      inProgressCourses: inProgressCourses,
      totalVideos: totalVideos,
      completedVideos: completedVideos,
      overallProgress: overallProgress,
      completedModules: completedModules,
      courseStats: courseStats,
      selectedCourseId: courseId,
      selectedCourseStat: courseId != null ? getCourseStat(courseId) : null,
    );
  }

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    // Parse course stats if available
    List<CourseStat> courseStats = [];
    if (json['courseStats'] != null && json['courseStats'] is List) {
      courseStats = (json['courseStats'] as List)
          .map((e) => CourseStat.fromJson(e))
          .toList();
    }
    // Check for selected course data
    int? selectedCourseId;
    CourseStat? selectedCourseStat;

    if (json['selectedCourseId'] != null) {
      selectedCourseId = json['selectedCourseId'] as int;

      // Find the selected course in courseStats
      if (courseStats.isNotEmpty) {
        selectedCourseStat = courseStats.firstWhere(
              (stat) => stat.courseId == selectedCourseId,
          orElse: () => CourseStat(
            courseId: selectedCourseId!,
            courseTitle: 'Unknown Course',
            totalVideos: 0,
            completedVideos: 0,
            totalModules: 0,
            completedModules: 0,
            progressPercent: 0,
            isCompleted: false,
          ),
        );
      }
    }

    return DashboardStatsModel(
      totalCourses: json['totalCourses'] as int? ?? 0,
      completedCourses: json['completedCourses'] as int? ?? 0,
      inProgressCourses: json['inProgressCourses'] as int? ?? 0,
      totalVideos: json['totalVideos'] as int? ?? 0,
      completedVideos: json['completedVideos'] as int? ?? 0,
      overallProgress: json['overallProgress'] as int? ?? 0,
      completedModules: json['completedModules'] as int? ?? 0,
      courseStats: courseStats,
      selectedCourseId: selectedCourseId,
      selectedCourseStat: selectedCourseStat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCourses': totalCourses,
      'completedCourses': completedCourses,
      'inProgressCourses': inProgressCourses,
      'totalVideos': totalVideos,
      'completedVideos': completedVideos,
      'overallProgress': overallProgress,
      'completedModules': completedModules,
      'courseStats': courseStats.map((e) => e.toJson()).toList(), // NEW
      'selectedCourseId': selectedCourseId, // NEW
    };
  }
}

// NEW: Course-specific statistics model
class CourseStat {
  final int courseId;
  final String courseTitle;
  final int totalVideos;
  final int completedVideos;
  final int totalModules;
  final int completedModules;
  final int progressPercent;
  final bool isCompleted;

  CourseStat({
    required this.courseId,
    required this.courseTitle,
    required this.totalVideos,
    required this.completedVideos,
    required this.totalModules,
    required this.completedModules,
    required this.progressPercent,
    required this.isCompleted,
  });

  factory CourseStat.fromJson(Map<String, dynamic> json) {
    return CourseStat(
      courseId: json['courseId'] as int,
      courseTitle: json['courseTitle'] as String,
      totalVideos: json['totalVideos'] as int? ?? 0,
      completedVideos: json['completedVideos'] as int? ?? 0,
      totalModules: json['totalModules'] as int? ?? 0,
      completedModules: json['completedModules'] as int? ?? 0,
      progressPercent: json['progressPercent'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseTitle': courseTitle,
      'totalVideos': totalVideos,
      'completedVideos': completedVideos,
      'totalModules': totalModules,
      'completedModules': completedModules,
      'progressPercent': progressPercent,
      'isCompleted': isCompleted,
    };
  }
}