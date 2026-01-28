// providers/favorite_provider.dart
import 'package:flutter/material.dart';
import '../services/favorite_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final FavoriteService _favoriteService;
  Set<String> _favoriteCourseIds = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  FavoriteProvider(this._favoriteService);

  Set<String> get favoriteCourseIds => _favoriteCourseIds;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  int get favoriteCount => _favoriteCourseIds.length;

  // Initialize with user ID
  void initialize(String userId) {
    _favoriteService.setUserId(userId);
    _isInitialized = true;
    loadFavorites();
  }

  // Load user's favorites
  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final favorites = await _favoriteService.getUserFavorites();
      _favoriteCourseIds = Set.from(favorites.map((f) => f.courseId));
    } catch (e) {
      print('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // In providers/favorite_provider.dart - Add these debug prints

  Future<void> addToFavorites(String courseId) async {
    if (!_isInitialized) {
      print('⚠️ FavoriteProvider not initialized');
      return;
    }

    print('➕ Adding course $courseId to favorites...');
    try {
      await _favoriteService.addToFavorite(courseId);
      _favoriteCourseIds.add(courseId);
      print('✅ Added course $courseId to favorites. Total: ${_favoriteCourseIds.length}');
      notifyListeners(); // This triggers UI updates
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String courseId) async {
    if (!_isInitialized) {
      print('⚠️ FavoriteProvider not initialized');
      return;
    }

    print('➖ Removing course $courseId from favorites...');
    try {
      await _favoriteService.removeFromFavorite(courseId);
      _favoriteCourseIds.remove(courseId);
      print('✅ Removed course $courseId from favorites. Total: ${_favoriteCourseIds.length}');
      notifyListeners(); // This triggers UI updates
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      rethrow;
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String courseId) async {
    if (!_isInitialized) {
      print('⚠️ FavoriteProvider not initialized');
      return;
    }

    try {
      if (isFavorite(courseId)) {
        await removeFromFavorites(courseId);
      } else {
        await addToFavorites(courseId);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Check if course is favorite
  bool isFavorite(String courseId) {
    if (!_isInitialized) return false;
    return _favoriteCourseIds.contains(courseId);
  }

  // Refresh favorites
  Future<void> refresh() async {
    await loadFavorites();
  }

  // Clear favorites (on logout) - ADD THIS METHOD
  void clear() {
    _favoriteCourseIds.clear();
    _isInitialized = false;
    notifyListeners();
    print('✅ Favorites cleared');
  }

  // Add userId for debugging
  String? getUserId() {
    // This depends on how your FavoriteService exposes userId
    // You might need to add a getter in FavoriteService
    return null; // Update based on your service
  }
}