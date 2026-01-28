import 'package:flutter/material.dart';
import 'app.dart';
import 'services/http_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
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

  // Note: UserProvider will be initialized in CdaxApp widget
  print('🎉 All services initialized successfully');
}