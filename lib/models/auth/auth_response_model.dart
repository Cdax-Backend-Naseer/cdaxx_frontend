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
    print('🔍 DEBUG: AuthResponse.fromJson called');
    print('   ├─ JSON keys: ${json.keys.toList()}');
    print('   ├─ success: ${json['success']}');
    print('   ├─ message: ${json['message']}');
    print('   ├─ has user field: ${json.containsKey('user')}');

    // Handle JWT response format
    bool isSuccess = json['success'] == true;
    String message = json['message']?.toString() ?? json['msg']?.toString() ?? '';

    // Extract token (could be in 'token' or 'data.token' for JWT responses)
    String? token;
    if (json['token'] != null) {
      token = json['token'].toString();
    } else if (json['data'] is Map && json['data']['token'] != null) {
      token = json['data']['token'].toString();
    }

    // Extract user (could be directly in response or in 'data.user')
    UserModel? user;
    if (json['user'] != null) {
      user = UserModel.fromJson(json['user']);
    } else if (json['data'] is Map && json['data']['user'] != null) {
      user = UserModel.fromJson(json['data']['user']);
    }

    return AuthResponse(
      success: isSuccess,
      message: message,
      token: token,
      refreshToken: json['refreshToken']?.toString(),
      user: user,
      additionalData: json['data'] ?? json,
    );
  }

  // Factory constructor for JWT responses
  factory AuthResponse.fromJWTResponse(Map<String, dynamic> json) {
    print('🔍 DEBUG: AuthResponse.fromJWTResponse called');
    print('   ├─ JSON keys: ${json.keys.toList()}');

    final isSuccess = json['success'] == true;
    final message = json['message']?.toString() ?? '';
    final token = json['token']?.toString();

    UserModel? user;
    if (json['user'] != null) {
      user = UserModel.fromJson(json['user']);
    }

    return AuthResponse(
      success: isSuccess,
      message: message,
      token: token,
      user: user,
      additionalData: json,
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
    return 'AuthResponse(success: $success, message: $message, hasToken: ${token != null}, hasUser: ${user != null})';
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

  // Helper to parse ID safely
  static String _parseIdSafely(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is num) return value.toString();
    return value.toString();
  }

  // Helper to parse isNewUser safely
  static bool _parseIsNewUserSafely(dynamic value) {
    if (value == null) return true; // Default to true for safety

    print('🔍 DEBUG: Parsing isNewUser - raw value: $value (type: ${value.runtimeType})');

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      if (value == '1' || value.toLowerCase() == 'true') return true;
      if (value == '0' || value.toLowerCase() == 'false') return false;
    }

    // Default
    return true;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('🔍 DEBUG: UserModel.fromJson called (in auth_response_model.dart)');
    print('   ├─ JSON keys: ${json.keys.toList()}');
    print('   ├─ id: ${json['id']} (type: ${json['id']?.runtimeType})');
    print('   ├─ email: ${json['email']}');
    print('   ├─ firstName: ${json['firstName']}');
    print('   ├─ lastName: ${json['lastName']}');
    print('   ├─ phoneNumber: ${json['phoneNumber']}');
    print('   ├─ isNewUser: ${json['isNewUser']} (type: ${json['isNewUser']?.runtimeType})');

    try {
      return UserModel(
        id: _parseIdSafely(json['id']),
        email: json['email']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString() ?? json['phone_number']?.toString(),
        profileImage: json['profileImage']?.toString() ?? json['profile_image']?.toString(),
        address: json['address']?.toString(),
        role: json['role']?.toString() ?? 'USER',
        isActive: json['isActive'] is bool? ? (json['isActive'] ?? true) :
        (json['isActive'] == 1 || json['isActive'] == true),
        isEmailVerified: json['isEmailVerified'] is bool? ? (json['isEmailVerified'] ?? false) :
        (json['isEmailVerified'] == 1 || json['isEmailVerified'] == true),
        isNewUser: _parseIsNewUserSafely(json['isNewUser']),
        isSubscribed: json['isSubscribed'] == true || json['subscribed'] == true,
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
    } catch (e) {
      print('❌ ERROR in UserModel.fromJson: $e');
      print('❌ Stack trace: ${e.toString()}');

      // Return a default user object to prevent crash
      return UserModel(
        id: _parseIdSafely(json['id']),
        email: json['email']?.toString() ?? 'error@example.com',
        firstName: json['firstName']?.toString() ?? 'Error',
        lastName: json['lastName']?.toString() ?? 'User',
        role: 'USER',
        isActive: true,
        isEmailVerified: false,
        isNewUser: true,
        isSubscribed: false,
      );
    }
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

/// JWT-specific response model (optional, for type safety)
class JWTResponse {
  final bool success;
  final String message;
  final String token;
  final UserModel user;

  JWTResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.user,
  });

  factory JWTResponse.fromJson(Map<String, dynamic> json) {
    return JWTResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'user': user.toJson(),
    };
  }
}