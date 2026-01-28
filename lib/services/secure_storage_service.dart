// Updated Secure Storage Service with JWT support
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure storage service for JWT tokens and other secure data.
class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService _instance = SecureStorageService._();
  static SecureStorageService get instance => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Key constants
  static const String _jwtTokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _customerTokenKey = 'customer_token';
  static const String _sessionTokenKey = 'session_token';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _paymentMethodTokenKey = 'payment_method_token';

  // ==================== JWT TOKEN METHODS ====================

  /// Save JWT token
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _jwtTokenKey, value: token);
      debugPrint('✅ JWT token saved to secure storage');
    } catch (e) {
      debugPrint('❌ Failed to save JWT token: $e');
      rethrow;
    }
  }

  /// Get JWT token
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _jwtTokenKey);
    } catch (e) {
      debugPrint('❌ Failed to read JWT token: $e');
      return null;
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      debugPrint('❌ Failed to save refresh token: $e');
      rethrow;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Failed to read refresh token: $e');
      return null;
    }
  }

  /// Delete JWT token
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _jwtTokenKey);
      debugPrint('✅ JWT token deleted from secure storage');
    } catch (e) {
      debugPrint('❌ Failed to delete JWT token: $e');
      rethrow;
    }
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Failed to delete refresh token: $e');
      rethrow;
    }
  }

  /// Delete JWT tokens (both access and refresh)
  Future<void> deleteJWTTokens() async {
    try {
      await deleteToken();
      await deleteRefreshToken();
      debugPrint('✅ All JWT tokens deleted');
    } catch (e) {
      debugPrint('❌ Failed to delete JWT tokens: $e');
      rethrow;
    }
  }

  /// Check if JWT token exists
  Future<bool> hasToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Failed to check JWT token: $e');
      return false;
    }
  }

  // ==================== EXISTING METHODS (UPDATED) ====================

  /// Store customer authentication token
  Future<void> storeCustomerToken(String token) async {
    try {
      await _storage.write(key: _customerTokenKey, value: token);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to store customer token: $e');
      rethrow;
    }
  }

  /// Retrieve customer authentication token
  Future<String?> getCustomerToken() async {
    try {
      return await _storage.read(key: _customerTokenKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorageService: Failed to read customer token: $e');
      }
      return null;
    }
  }

  /// Store session token
  Future<void> storeSessionToken(String token) async {
    try {
      await _storage.write(key: _sessionTokenKey, value: token);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to store session token: $e');
      rethrow;
    }
  }

  /// Retrieve session token
  Future<String?> getSessionToken() async {
    try {
      return await _storage.read(key: _sessionTokenKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorageService: Failed to read session token: $e');
      }
      return null;
    }
  }

  /// Store payment method token
  Future<void> storePaymentMethodToken(String token) async {
    try {
      await _storage.write(key: _paymentMethodTokenKey, value: token);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to store payment method token: $e');
      rethrow;
    }
  }

  /// Retrieve payment method token
  Future<String?> getPaymentMethodToken() async {
    try {
      return await _storage.read(key: _paymentMethodTokenKey);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to read payment method token: $e');
      return null;
    }
  }

  /// Store user preferences as JSON string
  Future<void> storeUserPreferences(String preferencesJson) async {
    try {
      await _storage.write(key: _userPreferencesKey, value: preferencesJson);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to store user preferences: $e');
      rethrow;
    }
  }

  /// Retrieve user preferences JSON string
  Future<String?> getUserPreferences() async {
    try {
      return await _storage.read(key: _userPreferencesKey);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to read user preferences: $e');
      return null;
    }
  }

  /// Store arbitrary secure data
  Future<void> store(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to store data for key $key: $e');
      rethrow;
    }
  }

  /// Retrieve arbitrary secure data
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to read data for key $key: $e');
      return null;
    }
  }

  /// Delete specific key
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to delete key $key: $e');
      rethrow;
    }
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('SecureStorageService: Failed to clear all data: $e');
      rethrow;
    }
  }

  /// Check if storage contains a specific key
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to check key $key: $e');
      return false;
    }
  }

  /// Get all keys
  Future<Set<String>> getAllKeys() async {
    try {
      final all = await _storage.readAll();
      return all.keys.toSet();
    } catch (e) {
      debugPrint('SecureStorageService: Failed to get all keys: $e');
      return {};
    }
  }

  /// Clear payment-related tokens only
  Future<void> clearPaymentTokens() async {
    try {
      await delete(_paymentMethodTokenKey);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to clear payment tokens: $e');
      rethrow;
    }
  }

  /// Clear authentication tokens only
  Future<void> clearAuthTokens() async {
    try {
      await deleteJWTTokens();
      await delete(_customerTokenKey);
      await delete(_sessionTokenKey);
    } catch (e) {
      debugPrint('SecureStorageService: Failed to clear auth tokens: $e');
      rethrow;
    }
  }

  /// Get JWT token - alias for getToken (for backward compatibility)
  /// Get JWT token - alias for getToken (for backward compatibility)
  Future<String?> getJWTToken() async {
    print('🔍 SecureStorageService.getJWTToken() called');
    final token = await getToken();
    print('🔍 getJWTToken result: ${token != null ? "EXISTS" : "NULL"}');
    return token;
  }

  /// Delete JWT token - alias for deleteToken (for backward compatibility)
  Future<void> deleteJWTToken() async => deleteToken();




  // Add these constants at the top with other key constants
  static const String _userDataKey = 'user_data'; // Add this
  static const String _userEmailKey = 'user_email'; // Add this
  static const String _userIdKey = 'user_id'; // Add this

