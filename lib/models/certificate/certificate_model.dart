// models/certificate/certificate_model.dart
class CertificateModel {
  final String id;
  final String userId;
  final String courseId;
  final String certificateNumber;
  final String userName;
  final String courseName;
  final DateTime completionDate;
  final DateTime issuedDate;
  final DateTime? expirationDate;
  final String? certificateUrl;
  final String verificationCode;
  final CertificateData certificateData;
  final bool isActive;

  CertificateModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.certificateNumber,
    required this.userName,
    required this.courseName,
    required this.completionDate,
    required this.issuedDate,
    this.expirationDate,
    this.certificateUrl,
    required this.verificationCode,
    required this.certificateData,
    this.isActive = true,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      courseId: json['courseId'] ?? json['course_id'] ?? '',
      certificateNumber: json['certificateNumber'] ?? json['certificate_number'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      courseName: json['courseName'] ?? json['course_name'] ?? '',
      completionDate: DateTime.parse(json['completionDate'] ?? json['completion_date']),
      issuedDate: DateTime.parse(json['issuedDate'] ?? json['issued_date']),
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'])
          : json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'])
          : null,
      certificateUrl: json['certificateUrl'] ?? json['certificate_url'],
      verificationCode: json['verificationCode'] ?? json['verification_code'] ?? '',
      certificateData: CertificateData.fromJson(json['certificateData'] ?? json['certificate_data'] ?? {}),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'certificateNumber': certificateNumber,
      'userName': userName,
      'courseName': courseName,
      'completionDate': completionDate.toIso8601String(),
      'issuedDate': issuedDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'certificateUrl': certificateUrl,
      'verificationCode': verificationCode,
      'certificateData': certificateData.toJson(),
      'isActive': isActive,
    };
  }
}

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