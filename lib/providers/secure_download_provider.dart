import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import '../services/download_service.dart';
import '../services/download_ledger_service.dart';
import '../services/download_listener.dart';
import '../services/api_service.dart';

class SecureDownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService = DownloadService();
  final DownloadLedgerService _ledgerService = DownloadLedgerService();
  late DownloadListener _downloadListener;
  final ApiService _apiService = ApiService();

  // Key-value maps tracking state vectors across views
  final Map<String, int> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};

  // Track subscription status per video/course
  final Map<String, bool> _subscriptionStatus = {};
  final Map<String, DateTime?> _subscriptionEndDates = {};
  final Map<String, bool> _subscriptionCheckInProgress = {};

  // Track video metadata for storage
  final Map<String, Map<String, String>> _videoMetadata = {};

  Map<String, int> get downloadProgress => _downloadProgress;
  Map<String, bool> get isDownloading => _isDownloading;
  Map<String, bool> get subscriptionStatus => _subscriptionStatus;
  Map<String, DateTime?> get subscriptionEndDates => _subscriptionEndDates;

  SecureDownloadProvider() {
    _downloadListener = DownloadListener();
    _downloadListener.initializeListener((id, statusValue, progress) async {
      final status = DownloadTaskStatus.fromInt(statusValue);
      await _syncTaskWithVideoId(id, status, progress);
    });
  }

  Future<void> _syncTaskWithVideoId(String taskId, DownloadTaskStatus status, int progress) async {
    final tasks = await FlutterDownloader.loadTasks();
    if (tasks == null) return;

    final currentTask = tasks.cast<DownloadTask?>().firstWhere(
          (task) => task?.taskId == taskId,
      orElse: () => null,
    );

    if (currentTask != null && currentTask.filename != null) {
      final String videoId = currentTask.filename!.replaceAll('.mp4', '');

      if (status == DownloadTaskStatus.running) {
        _isDownloading[videoId] = true;
        _downloadProgress[videoId] = progress;
      } else if (status == DownloadTaskStatus.complete) {
        _isDownloading[videoId] = false;
        // Update the file path in the ledger now that download is complete
        final fullPath = '${currentTask.savedDir}/${currentTask.filename}';
        await _ledgerService.updateFilePath(videoId, fullPath);
        debugPrint('✅ Download complete, file path updated for video $videoId');
      } else if (status == DownloadTaskStatus.failed ||
          status == DownloadTaskStatus.canceled) {
        _isDownloading[videoId] = false;
        _downloadProgress.remove(videoId);
      }

      notifyListeners();
    }
  }


  Future<bool> canDownloadVideo(String videoId, String courseId, String userId) async {
    // Return cached status if available and not expired
    if (_subscriptionStatus.containsKey(videoId) &&
        _subscriptionEndDates.containsKey(videoId)) {
      final endDate = _subscriptionEndDates[videoId];
      if (endDate != null && DateTime.now().isBefore(endDate)) {
        return _subscriptionStatus[videoId] ?? false;
      }
    }

    if (_subscriptionCheckInProgress[videoId] == true) {
      return false;
    }

    _subscriptionCheckInProgress[videoId] = true;

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/subscription/check/$courseId?userId=$userId',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final hasSubscription = data['hasSubscription'] ?? false;
        final endDateStr = data['subscriptionEndDate'];

        _subscriptionStatus[videoId] = hasSubscription;
        if (endDateStr != null) {
          _subscriptionEndDates[videoId] = DateTime.parse(endDateStr);
        }

        notifyListeners();
        return hasSubscription;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      return false;
    } finally {
      _subscriptionCheckInProgress[videoId] = false;
    }
  }

  Future<DateTime?> getSubscriptionEndDate(String videoId, String courseId, String userId) async {
    if (_subscriptionEndDates.containsKey(videoId)) {
      return _subscriptionEndDates[videoId];
    }

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/subscription/check/$courseId?userId=$userId',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final endDateStr = response.data!['subscriptionEndDate'];
        if (endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          _subscriptionEndDates[videoId] = endDate;
          notifyListeners();
          return endDate;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting subscription end date: $e');
      return null;
    }
  }

  Future<bool> startSecureDownload({
    required String videoUrl,
    required String videoId,
    required String courseId,
    required String userId,
    String? videoTitle,
    String? courseName,
    String? moduleName,
  }) async {
    final canDownload = await canDownloadVideo(videoId, courseId, userId);

    if (!canDownload) {
      debugPrint('❌ Cannot download $videoId: No active subscription');
      return false;
    }

    if (_isDownloading[videoId] == true) {
      debugPrint('⚠️ Download already in progress for $videoId');
      return false;
    }

    final endDate = await getSubscriptionEndDate(videoId, courseId, userId);

    // STORE METADATA IMMEDIATELY (before download starts)
    // Use a placeholder file path that will be updated later
    final placeholderPath = 'downloading_$videoId';

    await _ledgerService.registerDownloadWithMetadata(
      videoId: videoId,
      filePath: placeholderPath,
      expiryDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
      videoTitle: videoTitle ?? 'Video $videoId',
      courseName: courseName ?? 'Course',
      moduleName: moduleName ?? 'Module',
    );

    debugPrint('✅ Metadata saved for video $videoId:');
    debugPrint('   ├─ Title: ${videoTitle ?? 'Video $videoId'}');
    debugPrint('   ├─ Course: ${courseName ?? 'Course'}');
    debugPrint('   └─ Module: ${moduleName ?? 'Module'}');

    _isDownloading[videoId] = true;
    _downloadProgress[videoId] = 0;
    notifyListeners();

    try {
      await _downloadService.downloadCourseVideo(
        videoUrl: videoUrl,
        videoId: videoId,
      );
      return true;
    } catch (e) {
      _isDownloading[videoId] = false;
      _downloadProgress.remove(videoId);
      debugPrint("Error dispatching background download task sequence: $e");
      notifyListeners();
      return false;
    }
  }
  Future<bool> isVideoDownloaded(String videoId) async {
    return await _ledgerService.isVideoValid(videoId);
  }

  Future<DateTime?> getVideoExpiryDate(String videoId) async {
    final ledger = await _ledgerService.getLedger();
    if (ledger.containsKey(videoId)) {
      final expiryDateStr = ledger[videoId]['expiryDate'];
      if (expiryDateStr != null) {
        return DateTime.parse(expiryDateStr);
      }
    }
    return null;
  }

  Future<bool> isDownloadedVideoValid(String videoId) async {
    return await _ledgerService.isVideoValid(videoId);
  }

  Future<void> removeDownloadedVideo(String videoId) async {
    await _ledgerService.deleteVideo(videoId);
    _downloadProgress.remove(videoId);
    _isDownloading.remove(videoId);
    _subscriptionStatus.remove(videoId);
    _subscriptionEndDates.remove(videoId);
    _videoMetadata.remove(videoId);
    notifyListeners();
  }

  Future<void> clearAllDownloads() async {
    await _ledgerService.wipeAllDownloads();
    _downloadProgress.clear();
    _isDownloading.clear();
    _subscriptionStatus.clear();
    _subscriptionEndDates.clear();
    _videoMetadata.clear();
    notifyListeners();
  }

  Future<void> refreshSubscriptionStatus(String videoId, String courseId, String userId) async {
    _subscriptionStatus.remove(videoId);
    _subscriptionEndDates.remove(videoId);
    await canDownloadVideo(videoId, courseId, userId);
  }

  @override
  void dispose() {
    _downloadListener.disposeListener();
    super.dispose();
  }
}