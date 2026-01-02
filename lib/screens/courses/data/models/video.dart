// video.dart - UPDATED to match your database
import 'package:flutter/foundation.dart';

@immutable
class Video {
  final String id;
  final String title;
  final String description;
  final String videoUrl;     // Full URL from DB: https://www.youtube.com/watch?v=1xipg02Wu8s
  final String youtubeId;    // Just ID from DB: 1xipg02Wu8s
  final int durationSec;     // duration column in DB
  final int displayOrder;    // display_order column in DB
  final bool isPreview;      // is_preview column in DB (0x01 = true, 0x00 = false)
  final bool isLocked;       // Calculated at runtime
  final bool isCompleted;    // Calculated at runtime

  const Video({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.youtubeId,
    required this.durationSec,
    required this.displayOrder,
    required this.isPreview,
    required this.isLocked,
    required this.isCompleted,
  });

  // Getter for YouTube URL - just returns videoUrl since it's already a YouTube URL
  String get youtubeUrl => videoUrl;

  // Helper to extract YouTube ID if not provided (shouldn't be needed since DB has it)
  String get extractedYoutubeId {
    if (youtubeId.isNotEmpty) return youtubeId;
    // Extract from videoUrl if needed
    final uri = Uri.tryParse(videoUrl);
    if (uri != null) {
      final id = uri.queryParameters['v'];
      if (id != null && id.isNotEmpty) return id;
    }
    // Try to extract from youtu.be format
    if (videoUrl.contains('youtu.be/')) {
      final parts = videoUrl.split('youtu.be/');
      if (parts.length > 1) return parts[1].split('?')[0];
    }
    return '';
  }

  // JSON serialization matching your Spring Boot DTO
  factory Video.fromJson(Map<String, dynamic> json) {
    print('🎥 Parsing Video JSON:');
    print('   ├─ title: ${json['title']}');
    print('   ├─ videoUrl from API: ${json['videoUrl']}');
    print('   ├─ youtubeId from API: ${json['youtubeId']}');
    print('   ├─ isLocked from API: ${json['isLocked']}');
    print('   ├─ isCompleted from API: ${json['isCompleted']}');

    return Video(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Video',
      description: json['description']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',      // From DB column
      youtubeId: json['youtubeId']?.toString() ?? '',    // From DB column
      durationSec: _parseInt(json['duration'] ?? json['durationSec'], 0),
      displayOrder: _parseInt(json['displayOrder'] ?? json['orderIndex'], 0),
      isPreview: _parsePreviewFlag(json['isPreview'] ?? json['is_preview']),
      isLocked: _parseBool(json['isLocked'] ?? json['locked'], true),
      isCompleted: _parseBool(json['isCompleted'] ?? json['completed'], false),
    );
  }

  // Parse is_preview flag (0x01 = true, 0x00 = false in your DB)
  static bool _parsePreviewFlag(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      if (value == '0x01') return true;
      if (value == '0x00') return false;
      return value.toLowerCase() == 'true';
    }
    if (value is int) return value == 1;
    return false;
  }

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'youtubeId': youtubeId,
      'duration': durationSec,
      'displayOrder': displayOrder,
      'isPreview': isPreview,
      'isLocked': isLocked,
      'isCompleted': isCompleted,
    };
  }

  @override
  String toString() {
    return 'Video(id: $id, title: "$title", videoUrl: "$videoUrl", youtubeId: "$youtubeId", isLocked: $isLocked)';
  }
}