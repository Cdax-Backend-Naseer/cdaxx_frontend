import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  // Singleton instance configuration
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  /// Gets the secure, hidden app-specific folder
  Future<String> _getSecureFolderPath() async {
    final directory = await getApplicationDocumentsDirectory();

    // Creating a hidden sub-folder (prefixed with a dot) makes it extra secure
    final secureDir = Directory('${directory.path}/.hidden_lessons');
    if (!await secureDir.exists()) {
      await secureDir.create(recursive: true);
    }
    return secureDir.path;
  }

  /// Triggers a secure background download directly to the app sandbox
  Future<String?> downloadCourseVideo({
    required String videoUrl,
    required String videoId,
  }) async {
    final securePath = await _getSecureFolderPath();

    // Queue the native background download task
    final taskId = await FlutterDownloader.enqueue(
      url: videoUrl,
      savedDir: securePath,
      fileName: '$videoId.mp4',       // Saved inside the private sandbox
      showNotification: true,         // Shows download progress in notification bar
      openFileFromNotification: false,// Prevents user from opening it outside the app
      saveInPublicStorage: false,     // CRITICAL: Keeps it hidden from settings/gallery
    );

    print('📥 Secure download initialized. Task ID: $taskId');
    return taskId;
  }
}