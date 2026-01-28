// services/cart_service.dart - UPDATED WITH HttpService
import '../services/http_service.dart';
import '../models/cart_item.dart';
import '../models/cart_summary.dart';
import '../models/checkout_response.dart';

class CartService {
  final HttpService _httpService;
  String? _userId;

  CartService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  void setUserId(String userId) {
    _userId = userId;
  }

  Future<List<CartItem>> getCartItems() async {
    if (_userId == null) throw Exception('User ID not set');

    try {
      final response = await _httpService.get<List<dynamic>>(
        '/api/cart/$_userId',
            (data) => data as List<dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return data.map((item) => CartItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load cart: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error loading cart: $e');
      return [];
    }
  }

  Future<CartItem> addToCart(String courseId) async {
    if (_userId == null) throw Exception('User ID not set');

    try {
      final response = await _httpService.post<Map<String, dynamic>>(
        '/api/cart/$_userId/add/$courseId',
            (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return CartItem.fromJson(response.data!);
      } else {
        throw Exception('Failed to add to cart: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String courseId) async {
    if (_userId == null) throw Exception('User ID not set');

    try {
      final response = await _httpService.delete<dynamic>(
        '/api/cart/$_userId/remove/$courseId',
            (data) => data,
      );

      if (!response.isSuccess) {
        throw Exception('Failed to remove from cart: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error removing from cart: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    if (_userId == null) throw Exception('User ID not set');

    try {
      final response = await _httpService.delete<dynamic>(
        '/api/cart/$_userId/clear',
            (data) => data,
      );

      if (!response.isSuccess) {
        throw Exception('Failed to clear cart: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }

  Future<CartSummary> getCartSummary() async {
    if (_userId == null) throw Exception('User ID not set');

    try {
      final response = await _httpService.get<Map<String, dynamic>>(
        '/api/cart/$_userId/summary',
            (data) => data as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return CartSummary.fromJson(response.data!);
      } else {
        throw Exception('Failed to get cart summary: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error getting cart summary: $e');
      return CartSummary(
        items: [],
        itemCount: 0,
        totalPrice: 0.0,
        discountedPrice: 0.0,
        discountAmount: 0.0,
      );
    }
  }

  Future<CheckoutResponse> checkout({
    required List<String> courseIds,
    String paymentMethod = 'CREDIT_CARD',
    String? couponCode,
  }) async {
    if (_userId == null) throw Exception('User ID not set');

    try {
      final body = {
        'courseIds': courseIds.map((id) => int.parse(id)).toList(),
        'paymentMethod': paymentMethod,
        if (couponCode != null) 'couponCode': couponCode,
      };

      final response = await _httpService.post<Map<String, dynamic>>(
        '/api/cart/$_userId/checkout',
            (data) => data as Map<String, dynamic>,
        body: body,
      );

      if (response.isSuccess && response.data != null) {
        return CheckoutResponse.fromJson(response.data!);
      } else {
        throw Exception('Checkout failed: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error during checkout: $e');
      rethrow;
    }
  }
}