import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'app.dart';
import 'services/http_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services (Storage, HTTP, Auth, and now Downloader)
  await _initializeServices();

  runApp(const CdaxApp());
}

Future<void> _initializeServices() async {
  print('🚀 Initializing app services...');

  // Initialize storage service FIRST
  await StorageService().initialize();
  print('✅ Storage service initialized');

  // Initialize HTTP service
  HttpService().initialize();
  print('✅ HTTP service initialized');

  // Initialize Auth service (loads persisted session)
  await AuthService().initialize();
  print('✅ Auth service initialized');

  // 1. Initialize the Secure Background Downloader
  await FlutterDownloader.initialize(
      debug: true,   // Switch to false in production deployment
      ignoreSsl: true // Keeps downloads reliable even with strict SSL/CDN paths
  );

  // 2. Register the communication port for the downloader background isolate
  FlutterDownloader.registerCallback(downloadCallback);
  print('✅ Secure Background Downloader initialized');

  // Note: UserProvider will be initialized in CdaxApp widget
  print('🎉 All services initialized successfully');
}

/// 3. Global background download callback.
/// This must be a top-level or static function with this exact signature.
/// It catches download progress updates from the native OS service.
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}