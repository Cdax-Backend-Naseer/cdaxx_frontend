import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor network connectivity status
/// Used for offline-first architecture to detect when to use cache vs network
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _isConnected = true;
  bool _isInitialized = false;
  ConnectivityResult _lastResult = ConnectivityResult.none;

  // Getters
  bool get isConnected => _isConnected;
  bool get isDisconnected => !_isConnected;
  bool get isInitialized => _isInitialized;
  ConnectivityResult get lastResult => _lastResult;

  /// Initialize the connectivity service and start listening
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🌐 Initializing ConnectivityService...');

    // Check initial connectivity
    await _checkInitialConnectivity();

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);

    _isInitialized = true;
    debugPrint('✅ ConnectivityService initialized, isConnected: $_isConnected');
  }

  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _lastResult = result.isNotEmpty ? result.first : ConnectivityResult.none;
      _isConnected = _lastResult != ConnectivityResult.none;
      debugPrint('🌐 Initial connectivity: ${_isConnected ? 'ONLINE' : 'OFFLINE'} (${_lastResult.name})');
    } catch (e) {
      debugPrint('❌ Failed to check initial connectivity: $e');
      _isConnected = true; // Assume connected on error
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final newResult = results.isNotEmpty ? results.first : ConnectivityResult.none;
    final wasConnected = _isConnected;
    final isNowConnected = newResult != ConnectivityResult.none;

    _lastResult = newResult;
    _isConnected = isNowConnected;

    debugPrint('🌐 Connectivity changed: ${wasConnected ? 'ONLINE' : 'OFFLINE'} → ${isNowConnected ? 'ONLINE' : 'OFFLINE'} (${newResult.name})');

    if (wasConnected != isNowConnected) {
      notifyListeners();
    }
  }

  /// Manually refresh connectivity status
  Future<bool> refreshConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final newResult = result.isNotEmpty ? result.first : ConnectivityResult.none;
      _isConnected = newResult != ConnectivityResult.none;
      _lastResult = newResult;
      notifyListeners();
      debugPrint('🔄 Manual connectivity refresh: ${_isConnected ? 'ONLINE' : 'OFFLINE'}');
      return _isConnected;
    } catch (e) {
      debugPrint('❌ Failed to refresh connectivity: $e');
      return _isConnected;
    }
  }

  /// Check if connected to WiFi (for large downloads)
  bool get isWifiConnected => _lastResult == ConnectivityResult.wifi;

  /// Check if connected to mobile data
  bool get isMobileConnected => _lastResult == ConnectivityResult.mobile;

  /// Check if connection is metered (mobile data or limited)
  bool get isMeteredConnection => _lastResult == ConnectivityResult.mobile;

  /// Get connection type as string
  String get connectionType {
    switch (_lastResult) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }

  /// Dispose the service
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}