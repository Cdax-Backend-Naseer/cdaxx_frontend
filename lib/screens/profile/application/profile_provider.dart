// profile_provider.dart - COMPLETE UPDATED VERSION


import 'dart:io';

import 'package:flutter/foundation.dart';
import '../../../services/secure_storage_service.dart';
import '/services/http_service.dart';

@immutable
class UserProfile {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? address;
  final String? dateOfBirth;
  final String? profileImage;
  final String role;
  final bool isNewUser;
  final bool isActive;
  final bool isEmailVerified;
  final int enrolledCoursesCount;
  final bool subscribed;

  // ✅ Add this getter (not a constructor parameter)
  String get name => '$firstName $lastName'.trim();

  // ✅ Phone number alias for compatibility
  String get phone => phoneNumber;

  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.address,
    this.dateOfBirth,
    this.profileImage,
    required this.role,
    required this.isNewUser,
    required this.isActive,
    required this.isEmailVerified,
    this.enrolledCoursesCount = 0,
    this.subscribed = false,
  });

// In profile_provider.dart - Update UserProfile.fromJson()

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    print('👤 UserProfile.fromJson() called');
    print('   ├─ JSON keys: ${json.keys}');

    // ✅ Handle different field names from backend
    final firstName = json['firstName'] ?? json['first_name'] ?? '';
    final lastName = json['lastName'] ?? json['last_name'] ?? '';
    final email = json['email'] ?? '';

    // Phone number might come as 'phoneNumber', 'phone', or 'mobile'
    final phoneNumber = json['phoneNumber'] ??
        json['phone'] ??
        json['mobile'] ??
        '';

    // Address might be nested or direct
    final address = json['address'] ?? json['userAddress'] ?? '';

    // Date of birth might be in different formats
    final dateOfBirth = json['dateOfBirth'] ?? json['dob'] ?? json['date_of_birth'] ?? '';

    // Subscription status
    final subscribed = json['subscribed'] ?? json['isSubscribed'] ?? false;

    // Role might be 'USER' or 'ROLE_USER'
    String role = json['role'] ?? 'USER';
    if (role.startsWith('ROLE_')) {
      role = role.substring(5); // Remove 'ROLE_' prefix
    }

    // Debug print
    print('👤 Parsed values:');
    print('   ├─ firstName: $firstName');
    print('   ├─ lastName: $lastName');
    print('   ├─ email: $email');
    print('   ├─ phoneNumber: $phoneNumber');
    print('   ├─ subscribed: $subscribed');

    return UserProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      address: address.isNotEmpty ? address : null,
      dateOfBirth: dateOfBirth.isNotEmpty ? dateOfBirth : null,
      profileImage: json['profileImage'] ?? json['profile_image'] ?? json['imageUrl'],
      role: role,
      isNewUser: json['isNewUser'] ?? json['newUser'] ?? false,
      isActive: json['isActive'] ?? json['active'] ?? true,
      isEmailVerified: json['isEmailVerified'] ?? json['emailVerified'] ?? false,
      enrolledCoursesCount: json['enrolledCoursesCount'] ??
          json['enrolledCourses']?.length ??
          (json['courses'] as List?)?.length ??
          0,
      subscribed: subscribed,
    );
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? address,
    String? dateOfBirth,
    String? profileImage,
    String? role,
    bool? isNewUser,
    bool? isActive,
    bool? isEmailVerified,
    int? enrolledCoursesCount,
    bool? subscribed,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      isNewUser: isNewUser ?? this.isNewUser,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      enrolledCoursesCount: enrolledCoursesCount ?? this.enrolledCoursesCount,
      subscribed: subscribed ?? this.subscribed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'profileImage': profileImage,
      'role': role,
      'isNewUser': isNewUser,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
    };
  }
}

// Provider using HttpService
class ProfileProvider extends ChangeNotifier {
  final HttpService _httpService = HttpService();

  UserProfile _profile = const UserProfile(
    firstName: '',
    lastName: '',
    email: '',
    phoneNumber: '',
    role: 'ROLE_USER',
    isNewUser: true,
    isActive: true,
    isEmailVerified: false,
    enrolledCoursesCount: 0,
    subscribed: false,
  );

  bool _isLoading = false;
  String? _error;

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

// In profile_provider.dart - COMPLETE FIX

