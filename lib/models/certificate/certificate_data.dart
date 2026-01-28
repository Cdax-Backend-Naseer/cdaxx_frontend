// models/certificate/certificate_data.dart
class CertificateData {
  final double? grade;
  final int totalModules;
  final int completedModules;
  final String? completionDuration;
  final String? instructorName;
  final Map<String, dynamic> additionalData;

  CertificateData({
    this.grade,
    required this.totalModules,
    required this.completedModules,
    this.completionDuration,
    this.instructorName,
    this.additionalData = const {},
  });

  factory CertificateData.fromJson(Map<String, dynamic> json) {
    return CertificateData(
      grade: json['grade']?.toDouble(),
      totalModules: json['totalModules'] ?? json['total_modules'] ?? 0,
      completedModules: json['completedModules'] ?? json['completed_modules'] ?? 0,
      completionDuration: json['completionDuration'] ?? json['completion_duration'],
      instructorName: json['instructorName'] ?? json['instructor_name'],
      additionalData: json['additionalData'] ?? json['additional_data'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grade': grade,
      'totalModules': totalModules,
      'completedModules': completedModules,
      'completionDuration': completionDuration,
      'instructorName': instructorName,
      'additionalData': additionalData,
    };
  }
}