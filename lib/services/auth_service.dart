// Authentication Service - Complete Fixed Version
import 'dart:convert';
import 'dart:math';
import '../constants/api_endpoints.dart';
import '../models/auth/auth_response_model.dart';
import '../core/user_manager.dart';
import 'http_service.dart';
import 'storage_service.dart';
import 'secure_storage_service.dart';

class AuthService {
  final HttpService _httpService = HttpService();
  final StorageService _storageService = StorageService();
  final SecureStorageService _secureStorage = SecureStorageService.instance;

  // ==================== JWT METHODS ====================

  // JWT Login - with more debugging
  Future<ApiResponse<Map<String, dynamic>>> loginWithJWT({
    required String email,
    required String password,
  }) async {
    print('🔐 loginWithJWT called');
    print('   ├─ Email: $email');
    print('   ├─ Password length: ${password.length}');

    if (email.trim().isEmpty || password.trim().isEmpty) {
      print('❌ Email or password empty');
      return ApiResponse.error('Email and password are required');
    }

    try {
      print('🌐 Making request to: ${ApiEndpoints.jwtLogin}');
      final response = await _httpService.post<Map<String, dynamic>>(
        ApiEndpoints.jwtLogin,
            (data) => data as Map<String, dynamic>,
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      print('📡 Response received:');
      print('   ├─ Success: ${response.isSuccess}');
      print('   ├─ Error: ${response.error}');
      print('   ├─ Data: ${response.data}');

      if (response.isSuccess && response.data != null && response.data!['success'] == true) {
        final data = response.data!;

        // Store JWT token
        final token = data['accessToken'] ?? data['token'];
        if (token != null) {
          await _secureStorage.saveToken(token);
          print('✅ JWT Token saved: ${token.substring(0, min(20, token.length))}...');
        } else {
          print('❌ No token in response!');
        }

        // Store user data
        if (data['user'] != null) {
          final user = UserModel.fromJson(data['user']);
          await _persistUserData(user);
          print('✅ User data stored: ${user.email}');
        }

        // Update UserManager
        await UserManager.setEmail(email);
        print('✅ UserManager updated');

        return response;
      } else {
        final errorMessage = response.data?['message'] ?? 'Login failed';
        print('❌ Login failed: $errorMessage');
        print('❌ Response data: ${response.data}');
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      print('❌ Exception in loginWithJWT: $e');
      return ApiResponse.error('JWT Login failed: ${e.toString()}');
    }
  }

  // JWT Register
  Future<ApiResponse<Map<String, dynamic>>> registerWithJWT({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    if (firstName.trim().isEmpty || lastName.trim().isEmpty ||
        email.trim().isEmpty || phoneNumber.trim().isEmpty ||
        password.trim().isEmpty) {
      return ApiResponse.error('All fields are required');
    }

    try {
      final response = await _httpService.post<Map<String, dynamic>>(
        ApiEndpoints.jwtRegister,
            (data) => data as Map<String, dynamic>,
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email.trim().toLowerCase(),
          'phoneNumber': phoneNumber,
          'password': password,
        },
      );

      if (response.isSuccess && response.data != null && response.data!['success'] == true) {
        final data = response.data!;

        // Store JWT token
        final token = data['accessToken'] ?? data['token'];
        if (token != null) {
          await _secureStorage.saveToken(token);
          print('✅ JWT Token saved after registration');
        }

        // Store user data
        if (data['user'] != null) {
          final user = UserModel.fromJson(data['user']);
          await _persistUserData(user);
        }

        return response;
      } else {
        final errorMessage = response.data?['message'] ?? 'Registration failed';
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      return ApiResponse.error('JWT Registration failed: ${e.toString()}');
    }
  }

  // Get current authenticated user via JWT
  Future<ApiResponse<Map<String, dynamic>>> getCurrentUserWithJWT() async {
    try {
      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error('No authentication token found');
      }

      final response = await _httpService.get<Map<String, dynamic>>(
        ApiEndpoints.jwtMe,
            (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get current user: ${e.toString()}');
    }
  }

  // Validate JWT token
  Future<ApiResponse<Map<String, dynamic>>> validateJWTToken(String token) async {
    try {
      final response = await _httpService.post<Map<String, dynamic>>(
        ApiEndpoints.jwtValidate,
            (data) => data as Map<String, dynamic>,
        body: {'token': token},
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Token validation failed: ${e.toString()}');
    }
  }

  // Refresh JWT token - FIXED SIGNATURE (no parameters needed)
  Future<bool> refreshJWTToken() async {
    try {
      final oldToken = await _secureStorage.getToken();
      if (oldToken == null || oldToken.isEmpty) {
        print('❌ No token to refresh');
        return false;
      }

      final response = await _httpService.post<Map<String, dynamic>>(
        ApiEndpoints.jwtRefresh,
            (data) => data as Map<String, dynamic>,
        body: {'token': oldToken},
      );

      if (response.isSuccess && response.data != null && response.data!['success'] == true) {
        final newToken = response.data!['token'];
        if (newToken != null) {
          await _secureStorage.saveToken(newToken);
          print('✅ Token refreshed successfully');
          return true;
        }
      }

      print('❌ Token refresh failed: ${response.errorMessage}');
      return false;
    } catch (e) {
      print('❌ Token refresh exception: $e');
      return false;
    }
  }

  // Check if JWT token exists and is valid - FIXED to be synchronous if possible
  Future<bool> hasValidJWTToken() async {
    try {
      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // Simple check - if token exists and is not empty, assume valid
      // You can add more sophisticated validation if needed
      return token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Clear JWT token (for UserProvider)
  Future<void> clearJWTToken() async {
    await _secureStorage.deleteToken();
    print('🗑️ JWT token cleared');
  }

  // ==================== EXISTING METHODS (UPDATED) ====================

  // Original login (updated to optionally use JWT)
  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
    bool useJWT = true, // Default to JWT
  }) async {
    if (useJWT) {
      final jwtResponse = await loginWithJWT(email: email, password: password);
      if (jwtResponse.isSuccess && jwtResponse.data != null) {
        // Convert to AuthResponse for compatibility
        return ApiResponse.success(
          AuthResponse.fromJson(jwtResponse.data!),
          message: jwtResponse.message,
        );
      }
      return ApiResponse.error(jwtResponse.errorMessage);
    }

    // Original login logic (non-JWT)
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return ApiResponse.error('Email and password are required');
    }

    try {
      final response = await _httpService.post<AuthResponse>(
        ApiEndpoints.login,
            (data) => AuthResponse.fromJson(data),
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = response.data!;

        // Store user data for persistent login
        if (authResponse.user != null) {
          await _persistUserData(authResponse.user!);
        }

        // Store user email in UserManager for legacy support
        await UserManager.setEmail(email);
        print('✅ Login successful - Session persisted');
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Login failed: ${e.toString()}');
    }
  }

  // Original register (updated to optionally use JWT)
  Future<ApiResponse<AuthResponse>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
    required String confirmPassword,
    bool useJWT = true, // Default to JWT
  }) async {
    if (useJWT) {
      final jwtResponse = await registerWithJWT(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: mobile,
        password: password,
      );

      if (jwtResponse.isSuccess && jwtResponse.data != null) {
        return ApiResponse.success(
          AuthResponse.fromJson(jwtResponse.data!),
          message: jwtResponse.message,
        );
      }
      return ApiResponse.error(jwtResponse.errorMessage);
    }

    // Original registration logic (non-JWT)
    if (firstName.trim().isEmpty || lastName.trim().isEmpty ||
        email.trim().isEmpty || mobile.trim().isEmpty ||
        password.trim().isEmpty || confirmPassword.trim().isEmpty) {
      return ApiResponse.error('All fields are required');
    }

    if (password != confirmPassword) {
      return ApiResponse.error('Passwords do not match');
    }

    try {
      final response = await _httpService.post<AuthResponse>(
        ApiEndpoints.register,
            (data) => AuthResponse.fromJson(data),
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'mobile': mobile,
          'password': password,
          'cpassword': confirmPassword,
        },
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = response.data!;

        // Store user data if available (auto-login after registration)
        if (authResponse.user != null) {
          await _persistUserData(authResponse.user!);
        }
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Registration failed: ${e.toString()}');
    }
  }

  // Update profile - NEW METHOD for UserProvider
  Future<ApiResponse<Map<String, dynamic>>> updateProfile(Map<String, dynamic> updates) async {
    try {
      return await _httpService.put<Map<String, dynamic>>(
        ApiEndpoints.updateProfile,
            (data) => data as Map<String, dynamic>,
        body: updates,
      );
    } catch (e) {
      return ApiResponse.error('Profile update failed: ${e.toString()}');
    }
  }

  // Updated logout to clear JWT token
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    try {
      // Clear JWT token
      await _secureStorage.deleteToken();

      final response = await _httpService.post<Map<String, dynamic>>(
        ApiEndpoints.logout,
            (data) => data as Map<String, dynamic>,
      );

      // Clear local storage regardless of API response
      await _clearLocalData();

      return response;
    } catch (e) {
      // Clear local data even if API call fails
      await _clearLocalData();
      return ApiResponse.error('Logout failed: ${e.toString()}');
    }
  }

  // Updated isAuthenticated to check JWT token
  Future<bool> isAuthenticated() async {
    // First check JWT token
    final hasValidJWT = await hasValidJWTToken();
    if (hasValidJWT) {
      return true;
    }

    // Fallback to legacy check
    final isLoggedIn = _storageService.getBool('is_logged_in') ?? false;
    final hasUserData = _storageService.getString('user_data') != null;

    print('🔍 Auth Check - JWT: $hasValidJWT, Legacy: $isLoggedIn & $hasUserData');

    return isLoggedIn && hasUserData;
  }

  // Get current JWT token
  Future<String?> getJWTToken() async {
    return await _secureStorage.getToken();
  }

  // Helper method to persist user data BOTH in secure storage AND shared preferences
  Future<void> _persistUserData(UserModel user) async {
    try {
      print('💾 Persisting user data for: ${user.email}');

      // Convert user to JSON
      final userJson = user.toJson();
      print('   ├─ User JSON: $userJson');

      // Store in SECURE STORAGE (for ProfileProvider)
      try {
        await _secureStorage.saveUserData(userJson);
        print('   ├─ ✅ Saved to SecureStorage');
      } catch (e) {
        print('   ├─ ❌ SecureStorage error: $e');
      }

      // Store in SHARED PREFERENCES (for legacy compatibility)
      try {
        await _storageService.setString('user_data', jsonEncode(userJson));
        print('   ├─ ✅ Saved to SharedPreferences');
      } catch (e) {
        print('   ├─ ❌ SharedPreferences error: $e');
      }

      // Store is_logged_in flag
      await _storageService.setBool('is_logged_in', true);

      // Store email separately for quick access
      if (user.email != null && user.email!.isNotEmpty) {
        await _storageService.setString('user_email', user.email!);
        await _secureStorage.saveUserEmail(user.email!);
      }

      // Store user ID separately
      if (user.id != null) {
        await _storageService.setString('user_id', user.id!.toString());
        await _secureStorage.saveUserId(user.id!.toString());
      }

      print('✅ User data persisted successfully');
      print('   ├─ User ID: ${user.id}');
      print('   ├─ Email: ${user.email}');
    } catch (e) {
      print('❌ Error persisting user data: $e');
    }
  }

  /// Sync user data between SecureStorage and SharedPreferences
  Future<void> syncUserData() async {
    print('🔄 Syncing user data between storage systems...');

    try {
      // Try to get from SecureStorage first
      final secureUserData = await _secureStorage.getUserData();
      final secureEmail = await _secureStorage.getUserEmail();
      final secureUserId = await _secureStorage.getUserId();

      print('🔍 SecureStorage check:');
      print('   ├─ Has user data: ${secureUserData != null}');
      print('   ├─ Email: $secureEmail');
      print('   ├─ User ID: $secureUserId');

      if (secureUserData != null) {
        // Save to SharedPreferences for legacy compatibility
        await _storageService.setString('user_data', jsonEncode(secureUserData));
        print('✅ Copied from SecureStorage → SharedPreferences');
      }

      // Try to get from SharedPreferences
      final prefUserDataString = _storageService.getString('user_data');
      print('🔍 SharedPreferences check:');
      print('   ├─ Has user data: ${prefUserDataString != null}');

      if (prefUserDataString != null && secureUserData == null) {
        try {
          final prefUserData = json.decode(prefUserDataString) as Map<String, dynamic>;
          await _secureStorage.saveUserData(prefUserData);
          print('✅ Copied from SharedPreferences → SecureStorage');
        } catch (e) {
          print('❌ Error parsing SharedPreferences data: $e');
        }
      }

      // Sync email
      final prefEmail = _storageService.getString('user_email');
      if (prefEmail != null && prefEmail.isNotEmpty && (secureEmail == null || secureEmail!.isEmpty)) {
        await _secureStorage.saveUserEmail(prefEmail);
        print('✅ Copied email from SharedPreferences → SecureStorage');
      }

      if (secureEmail != null && secureEmail.isNotEmpty && (prefEmail == null || prefEmail.isEmpty)) {
        await _storageService.setString('user_email', secureEmail);
        print('✅ Copied email from SecureStorage → SharedPreferences');
      }

      print('✅ User data sync complete');
    } catch (e) {
      print('❌ Error syncing user data: $e');
    }
  }

  // Get user's first name by email
  Future<String?> getFirstName(String email) async {
    try {
      final response = await _httpService.get<Map<String, dynamic>>(
        '/auth/firstName',
            (data) => data as Map<String, dynamic>,
        queryParams: {'email': email},
      );

      if (response.isSuccess && response.data != null) {
        return response.data!['firstName']?.toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user details by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await _httpService.get<Map<String, dynamic>>(
        '/auth/getUserByEmail',
            (data) => data as Map<String, dynamic>,
        queryParams: {'email': email},
      );

      if (response.isSuccess && response.data != null && response.data!['status'] == 'success') {
        return UserModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Forgot password
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String email,
  }) async {
    try {
      return await _httpService.post<Map<String, dynamic>>(
        ApiEndpoints.forgotPassword,
            (data) => data as Map<String, dynamic>,
        body: {
          'email': email,
        },
      );
    } catch (e) {
      return ApiResponse.error('Forgot password failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      return await _httpService.post<Map<String, dynamic>>(
        ApiEndpoints.resetPassword,
            (data) => data as Map<String, dynamic>,
        body: {
          'token': token,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      return ApiResponse.error('Password reset failed: ${e.toString()}');
    }
  }

  // Change password
  Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      return await _httpService.post<Map<String, dynamic>>(
        ApiEndpoints.changePassword,
            (data) => data as Map<String, dynamic>,
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      return ApiResponse.error('Password change failed: ${e.toString()}');
    }
  }

  // Verify email
  Future<ApiResponse<Map<String, dynamic>>> verifyEmail({
    required String token,
  }) async {
    try {
      return await _httpService.post<Map<String, dynamic>>(
        ApiEndpoints.verifyEmail,
            (data) => data as Map<String, dynamic>,
        body: {
          'token': token,
        },
      );
    } catch (e) {
      return ApiResponse.error('Email verification failed: ${e.toString()}');
    }
  }

  /// Get current user from storage (checks both SecureStorage and SharedPreferences)
  Future<UserModel?> getCurrentUser() async {
    try {
      // First try SecureStorage
      final secureUserData = await _secureStorage.getUserData();
      if (secureUserData != null) {
        print('🔍 AuthService.getCurrentUser(): Found in SecureStorage');
        print('   ├─ Email: ${secureUserData['email']}');
        print('   ├─ ID: ${secureUserData['id']}');
        return UserModel.fromJson(secureUserData);
      }

      // Fallback to SharedPreferences
      final userDataString = _storageService.getString('user_data');
      if (userDataString != null) {
        print('🔍 AuthService.getCurrentUser(): Found in SharedPreferences');
        try {
          final Map<String, dynamic> userData = json.decode(userDataString);
          print('   ├─ Email: ${userData['email']}');
          print('   ├─ ID: ${userData['id']}');

          // Migrate to SecureStorage
          await _secureStorage.saveUserData(userData);
          print('✅ Migrated user data to SecureStorage');

          return UserModel.fromJson(userData);
        } catch (e) {
          print('❌ ERROR parsing SharedPreferences user data: $e');
        }
      }

      print('⚠️ AuthService.getCurrentUser(): No user data found in any storage');
      return null;
    } catch (e) {
      print('❌ ERROR in getCurrentUser: $e');
      return null;
    }
  }

  // Get current user email
  Future<String?> getCurrentUserEmail() async {
    final user = await getCurrentUser();
    return user?.email;
  }

  // Get current user ID
  Future<String?> getCurrentUserId() async {
    final user = await getCurrentUser();
    return user?.id?.toString();
  }

  // Get directly stored user ID (faster)
  String? getStoredUserId() {
    return _storageService.getString('user_id');
  }

  // Get directly stored email (faster)
  String? getStoredUserEmail() {
    return _storageService.getString('user_email');
  }

  // Save user data (public method for UserProvider)
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _secureStorage.saveUserData(userData);
      print('✅ AuthService.saveUserData(): User data saved to SecureStorage');
      print('   ├─ Email: ${userData['email']}');
      print('   ├─ ID: ${userData['id']}');
    } catch (e) {
      print('❌ AuthService.saveUserData() error: $e');
      rethrow;
    }
  }

  // Initialize auth service (call this at app startup)
  Future<void> initialize() async {
    print('\n🔄 INITIALIZING AUTH SERVICE...');

    // Sync data between storage systems
    await syncUserData();

    // Check JWT token first
    final hasJWT = await hasValidJWTToken();
    if (hasJWT) {
      print('✅ JWT token is valid');
    } else {
      print('⚠️ No valid JWT token');
    }

    // Check for stored user data
    final user = await getCurrentUser();
    if (user != null) {
      print('✅ User session found');
      print('   ├─ User ID: ${user.id}');
      print('   ├─ User Email: ${user.email}');
      print('   ├─ User Name: ${user.firstName} ${user.lastName}');

      // Also check email from all sources
      print('🔍 Email from all sources:');
      print('   ├─ UserModel: ${user.email}');
      print('   ├─ SecureStorage: ${await _secureStorage.getUserEmail()}');
      print('   ├─ SharedPreferences: ${_storageService.getString('user_email')}');
    } else {
      print('⚠️ No user session found in any storage');
    }

    // Debug: Print all stored data
    await _debugAllStorage();
  }

  /// Debug all storage systems
  Future<void> _debugAllStorage() async {
    print('\n🔍 DEBUG - ALL STORAGE SYSTEMS:');

    // SecureStorage
    try {
      final secureUserData = await _secureStorage.getUserData();
      final secureEmail = await _secureStorage.getUserEmail();
      final secureUserId = await _secureStorage.getUserId();
      final secureToken = await _secureStorage.getToken();

      print('📦 SECURE STORAGE:');
      print('   ├─ User Data: ${secureUserData != null ? "EXISTS" : "NULL"}');
      if (secureUserData != null) {
        print('   ├─ Email in user data: ${secureUserData['email']}');
      }
      print('   ├─ Email (separate): $secureEmail');
      print('   ├─ User ID: $secureUserId');
      print('   ├─ JWT Token: ${secureToken != null ? "EXISTS" : "NULL"}');
    } catch (e) {
      print('❌ SecureStorage debug error: $e');
    }

    // SharedPreferences
    try {
      final prefUserData = _storageService.getString('user_data');
      final prefEmail = _storageService.getString('user_email');
      final prefUserId = _storageService.getString('user_id');
      final prefIsLoggedIn = _storageService.getBool('is_logged_in');

      print('📦 SHARED PREFERENCES:');
      print('   ├─ User Data: ${prefUserData != null ? "EXISTS" : "NULL"}');
      print('   ├─ Email: $prefEmail');
      print('   ├─ User ID: $prefUserId');
      print('   ├─ Is Logged In: $prefIsLoggedIn');
    } catch (e) {
      print('❌ SharedPreferences debug error: $e');
    }
  }

  // Clear local authentication data
  Future<void> _clearLocalData() async {
    print('🧹 Clearing local auth data...');
    // Clear JWT token
    await _secureStorage.deleteToken();

    // Clear legacy data
    await UserManager.clearSession();
    await _storageService.remove('is_logged_in');
    await _storageService.remove('user_data');
    await _storageService.remove('user_email');
    await _storageService.remove('user_id');
    print('✅ Local auth data cleared');
  }

  // Force clear all auth data (for debugging)
  Future<void> clearAllAuthData() async {
    await _clearLocalData();
  }

  // Debug method
  Future<void> debugStorage() async {
    await _debugAllStorage();
  }

  // ==================== ADDITIONAL HELPER METHODS ====================

  // Check if user is logged in (simple synchronous check)
  bool isLoggedInSync() {
    return _storageService.getBool('is_logged_in') ?? false;
  }

  // Get user ID synchronously
  String? getUserIdSync() {
    return _storageService.getString('user_id');
  }

  // Get email synchronously
  String? getUserEmailSync() {
    return _storageService.getString('user_email');
  }

  // Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  // Validate password strength
  bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  // Clear all data (for testing)
  Future<void> clearEverything() async {
    await _secureStorage.clearAll();
    await _storageService.clear();
    print('🧹 All auth data cleared');
  }
}