// models/cart_item.dart
class CartItem {
  final String id;
  final String courseId;
  final String title;
  final double price;
  final String? thumbnailUrl;
  final int duration; // in minutes
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.courseId,
    required this.title,
    required this.price,
    this.thumbnailUrl,
    this.duration = 0,
    required this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      title: json['courseTitle'] ?? json['title'] ?? 'Untitled Course',
      price: (json['price'] ?? 0.0).toDouble(),
      thumbnailUrl: json['thumbnailUrl'] ?? json['courseThumbnail'],
      duration: json['duration'] ?? 0,
      addedAt: DateTime.parse(json['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'price': price,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}