// ==================== USER DATA METHODS ====================

  /// Save complete user data as JSON
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final userJson = jsonEncode(userData);
      await _storage.write(key: _userDataKey, value: userJson);
      debugPrint('✅ User data saved to secure storage');

      // Also save email and ID separately for quick access
      if (userData['email'] != null) {
        await saveUserEmail(userData['email']);
      }
      if (userData['id'] != null) {
        await saveUserId(userData['id'].toString());
      }
    } catch (e) {
      debugPrint('❌ Failed to save user data: $e');
      rethrow;
    }
  }

  /// Get complete user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userJson = await _storage.read(key: _userDataKey);
      if (userJson != null && userJson.isNotEmpty) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        debugPrint('✅ User data retrieved from secure storage');
        return userData;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to read user data: $e');
      return null;
    }
  }

  /// Save user email separately
  Future<void> saveUserEmail(String email) async {
    try {
      await _storage.write(key: _userEmailKey, value: email);
      debugPrint('✅ User email saved: $email');
    } catch (e) {
      debugPrint('❌ Failed to save user email: $e');
    }
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _userEmailKey);
    } catch (e) {
      debugPrint('❌ Failed to read user email: $e');
      return null;
    }
  }

  /// Save user ID separately
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      debugPrint('✅ User ID saved: $userId');
    } catch (e) {
      debugPrint('❌ Failed to save user ID: $e');
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('❌ Failed to read user ID: $e');
      return null;
    }
  }

  /// Delete all user data
  Future<void> deleteUserData() async {
    try {
      await _storage.delete(key: _userDataKey);
      await _storage.delete(key: _userEmailKey);
      await _storage.delete(key: _userIdKey);
      debugPrint('✅ All user data deleted');
    } catch (e) {
      debugPrint('❌ Failed to delete user data: $e');
      rethrow;
    }
  }

  /// Check if user data exists
  Future<bool> hasUserData() async {
    try {
      final userJson = await _storage.read(key: _userDataKey);
      return userJson != null && userJson.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Failed to check user data: $e');
      return false;
    }
  }

  /// Get all user-related data (for debugging)
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final userData = await getUserData();
      final email = await getUserEmail();
      final userId = await getUserId();
      final jwtToken = await getJWTToken();

      return {
        'userData': userData,
        'email': email,
        'userId': userId,
        'hasJWT': jwtToken != null && jwtToken.isNotEmpty,
      };
    } catch (e) {
      debugPrint('❌ Failed to get user info: $e');
      return {};
    }
  }
}