/// User Provider - Enhanced Version with Robust Auth Handling
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../models/auth/auth_response_model.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SecureStorageService _secureStorage = SecureStorageService.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  String? _storedEmail;

  // For auth state streaming (optional)
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  Stream<bool> get authStateChanges => _authStateController.stream;

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
    if (user?.email != null) {
      _storedEmail = user!.email;
    }
    _error = null;
    notifyListeners();
  }

// In UserProvider.initialize() method, add this check:

  Future<void> initialize() async {
    print('\n🔄 UserProvider: Initializing authentication state...');
    _setLoading(true);

    try {
      // First check if we have any stored user data
      final storedUser = await _authService.getCurrentUser();
      print('🔍 UserProvider: Stored user check - ${storedUser != null ? "EXISTS" : "NULL"}');

      // Check JWT token
      final hasJWT = await _authService.hasValidJWTToken();
      print('🔍 UserProvider: JWT token exists: $hasJWT');

      // 🔴 CRITICAL: If we have stored user but NO JWT token, we need to logout
      if (storedUser != null && !hasJWT) {
        print('⚠️ UserProvider: Stored user exists but NO JWT token!');
        print('⚠️ This means the user needs to login again.');

        // Clear stored user data since we can't make API calls without JWT
        await _authService.clearAllAuthData();
        print('✅ Cleared all auth data - user needs to login again');

        _isAuthenticated = false;
        _currentUser = null;
        _storedEmail = null;
        _authStateController.add(false);

        print('📊 UserProvider: User logged out (no JWT token)');
        return;
      }

      if (hasJWT) {
        print('🔄 UserProvider: Attempting JWT initialization...');
        await _initializeWithJWT(storedUser);
      } else {
        print('🔄 UserProvider: No JWT token, trying legacy initialization...');
        await _initializeLegacy(storedUser);
      }

      // Final check and logging
      await _finalizeInitialization();

    } catch (e) {
      print('❌ UserProvider: Error during initialization: $e');
      await _handleInitializationError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _initializeWithJWT(UserModel? storedUser) async {
    try {
      final userResponse = await _authService.getCurrentUserWithJWT();

      print('📡 UserProvider: JWT response status: ${userResponse.statusCode}');

      if (userResponse.isSuccess &&
          userResponse.data != null &&
          userResponse.data!['success'] == true) {

        final userData = userResponse.data!['user'];
        if (userData != null) {
          _currentUser = UserModel.fromJson(userData);
          _storedEmail = _currentUser!.email;
          _isAuthenticated = true;

          print('✅ UserProvider: JWT initialization successful');
          print('   ├─ User: ${_currentUser!.email}');
          print('   ├─ ID: ${_currentUser!.id}');

          // Save to storage for consistency
          await _authService.saveUserData(userData);
          _authStateController.add(true);
          return;
        }
      } else if (userResponse.statusCode == 401) {
        // Token is invalid or user not found
        print('⚠️ UserProvider: JWT token invalid (401)');
        print('   ├─ Response message: ${userResponse.data?['message']}');

        // Clear the invalid token
        await _authService.clearJWTToken();
        print('✅ JWT token cleared');

        // Check if we have stored user data that might be different
        if (storedUser != null) {
          print('⚠️ Found stored user data that doesn\'t match JWT token');
          print('   ├─ Stored user ID: ${storedUser.id}');
          print('   ├─ Stored email: ${storedUser.email}');

          // Try to decode JWT to see what user it's for
          try {
            final token = await _authService.getJWTToken();
            if (token != null) {
              final parts = token.split('.');
              if (parts.length == 3) {
                final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
                final tokenUserId = payload['userId']?.toString();
                final tokenEmail = payload['sub'];
                print('🔍 JWT Token Analysis:');
                print('   ├─ Token User ID: $tokenUserId');
                print('   ├─ Token Email: $tokenEmail');
                print('   ├─ Stored User ID: ${storedUser.id}');
                print('   ├─ Stored Email: ${storedUser.email}');

                if (tokenUserId != storedUser.id?.toString()) {
                  print('❌ JWT token is for different user!');
                  print('   ├─ Clearing all auth data...');
                  await _authService.clearAllAuthData();
                }
              }
            }
          } catch (e) {
            print('❌ Error analyzing JWT token: $e');
          }
        }
      }

      // If JWT failed, fall back to legacy or stored user
      print('🔄 UserProvider: Falling back to stored user data...');
      await _initializeLegacy(storedUser);

    } catch (e) {
      print('❌ UserProvider: JWT initialization error: $e');
      await _authService.clearJWTToken();
      await _initializeLegacy(storedUser);
    }
  }

  Future<void> _initializeLegacy(UserModel? storedUser) async {
    print('🔄 UserProvider: Attempting legacy initialization...');

    // First try using stored user if available
    if (storedUser != null) {
      print('✅ UserProvider: Using stored user data');
      _currentUser = storedUser;
      _storedEmail = storedUser.email;
      _isAuthenticated = true;
      _authStateController.add(true);
      print('   ├─ User: ${storedUser.email}');
      print('   ├─ ID: ${storedUser.id}');
      return;
    }

    // Fallback to legacy auth check
    _isAuthenticated = await _authService.isAuthenticated();
    print('🔍 UserProvider: Legacy auth check: $_isAuthenticated');

    if (_isAuthenticated) {
      _currentUser = await _authService.getCurrentUser();

      if (_currentUser != null) {
        _storedEmail = _currentUser!.email;
        print('✅ UserProvider: Legacy initialization successful');
        print('   ├─ User: ${_currentUser!.email}');
        _authStateController.add(true);
      } else {
        print('⚠️ UserProvider: Legacy auth says authenticated but no user data');
        _isAuthenticated = false;
        await _authService.clearAllAuthData();
        _authStateController.add(false);
      }
    } else {
      print('ℹ️ UserProvider: No legacy session found');
      _authStateController.add(false);
    }
  }

  Future<void> _finalizeInitialization() async {
    // Double-check email
    if (_storedEmail == null && _isAuthenticated) {
      print('🔍 UserProvider: Email missing, trying to recover...');

      // Try from SecureStorage directly
      final storedEmail = await _secureStorage.getUserEmail();
      if (storedEmail != null) {
        _storedEmail = storedEmail;
        print('✅ Retrieved email from SecureStorage: $_storedEmail');
      }
    }

    // Final state logging
    print('📊 UserProvider initialization complete:');
    print('   ├─ Authenticated: $_isAuthenticated');
    print('   ├─ User exists: ${_currentUser != null}');
    print('   ├─ User email: ${_currentUser?.email}');
    print('   ├─ Stored email: $_storedEmail');
    print('   ├─ userEmail getter: ${userEmail}');
  }

  Future<void> _handleInitializationError(dynamic error) async {
    _setError('Failed to initialize user session: ${error.toString()}');
    _isAuthenticated = false;
    _authStateController.add(false);

    // Clear potentially corrupted auth data
    await _authService.clearAllAuthData();
  }

  // Load current user
  Future<void> loadCurrentUser() async {
    _setLoading(true);
    _setError(null);

    try {
      _currentUser = await _authService.getCurrentUser();
      if (_currentUser != null && _currentUser!.email != null) {
        _storedEmail = _currentUser!.email;
      }
      _isAuthenticated = _currentUser != null;
      if (_isAuthenticated) {
        _authStateController.add(true);
      }
      print('🔍 UserProvider: loadCurrentUser - isAuthenticated = $_isAuthenticated');
      print('   ├─ Email loaded: $_storedEmail');
    } catch (e) {
      _setError('Failed to load user: ${e.toString()}');
      _isAuthenticated = false;
      _authStateController.add(false);
    }

    _setLoading(false);
  }

  // Login user with retry logic
  Future<bool> login(String email, String password, {int maxRetries = 2}) async {
    // Basic input validation
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _setError('Email and password are required');
      return false;
    }

    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        _setLoading(true);
        _setError(null);

        print('\n🔐 UserProvider: Attempting login for $email (attempt ${attempts + 1})');

        // Try JWT login directly first
        print('   ├─ Attempting direct JWT login...');
        final jwtResponse = await _authService.loginWithJWT(
          email: email,
          password: password,
        );

        print('   ├─ JWT Login response:');
        print('   ├─ Success: ${jwtResponse.isSuccess}');

        if (jwtResponse.isSuccess && jwtResponse.data != null && jwtResponse.data!['success'] == true) {
          final data = jwtResponse.data!;

          // Extract user from JWT response
          UserModel? user;
          if (data['user'] != null) {
            user = UserModel.fromJson(data['user']);
            print('   ├─ User extracted: ${user.email}');
          }

          _currentUser = user;
          _storedEmail = email; // Store the login email
          _isAuthenticated = true;
          _authStateController.add(true);

          print('✅ UserProvider: JWT Login successful');
          print('   ├─ User ID: ${_currentUser!.id}');
          print('   ├─ Email from user object: ${_currentUser!.email}');
          print('   ├─ Stored email (login email): $_storedEmail');

          // ✅ CRITICAL: Save user data to secure storage
          if (data['user'] != null) {
            await _authService.saveUserData(data['user']);
            print('💾 User data saved to secure storage');
          }

          _setLoading(false);
          return true;
        }

        // If JWT failed, try the standard login
        print('   ⚠️ Direct JWT login failed, trying standard login...');
        final response = await _authService.login(
          email: email,
          password: password,
          useJWT: true, // Explicitly use JWT
        );

        print('   ├─ Standard Login response:');
        print('   ├─ Success: ${response.isSuccess}');

        if (response.isSuccess && response.data != null && response.data!.success) {
          _currentUser = response.data!.user;
          _storedEmail = email;
          _isAuthenticated = true;
          _authStateController.add(true);

          print('✅ UserProvider: Standard Login successful');
          print('   ├─ User ID: ${_currentUser!.id}');
          print('   ├─ Email from user object: ${_currentUser!.email}');

          // ✅ CRITICAL: Save user data to secure storage
          await _authService.saveUserData(_currentUser!.toJson());
          print('💾 User data saved to secure storage');

          _setLoading(false);
          return true;
        } else {
          final errorMsg = response.data?.message ?? response.error ?? 'Login failed';

          // If this was the last attempt, show error
          if (attempts == maxRetries) {
            _setError(errorMsg);
            _isAuthenticated = false;
            _authStateController.add(false);
            print('❌ UserProvider: All login attempts failed');
            print('❌ Error: $errorMsg');
            _setLoading(false);
            return false;
          }

          print('⚠️ Login attempt ${attempts + 1} failed, retrying...');
          attempts++;

          // Wait before retry (exponential backoff)
          await Future.delayed(Duration(seconds: attempts));
        }
      } catch (e) {
        // If this was the last attempt, show error
        if (attempts == maxRetries) {
          final errorMsg = 'Unexpected error: ${e.toString()}';
          _setError(errorMsg);
          _isAuthenticated = false;
          _authStateController.add(false);
          print('❌ UserProvider: Login exception - $errorMsg');
          _setLoading(false);
          return false;
        }

        print('⚠️ Login attempt ${attempts + 1} threw exception, retrying...');
        attempts++;
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    return false;
  }

  // Register user - WITH AUTO-LOGIN (Updated for JWT)
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

      print('\n📝 UserProvider: Attempting registration for $email');

      // Try JWT registration first
      print('   ├─ Attempting JWT registration...');
      final jwtResponse = await _authService.registerWithJWT(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: mobile,
        password: password,
      );

      print('   ├─ JWT Registration response:');
      print('   ├─ Success: ${jwtResponse.isSuccess}');

      if (jwtResponse.isSuccess && jwtResponse.data != null && jwtResponse.data!['success'] == true) {
        print('✅ UserProvider: JWT Registration successful, attempting auto-login');

        // Auto-login after successful JWT registration
        final loginResult = await login(email, password, maxRetries: 1);

        if (loginResult) {
          print('✅ UserProvider: Auto-login successful');
          return true;
        } else {
          _setError('Registration successful but login failed');
          print('⚠️ UserProvider: Registration succeeded but auto-login failed');
          return false;
        }
      }

      // Fallback to legacy registration if JWT fails
      print('   ⚠️ JWT registration failed, trying legacy registration...');
      final response = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        mobile: mobile,
        password: password,
        confirmPassword: confirmPassword,
        useJWT: false, // Use legacy registration
      );

      if (response.isSuccess && response.data != null && response.data!.success) {
        print('✅ UserProvider: Legacy Registration successful, attempting auto-login');

        // ✅ AUTO-LOGIN AFTER SUCCESSFUL REGISTRATION
        final loginResult = await login(email, password, maxRetries: 1);

        if (loginResult) {
          return true;
        } else {
          _setError('Registration successful but login failed');
          print('⚠️ UserProvider: Registration succeeded but auto-login failed');
          return false;
        }
      } else {
        final errorMsg = response.data?.message ?? response.error ?? 'Registration failed';
        _setError(errorMsg);
        print('❌ UserProvider: Registration failed - $errorMsg');
        return false;
      }
    } catch (e) {
      final errorMsg = 'Unexpected error: ${e.toString()}';
      _setError(errorMsg);
      print('❌ UserProvider: Registration exception - $errorMsg');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check JWT token status
  Future<bool> checkJWTToken() async {
    try {
      final hasToken = await _authService.hasValidJWTToken();
      print('🔍 UserProvider: JWT Token status - $hasToken');
      return hasToken;
    } catch (e) {
      print('❌ UserProvider: Error checking JWT token: $e');
      return false;
    }
  }

  // Get current JWT token (for debugging)
  Future<String?> getJWTToken() async {
    return await _authService.getJWTToken();
  }

  // Token Refresh Method
  Future<bool> refreshToken() async {
    try {
      print('🔄 UserProvider: Refreshing token...');
      final refreshed = await _authService.refreshJWTToken();

      if (refreshed) {
        // Re-fetch user data with new token
        final userResponse = await _authService.getCurrentUserWithJWT();
        if (userResponse.isSuccess && userResponse.data != null) {
          final userData = userResponse.data!['user'];
          if (userData != null) {
            _currentUser = UserModel.fromJson(userData);
            notifyListeners();
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('❌ Token refresh failed: $e');
      return false;
    }
  }

  // Validate Session
  Future<bool> validateSession() async {
    if (!_isAuthenticated) return false;

    try {
      // Check if JWT is still valid
      final hasValidJWT = await _authService.hasValidJWTToken();

      if (hasValidJWT) {
        // Try to fetch fresh user data
        final userResponse = await _authService.getCurrentUserWithJWT();
        if (userResponse.isSuccess) {
          return true;
        }
      }

      // Session is invalid, logout
      print('⚠️ Session validation failed, logging out...');
      await logout();
      return false;

    } catch (e) {
      print('❌ Session validation error: $e');
      return false;
    }
  }

  // Update User Profile
  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.updateProfile(updates);

      if (response.isSuccess && response.data != null) {
        // Update local user model
        if (_currentUser != null) {
          _currentUser = UserModel.fromJson({
            ..._currentUser!.toJson(),
            ...updates,
          });
          notifyListeners();
        }
        return true;
      } else {
        _setError(response.errorMessage);
        return false;
      }
    } catch (e) {
      _setError('Update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    print('🚪 UserProvider: Logging out...');
    _setLoading(true);

    try {
      await _authService.logout();
      _currentUser = null;
      _storedEmail = null;
      _isAuthenticated = false;
      _error = null;
      _authStateController.add(false);
      print('✅ UserProvider: Logout successful - cleared stored email');
    } catch (e) {
      print('❌ UserProvider: Logout error - $e');
      // Still clear local state even if API call fails
      _currentUser = null;
      _storedEmail = null;
      _isAuthenticated = false;
      _error = null;
      _authStateController.add(false);
    } finally {
      _setLoading(false);
    }
  }

  // Error Recovery Method
  Future<bool> recoverFromError() async {
    print('🔄 UserProvider: Attempting error recovery...');

    try {
      // Clear all local state
      _currentUser = null;
      _storedEmail = null;
      _isAuthenticated = false;
      _error = null;
      _authStateController.add(false);

      // Re-initialize from scratch
      await initialize();

      return _isAuthenticated;
    } catch (e) {
      print('❌ Error recovery failed: $e');
      return false;
    }
  }

  // Check if user is logged in (without loading)
  bool get isLoggedIn => _isAuthenticated;

  // Get user ID (convenience method)
  String? get userId => _currentUser?.id?.toString();

  // Get user email (convenience method) - UPDATED
  String? get userEmail {
    // First try the stored email
    if (_storedEmail != null && _storedEmail!.isNotEmpty) {
      return _storedEmail;
    }
    // Fallback to currentUser email
    if (_currentUser?.email != null && _currentUser!.email.isNotEmpty) {
      return _currentUser!.email;
    }
    return null;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Manually set authenticated state (for debugging)
  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    if (!authenticated) {
      _currentUser = null;
      _storedEmail = null;
      _authStateController.add(false);
    } else {
      _authStateController.add(true);
    }
    notifyListeners();
  }

  // Debug method to see current state
  void debugState() {
    print('\n🔍 UserProvider Debug State:');
    print('   ├─ isAuthenticated: $_isAuthenticated');
    print('   ├─ currentUser exists: ${_currentUser != null}');
    print('   ├─ currentUser.email: ${_currentUser?.email}');
    print('   ├─ storedEmail: $_storedEmail');
    print('   ├─ userEmail getter returns: ${userEmail}');
    print('   ├─ userId: $userId');
    print('   ├─ has auth listeners: ${_authStateController.hasListener}');
  }

  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}