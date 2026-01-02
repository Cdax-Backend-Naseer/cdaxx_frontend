// In profile_provider.dart - REPLACE the entire file

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../providers/user_provider.dart';
import '/config/environment_config.dart';

final String baseUrl = EnvironmentConfig.baseUrl;

@immutable
class UserProfile {
  final String name;
  final String email;
  final String phone;
  final int enrolledCoursesCount;
  final bool subscribed;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.enrolledCoursesCount,
    required this.subscribed,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
      enrolledCoursesCount: json['enrolledCoursesCount'] ?? 0,
      subscribed: json['subscribed'] ?? false,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    int? enrolledCoursesCount,
    bool? subscribed,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      enrolledCoursesCount: enrolledCoursesCount ?? this.enrolledCoursesCount,
      subscribed: subscribed ?? this.subscribed,
    );
  }
}

// NEW: Streak model for OLD API (keep for compatibility)
@immutable
class UserStreak {
  final DateTime date;
  final int videosWatched;
  final bool active;

  const UserStreak({
    required this.date,
    required this.videosWatched,
    required this.active,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      date: DateTime.parse(json['date']),
      videosWatched: json['videosWatched'] ?? 0,
      active: json['active'] ?? false,
    );
  }
}

// Provider
class ProfileProvider extends ChangeNotifier {
  UserProfile _profile = const UserProfile(
    name: 'Jane Doe',
    email: 'jane@example.com',
    phone: '+1 555 0100',
    enrolledCoursesCount: 2,
    subscribed: true,
  );

  bool _isLoading = false;
  List<UserStreak> _streaks = [];

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  List<UserStreak> get streaks => _streaks;

  Future<void> updateProfile(UserProfile updated) async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    _profile = updated;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProfile(String userEmail) async {
    _isLoading = true;

    final url = Uri.parse("$baseUrl/api/auth/getUserByEmail?email=$userEmail");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      _profile = UserProfile(
        name: "${data['firstName']} ${data['lastName']}",
        email: data['email'],
        phone: data['mobile'] ?? "",
        enrolledCoursesCount: 0,
        subscribed: true,
      );
    }

    // Fetch OLD streak data (for compatibility)
    try {
      final streakUrl = Uri.parse("$baseUrl/api/profile/streak?email=$userEmail");
      final streakResp = await http.get(streakUrl);

      if (streakResp.statusCode == 200) {
        final streakData = jsonDecode(streakResp.body) as List<dynamic>;
        _streaks = streakData.map((e) => UserStreak.fromJson(e)).toList();
      }
    } catch (e) {
      _streaks = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}