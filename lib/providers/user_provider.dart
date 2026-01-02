/// User Provider - Fixed Version
import 'package:flutter/foundation.dart';
import '../models/auth/auth_response_model.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    _error = null;
    notifyListeners();
  }

  // Initialize authentication state
  Future<void> initialize() async {
    _setLoading(true);
    _isAuthenticated = await _authService.isAuthenticated();

    if (_isAuthenticated) {
      _currentUser = await _authService.getCurrentUser();
      // If user data failed to load, user is not really authenticated
      if (_currentUser == null) {
        _isAuthenticated = false;
      }
    }

    _setLoading(false);
  }

  // Load current user
  Future<void> loadCurrentUser() async {
    _setLoading(true);
    _setError(null);

    try {
      _currentUser = await _authService.getCurrentUser();
      _isAuthenticated = _currentUser != null;
    } catch (e) {
      _setError('Failed to load user: ${e.toString()}');
      _isAuthenticated = false;
    }

    _setLoading(false);
  }

  // Login user
  Future<bool> login(String email, String password) async {
    // Basic input validation
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _setError('Email and password are required');
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.isSuccess && response.data != null && response.data!.success) {
        _currentUser = response.data!.user;
        _isAuthenticated = true;
        return true;
      } else {
        // FIX: Use response.error instead of response.errorMessage
        _setError(response.data?.message ?? response.error ?? 'Login failed');
        _isAuthenticated = false;
        return false;
      }
    } catch (e) {
      _setError('Unexpected error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register user
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        mobile: mobile,
        password: password,
        confirmPassword: confirmPassword,
      );

      if (response.isSuccess && response.data != null && response.data!.success) {
        return true;
      } else {
        // FIX: Use response.error instead of response.errorMessage
        _setError(response.data?.message ?? response.error ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Unexpected error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentUser = null;
    _isAuthenticated = false;
    _error = null;
    _setLoading(false);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}