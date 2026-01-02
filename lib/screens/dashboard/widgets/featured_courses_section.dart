// Featured Courses Section Widget
// Displays featured courses in a horizontal scrollable list

import 'package:flutter/material.dart';
import '../../../screens/courses/data/models/course.dart';

class FeaturedCoursesSection extends StatelessWidget {
  final List<Course> featuredCourses;
  final Function(Course) onCourseTap;

  const FeaturedCoursesSection({
    super.key,
    required this.featuredCourses,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Courses',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/dashboard/courses'),
              child: const Text('View All'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),

        // Courses List
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: featuredCourses.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final course = featuredCourses[index];
              return _buildCourseCard(context, course, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course, ThemeData theme) {
    return SizedBox(
      width: 280,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => onCourseTap(course),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  course.thumbnailUrl,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 140,
                    color: theme.colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              // Course Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Title
                      Text(
                        course.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),

                      // Course Description
                      Expanded(
                        child: Text(
                          course.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Course Metadata
                      Row(
                        children: [
                          // Rating
                          if (course.rating != null) ...[
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course.rating!.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          
                          // Student Count
                          if (course.studentsCount != null) ...[
                            Icon(
                              Icons.people,
                              size: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatStudentCount(course.studentsCount!),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: course.isSubscribed
                            ? ElevatedButton(
                                onPressed: () => onCourseTap(course),
                                child: const Text('Continue'),
                              )
                            : OutlinedButton(
                                onPressed: () => onCourseTap(course),
                                child: const Text('Preview'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStudentCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}