import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'download_ledger_service.dart';

class DownloadListener {
  final ReceivePort _port = ReceivePort();
  final DownloadLedgerService _ledgerService = DownloadLedgerService();

  /// Call this inside your Screen/Widget's initState() or Provider to start tracking progress
  void initializeListener(Function(String id, int status, int progress) onUpdate) {
    // Register communication channel with the background download isolate
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');

    _port.listen((dynamic data) async {
      String id = data[0];
      int statusValue = data[1];
      int progress = data[2];

      DownloadTaskStatus status = DownloadTaskStatus.fromInt(statusValue);

      // Trigger UI updates via custom callback
      onUpdate(id, statusValue, progress);

      // CRITICAL: When the download successfully finishes, register it in our ledger
      if (status == DownloadTaskStatus.complete) {
        await _handleDownloadCompletion(id);
      }
    });
  }

  /// Call this inside your dispose() methods to prevent memory leaks
  void disposeListener() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  Future<void> _handleDownloadCompletion(String taskId) async {
    // Fetch task logs from the background downloader engine
    final tasks = await FlutterDownloader.loadTasks();
    if (tasks == null) return;

    final currentTask = tasks.firstWhere((task) => task.taskId == taskId);

    // Extract the information we assigned during generation
    final String videoId = currentTask.filename!.replaceAll('.mp4', '');
    final String fullPath = '${currentTask.savedDir}/${currentTask.filename}';

    print('📥 Download completed for video: $videoId');
    print('   ├─ File path: $fullPath');

    // Update the file path in the ledger
    final ledgerService = DownloadLedgerService();
    await ledgerService.updateFilePath(videoId, fullPath);

    print('🎯 Download completion flow finished. File path updated in ledger.');
  }
}