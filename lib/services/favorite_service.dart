// services/favorite_service.dart - UPDATED WITH HttpService
import '../services/http_service.dart';
import '../models/favorite_course.dart';

class FavoriteService {
  final HttpService _httpService;
  String? _userId;

  FavoriteService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

// In favorite_service.dart, update the setUserId method:
  void setUserId(String userId) {
    print('🔍 FavoriteService: Setting userId = $userId');
    print('   ├─ Type: ${userId.runtimeType}');
    print('   ├─ Is numeric: ${isNumeric(userId)}');
    _userId = userId;
  }

  bool isNumeric(String s) {
    if (s == null) return false;
    return double.tryParse(s) != null;
  }

  Future<List<FavoriteCourse>> getUserFavorites() async {
    if (_userId == null) throw Exception('User ID not set');

    try {
      final response = await _httpService.get<List<dynamic>>(
        '/api/favorites/$_userId',
            (data) => data as List<dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return data.map((item) => FavoriteCourse.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load favorites: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error loading favorites: $e');
      rethrow;
    }
  }

  Future<FavoriteCourse> addToFavorite(String courseId) async {
    if (_userId == null) throw Exception('User ID not set');

    try {
      final response = await _httpService.post<Map<String, dynamic>>(
        '/api/favorites/$_userId/add/$courseId',
            (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return FavoriteCourse.fromJson(response.data!);
      } else {
        throw Exception('Failed to add to favorites: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorite(String courseId) async {
    if (_userId == null) throw Exception('User ID not set');

    try {
      final response = await _httpService.delete<dynamic>(
        '/api/favorites/$_userId/remove/$courseId',
            (data) => data,
      );

      if (!response.isSuccess) {
        throw Exception('Failed to remove from favorites: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }
}