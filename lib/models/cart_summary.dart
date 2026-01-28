// models/cart_summary.dart
import 'cart_item.dart';

class CartSummary {
  final List<CartItem> items;
  final int itemCount;
  final double totalPrice;
  final double discountedPrice;
  final double discountAmount;

  CartSummary({
    required this.items,
    required this.itemCount,
    required this.totalPrice,
    required this.discountedPrice,
    required this.discountAmount,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    List<CartItem> items = [];
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList();
    }

    return CartSummary(
      items: items,
      itemCount: json['itemCount'] ?? 0,
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      discountedPrice: (json['discountedPrice'] ?? 0.0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'itemCount': itemCount,
      'totalPrice': totalPrice,
      'discountedPrice': discountedPrice,
      'discountAmount': discountAmount,
    };
  }
}