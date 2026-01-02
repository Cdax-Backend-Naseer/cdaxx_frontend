/// Video Model - Backend Compatible
/// Matches exactly with backend Video entity JSON structure
class VideoModel {
  final int id;
  final String title;
  final String videoUrl; // Backend uses 'videoUrl', not 'youtubeUrl'
  
  // Backend provides both old and new naming conventions
  // final bool locked; // old naming
  // final bool completed; // old naming
  final bool isLocked; // new naming
  final bool isCompleted; // new naming
  
  VideoModel({
    required this.id,
    required this.title,
    required this.videoUrl,
    // this.locked = true,
    // this.completed = false,
    this.isLocked = true,
    this.isCompleted = false,
  });
  
  // Getters for consistent access (prefer new naming)
  bool get isVideoLocked => isLocked;
  bool get isVideoCompleted => isCompleted;
  
  // For compatibility, also provide youtubeUrl getter
  String get youtubeUrl => videoUrl;
  
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',
      
      // Handle both naming conventions from backend
      // locked: json['locked'] ?? json['isLocked'] ?? true,
      // completed: json['completed'] ?? json['isCompleted'] ?? false,
      isLocked: json['isLocked'] ?? json['locked'] ?? true,
      isCompleted: json['isCompleted'] ?? json['completed'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'videoUrl': videoUrl,
      // 'locked': locked,
      // 'completed': completed,
      'isLocked': isLocked,
      'isCompleted': isCompleted,
    };
  }
  
  VideoModel copyWith({
    int? id,
    String? title,
    String? videoUrl,
    bool? locked,
    bool? completed,
    bool? isLocked,
    bool? isCompleted,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      // locked: locked ?? this.locked,
      // completed: completed ?? this.completed,
      isLocked: isLocked ?? this.isLocked,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}