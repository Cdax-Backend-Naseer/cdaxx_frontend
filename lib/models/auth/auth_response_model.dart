/// Authentication Response Model
/// Represents the response from authentication endpoints
class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final String? refreshToken;
  final UserModel? user;
  final Map<String, dynamic>? additionalData;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.refreshToken,
    this.user,
    this.additionalData,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] == true || json['status'] == 'success',
      message: json['message'] ?? json['msg'] ?? '',
      token: json['token']?.toString() ?? json['accessToken']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      additionalData: json['data'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'refreshToken': refreshToken,
      'user': user?.toJson(),
      'data': additionalData,
    };
  }

  @override
  String toString() {
    return 'AuthResponse(success: $success, message: $message, hasToken: ${token != null})';
  }
}

/// Simple user model for authentication responses
class UserModel {
  final String? id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? profileImage;
  final String? address;
  final String role;
  final bool isActive;
  final bool isEmailVerified;
  final bool isNewUser;
  final bool isSubscribed;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? additionalData;

  UserModel({
    this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profileImage,
    this.address,
    this.role = 'USER',
    this.isActive = true,
    this.isEmailVerified = false,
    this.isNewUser = true,
    this.isSubscribed = false,
    this.createdAt,
    this.updatedAt,
    this.preferences,
    this.additionalData,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : email;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      profileImage: json['profileImage']?.toString(),
      address: json['address']?.toString(),
      role: json['role']?.toString() ?? 'USER',
      isActive: json['isActive'] == true,
      isEmailVerified: json['isEmailVerified'] == true,

      // Handles 0/1 OR true/false
      isNewUser: json['isNewUser'] is bool
          ? json['isNewUser']
          : json['isNewUser'] == 1,

      isSubscribed:
      json['subscribed'] == true || json['isSubscribed'] == true,

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,

      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'])
          : null,

      additionalData: json,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'address': address,
      'role': role,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'isNewUser': isNewUser,
      'isSubscribed': isSubscribed,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'preferences': preferences,
      ...?additionalData,
    };
  }

  @override
  String toString() {
    return 'UserModel(email: $email, fullName: $fullName, isNewUser: $isNewUser)';
  }
}