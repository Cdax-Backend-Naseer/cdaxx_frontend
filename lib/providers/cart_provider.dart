// providers/cart_provider.dart
import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService;
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  bool _isInitialized = false; // Add this

  CartProvider(this._cartService);

  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; // Add this getter
  int get itemCount => _cartItems.length;

  double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) => sum + item.price);
  }

  // Initialize with user ID
  void initialize(String userId) {
    _cartService.setUserId(userId);
    _isInitialized = true; // Set to true
    loadCart();
  }

  // Load cart items
  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      _cartItems = await _cartService.getCartItems();
    } catch (e) {
      print('Error loading cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add course to cart
  Future<void> addToCart({
    required String courseId,
    required String title,
    required double price,
    String? thumbnailUrl,
  }) async {
    try {
      // Check if already in cart
      if (_cartItems.any((item) => item.courseId == courseId)) {
        throw Exception('Course already in cart');
      }

      // Add to local state
      final item = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseId: courseId,
        title: title,
        price: price,
        thumbnailUrl: thumbnailUrl,
        addedAt: DateTime.now(),
      );
      _cartItems.add(item);
      notifyListeners();

      // Call API
      await _cartService.addToCart(courseId);
    } catch (e) {
      _cartItems.removeWhere((item) => item.courseId == courseId);
      notifyListeners();
      rethrow;
    }
  }

  // Remove course from cart
  Future<void> removeFromCart(String courseId) async {
    try {
      _cartItems.removeWhere((item) => item.courseId == courseId);
      notifyListeners();

      await _cartService.removeFromCart(courseId);
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  // Clear entire cart
  Future<void> clearCart() async {
    try {
      _cartItems.clear();
      notifyListeners();

      await _cartService.clearCart();
    } catch (e) {
      notifyListeners();
      rethrow;
    }
  }

  // Check if course is in cart
  bool isInCart(String courseId) {
    return _cartItems.any((item) => item.courseId == courseId);
  }

  // Get cart summary
  Future<Map<String, dynamic>> getCartSummary() async {
    try {
      final summary = await _cartService.getCartSummary();
      return {
        'itemCount': summary.itemCount,
        'totalPrice': summary.totalPrice,
        'discountedPrice': summary.discountedPrice,
        'discountAmount': summary.discountAmount,
      };
    } catch (e) {
      print('Error getting cart summary: $e');
      return {
        'itemCount': itemCount,
        'totalPrice': totalPrice,
        'discountedPrice': totalPrice,
        'discountAmount': 0.0,
      };
    }
  }

  // Checkout
  Future<Map<String, dynamic>> checkout({
    String paymentMethod = 'CREDIT_CARD',
    String? couponCode,
  }) async {
    try {
      final courseIds = _cartItems.map((item) => item.courseId).toList();
      final response = await _cartService.checkout(
        courseIds: courseIds,
        paymentMethod: paymentMethod,
        couponCode: couponCode,
      );

      if (response.success) {
        // Clear cart on successful checkout
        _cartItems.clear();
        _isInitialized = false; // Reset initialization
        notifyListeners();
      }

      return {
        'success': response.success,
        'orderId': response.orderId,
        'message': response.message,
        'purchasedCourses': response.purchasedCourses,
      };
    } catch (e) {
      print('Error during checkout: $e');
      rethrow;
    }
  }

  // Refresh cart
  Future<void> refresh() async {
    await loadCart();
  }

  // Clear cart data (on logout)
  void clear() {
    _cartItems.clear();
    _isInitialized = false; // Reset
    notifyListeners();
  }
}