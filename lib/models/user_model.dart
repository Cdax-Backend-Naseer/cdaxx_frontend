/// User Model
/// Represents user data from the backend
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? profileImage;
  final DateTime? dateOfBirth;
  final String? address;
  final String role;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isNewUser;
  final UserPreferences? preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profileImage,
    this.dateOfBirth,
    this.address,
    required this.role,
    required this.isActive,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
    required this.isNewUser,
  });

  String get fullName => '$firstName $lastName';

  String get displayName => fullName.isNotEmpty ? fullName : email;

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
    print('🔍 DEBUG: UserModel.fromJson called');
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
        phoneNumber: json['phoneNumber']?.toString(),
        profileImage: json['profileImage']?.toString(),
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.tryParse(json['dateOfBirth'].toString())
            : null,
        address: json['address']?.toString(),
        role: json['role']?.toString() ?? 'USER',
        isActive: json['isActive'] is bool? ? (json['isActive'] ?? true) :
        (json['isActive'] == 1 || json['isActive'] == true),
        isEmailVerified: json['isEmailVerified'] is bool? ? (json['isEmailVerified'] ?? false) :
        (json['isEmailVerified'] == 1 || json['isEmailVerified'] == true),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        preferences: json['preferences'] != null
            ? UserPreferences.fromJson(json['preferences'])
            : null,
        isNewUser: _parseIsNewUserSafely(json['isNewUser']),
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isNewUser: true,
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
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'address': address,
      'role': role,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences?.toJson(),
      'isNewUser': isNewUser,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImage,
    DateTime? dateOfBirth,
    String? address,
    String? role,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserPreferences? preferences,
    bool? isNewUser,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, isNewUser: $isNewUser)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// User Preferences Model
class UserPreferences {
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final String theme; // 'light', 'dark', 'system'
  final String language;
  final bool analyticsEnabled;

  UserPreferences({
    required this.notificationsEnabled,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.theme,
    required this.language,
    required this.analyticsEnabled,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
      theme: json['theme']?.toString() ?? 'system',
      language: json['language']?.toString() ?? 'en',
      analyticsEnabled: json['analyticsEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'theme': theme,
      'language': language,
      'analyticsEnabled': analyticsEnabled,
    };
  }

  UserPreferences copyWith({
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    String? theme,
    String? language,
    bool? analyticsEnabled,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}