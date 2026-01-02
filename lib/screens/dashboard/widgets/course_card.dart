import 'package:flutter/material.dart';

/// Reusable course card
/// - Rounded corners (14), elevation 2, padding 12
/// - Thumbnail, title, progress bar, locked state
/// - Tappable to trigger navigation
class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.title,
    required this.thumbnailUrl,
    required this.progressPercent, // 0.0 - 1.0
    this.subtitle,
    this.isLocked = false,
    this.onTap,
    this.width,
    this.totalVideos, // NEW: Total videos count
    this.completedVideos, // NEW: Completed videos count
    this.totalModules, // NEW: Total modules count
    this.completedModules, // NEW: Completed modules count
    this.showDetailedStats = false, // NEW: Show video/module counts
  });

  final String title;
  final String thumbnailUrl;
  final double progressPercent; // 0.0 - 1.0
  final String? subtitle;
  final bool isLocked;
  final VoidCallback? onTap;
  final double? width;

  // NEW: Detailed stats parameters
  final int? totalVideos;
  final int? completedVideos;
  final int? totalModules;
  final int? completedModules;
  final bool showDetailedStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Course title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.1),
                        ),
                      ],

                      // NEW: Show video and module counts if available
                      if (showDetailedStats && (totalVideos != null || totalModules != null))
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              // Videos count
                              if (totalVideos != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.video_library,
                                      size: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$completedVideos/$totalVideos',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),

                              // Modules count
                              if (totalModules != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.library_books,
                                      size: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$completedModules/$totalModules',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Progress bar with percentage
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress percentage text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(progressPercent * 100).round()}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getProgressColor(progressPercent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: progressPercent.clamp(0.0, 1.0),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: _getProgressColor(progressPercent),
                        ),
                      ),

                      // NEW: Detailed progress text
                      if (showDetailedStats && (totalVideos != null || totalModules != null))
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (totalVideos != null)
                                Text(
                                  '$completedVideos/$totalVideos videos',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),

                              if (totalModules != null)
                                Text(
                                  '$completedModules/$totalModules modules',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Locked indicator
                if (isLocked) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.lock, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Locked',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to get progress color based on percentage
  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.amber;
    if (progress >= 0.25) return Colors.orange;
    return Colors.red;
  }
}