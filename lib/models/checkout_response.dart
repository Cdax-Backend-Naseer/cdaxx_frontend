// models/checkout_response.dart
class CheckoutResponse {
  final bool success;
  final String? orderId;
  final double totalAmount;
  final double amountPaid;
  final String paymentStatus;
  final List<String> purchasedCourses;
  final String message;

  CheckoutResponse({
    required this.success,
    this.orderId,
    required this.totalAmount,
    required this.amountPaid,
    required this.paymentStatus,
    required this.purchasedCourses,
    required this.message,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      success: json['success'] ?? false,
      orderId: json['orderId'],
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0.0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      purchasedCourses: List<String>.from(json['purchasedCourses'] ?? []),
      message: json['message'] ?? '',
    );
  }
}