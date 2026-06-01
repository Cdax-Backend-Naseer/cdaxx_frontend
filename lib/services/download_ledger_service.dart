import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DownloadLedgerService {
  final _storage = const FlutterSecureStorage();
  static const String _ledgerKey = 'secure_download_ledger';
  FlutterSecureStorage get storage => _storage;
  // Singleton pattern
  static final DownloadLedgerService _instance = DownloadLedgerService._internal();
  factory DownloadLedgerService() => _instance;
  DownloadLedgerService._internal();

  /// Retrieves the complete dictionary of downloaded videos
  Future<Map<String, dynamic>> getLedger() async {
    final String? jsonString = await _storage.read(key: _ledgerKey);
    if (jsonString == null) return {};
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  /// Register download with basic info (existing method - kept for compatibility)
  Future<void> registerDownload({
    required String videoId,
    required String filePath,
    required DateTime expiryDate,
  }) async {
    final ledger = await getLedger();

    ledger[videoId] = {
      'filePath': filePath,
      'expiryDate': expiryDate.toIso8601String(),
      'title': 'Video $videoId',
      'courseName': 'Course',
      'thumbnailUrl': '',
      'downloadedAt': DateTime.now().toIso8601String(),
    };

    await _storage.write(key: _ledgerKey, value: json.encode(ledger));
    print('💾 Video $videoId successfully registered to secure ledger.');
  }

  /// Register download with full metadata
  Future<void> registerDownloadWithMetadata({
    required String videoId,
    required String filePath,
    required DateTime expiryDate,
    required String videoTitle,
    required String courseName,
    required String? moduleName,        // ADD THIS
    String? thumbnailUrl,
  }) async {
    final ledger = await getLedger();

    ledger[videoId] = {
      'filePath': filePath,
      'expiryDate': expiryDate.toIso8601String(),
      'title': videoTitle,
      'courseName': courseName,
      'moduleName': moduleName ?? 'General',  // ADD THIS
      'thumbnailUrl': thumbnailUrl ?? '',
      'downloadedAt': DateTime.now().toIso8601String(),
    };

    await _storage.write(key: _ledgerKey, value: json.encode(ledger));
    print('💾 Video $videoId registered with metadata.');
  }

  /// Checks if a video is present and if the subscription is still valid
  Future<bool> isVideoValid(String videoId) async {
    final ledger = await getLedger();
    if (!ledger.containsKey(videoId)) return false;

    final videoData = ledger[videoId];
    final DateTime expiryDate = DateTime.parse(videoData['expiryDate']);
    final String filePath = videoData['filePath'];

    // 1. Strict Expiry Verification
    if (DateTime.now().isAfter(expiryDate)) {
      print('⏰ Video access expired for ID: $videoId. Initiating auto-deletion.');
      await deleteVideo(videoId);
      return false;
    }

    // 2. Physical File Presence Check
    final file = File(filePath);
    return await file.exists();
  }

  /// Get video metadata (NEW METHOD)
  Future<Map<String, dynamic>?> getVideoMetadata(String videoId) async {
    final ledger = await getLedger();
    if (!ledger.containsKey(videoId)) return null;
    return ledger[videoId];
  }

  /// Get all valid (non-expired) downloaded videos (NEW METHOD)
  /// Get all valid (non-expired) downloaded videos
  Future<List<Map<String, dynamic>>> getAllValidVideos() async {
    final ledger = await getLedger();
    final List<Map<String, dynamic>> validVideos = [];

    for (var entry in ledger.entries) {
      final videoId = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final expiryDate = DateTime.parse(data['expiryDate']);

      print('🔍 getAllValidVideos - Checking video: $videoId');
      print('   ├─ title in data: ${data['title']}');
      print('   ├─ courseName in data: ${data['courseName']}');
      print('   └─ expiryDate: $expiryDate');

      if (DateTime.now().isBefore(expiryDate)) {
        // Check if file still exists
        final file = File(data['filePath']);
        if (await file.exists()) {
          validVideos.add({
            'videoId': videoId,
            ...data,  // This includes title, courseName, etc.
          });
          print('   ✅ Added to valid videos');
        } else {
          print('   ❌ File does not exist, skipping');
        }
      } else {
        print('   ⏰ Video expired, cleaning up');
        await deleteVideo(videoId);
      }
    }

    print('📊 getAllValidVideos returning ${validVideos.length} videos');
    return validVideos;
  }

  /// Update file path for an existing download (used when download completes)
  Future<void> updateFilePath(String videoId, String newFilePath) async {
    final ledger = await getLedger();

    if (ledger.containsKey(videoId)) {
      ledger[videoId]['filePath'] = newFilePath;
      await _storage.write(key: _ledgerKey, value: json.encode(ledger));
      print('✅ Updated file path for video $videoId to: $newFilePath');
    } else {
      print('⚠️ Video $videoId not found in ledger, cannot update path');
    }
  }

  /// Deletes a specific video file from the sandbox and removes its database entry
  Future<void> deleteVideo(String videoId) async {
    final ledger = await getLedger();
    if (!ledger.containsKey(videoId)) return;

    try {
      final String filePath = ledger[videoId]['filePath'];
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        print('🗑️ Securely wiped video binary: $filePath');
      }
    } catch (e) {
      print('⚠️ Error deleting video file: $e');
    } finally {
      ledger.remove(videoId);
      await _storage.write(key: _ledgerKey, value: json.encode(ledger));
      print('🗑️ Removed video $videoId from ledger');
    }
  }

  /// Delete multiple videos (NEW METHOD)
  Future<void> deleteMultipleVideos(List<String> videoIds) async {
    for (final videoId in videoIds) {
      await deleteVideo(videoId);
    }
    print('🗑️ Deleted ${videoIds.length} videos');
  }

  /// Global Purge: Deletes ALL downloaded files immediately (e.g., when a user logs out)
  Future<void> wipeAllDownloads() async {
    final ledger = await getLedger();
    final keys = ledger.keys.toList();

    for (String videoId in keys) {
      await deleteVideo(videoId);
    }
    print('🚨 All downloaded offline assets cleared from device storage.');
  }

  /// Get total downloaded videos count (NEW METHOD)
  Future<int> getDownloadedCount() async {
    final validVideos = await getAllValidVideos();
    return validVideos.length;
  }

  /// Get total storage used by downloaded videos in bytes (NEW METHOD)
  Future<int> getTotalStorageUsed() async {
    final ledger = await getLedger();
    int totalBytes = 0;

    for (var entry in ledger.entries) {
      final filePath = entry.value['filePath'];
      final file = File(filePath);
      if (await file.exists()) {
        totalBytes += await file.length();
      }
    }

    return totalBytes;
  }

  /// Format storage size for display (NEW METHOD)
  String formatStorageSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}