  Future<void> fetchProfile() async {
    print('🔍 ProfileProvider.fetchProfile() called');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use HttpService with JWT token automatically added
      final response = await _httpService.get<Map<String, dynamic>>(
        'auth/profile/me',
            (json) => json as Map<String, dynamic>, // Just return raw JSON
      );

      print('📡 Profile API Response:');
      print('   ├─ Success: ${response.isSuccess}');
      print('   ├─ Status Code: ${response.statusCode}');
      print('   ├─ Has Data: ${response.data != null}');
      print('   ├─ Data Keys: ${response.data?.keys}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        // ✅ FIX 1: Check different response formats
        Map<String, dynamic> userJson;

        if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
          // Format 1: Response has nested "user" object
          userJson = data['user'] as Map<String, dynamic>;
          print('✅ Using nested "user" object');
        } else if (data.containsKey('firstName') || data.containsKey('email')) {
          // Format 2: Response is already the user object
          userJson = data;
          print('✅ Using direct user object');
        } else {
          // Format 3: Response is in a different format
          userJson = data;
          print('⚠️ Unknown response format, trying to parse anyway');
        }

        // ✅ FIX 2: Debug print the user data
        print('👤 Parsed User Data:');
        print('   ├─ firstName: ${userJson['firstName']}');
        print('   ├─ lastName: ${userJson['lastName']}');
        print('   ├─ email: ${userJson['email']}');
        print('   ├─ phoneNumber: ${userJson['phoneNumber']}');
        print('   ├─ all keys: ${userJson.keys}');

        // ✅ FIX 3: Parse the user data
        _profile = UserProfile.fromJson(userJson);

        // ✅ FIX 4: Also save to secure storage for consistency
        await SecureStorageService.instance.saveUserData(userJson);

        print('✅ Profile loaded successfully');
      } else {
        _error = response.errorMessage ?? 'Failed to fetch profile';

        // Debug error
        print('❌ Profile fetch failed:');
        print('   ├─ Error: $_error');
        print('   ├─ Status Code: ${response.statusCode}');

        if (response.statusCode == 401) {
          _error = 'Session expired. Please login again.';
        }
      }
    } catch (e, stackTrace) {
      _error = 'Error: ${e.toString()}';
      print('❌ Exception in fetchProfile: $e');
      print('❌ Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> uploadProfileImage(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📤 Uploading profile image...');

      final response = await _httpService.uploadFile<Map<String, dynamic>>(
        'auth/profile/upload-image',
            (json) => json as Map<String, dynamic>,
        file: imageFile,
        fieldName: 'file',
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        if (data['success'] == true) {
          final imageUrl = data['imageUrl'];

          if (imageUrl != null) {
            // Update local profile
            _profile = _profile.copyWith(profileImage: imageUrl);
            notifyListeners();
            print('✅ Profile image updated: $imageUrl');
          }

          return true;
        } else {
          _error = data['message'] ?? 'Upload failed';
          return false;
        }
      } else {
        _error = response.errorMessage ?? 'Upload failed';
        return false;
      }
    } catch (e, stackTrace) {
      _error = 'Error: $e';
      print('❌ Exception: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Alternative method if first endpoint fails
  Future<bool> _tryAlternativeImageUpload(File imageFile) async {
    print('🔄 Trying alternative upload endpoint...');

    try {
      final response = await _httpService.uploadFile<Map<String, dynamic>>(
        'auth/profile/upload-image', // Alternative endpoint
            (json) => json as Map<String, dynamic>,
        file: imageFile,
        fieldName: 'image',
      );

      if (response.isSuccess) {
        print('✅ Image uploaded via alternative endpoint');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Alternative upload also failed: $e');
      return false;
    }
  }





  // Update profile using JWT
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    print('🔍 ProfileProvider.updateProfile() called');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use HttpService with JWT token automatically added
      final response = await _httpService.put<bool>(
        'auth/profile/update',
            (json) => json['success'] ?? false,
        body: updates,
      );

      if (response.isSuccess && response.data == true) {
        // Update local profile
        _profile = _profile.copyWith(
          firstName: updates['firstName'] ?? _profile.firstName,
          lastName: updates['lastName'] ?? _profile.lastName,
          phoneNumber: updates['phoneNumber'] ?? updates['phone'] ?? _profile.phoneNumber,
          address: updates['address'] ?? _profile.address,
          dateOfBirth: updates['dateOfBirth'] ?? _profile.dateOfBirth,
        );
        print('✅ Profile updated successfully');
        return true;
      } else {
        _error = response.errorMessage;
        print('❌ Failed to update profile: ${response.errorMessage}');
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      print('❌ Exception updating profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Legacy method for compatibility (if needed)
  Future<void> fetchProfileLegacy(String userEmail) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use HttpService but override with email query param
      final response = await _httpService.get<UserProfile>(
        'auth/getUserByEmail?email=$userEmail',
            (json) => UserProfile.fromJson(json),
      );

      if (response.isSuccess) {
        _profile = response.data!;
      } else {
        _error = response.errorMessage;
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Debug method
  void debugProfile() {
    print('📊 Profile Debug Info:');
    print('  - Name: ${_profile.name}');
    print('  - Email: ${_profile.email}');
    print('  - Phone: ${_profile.phoneNumber}');
    print('  - Subscribed: ${_profile.subscribed}');
    print('  - Enrolled Courses: ${_profile.enrolledCoursesCount}');
    print('  - Loading: $_isLoading');
    print('  - Error: $_error');
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}