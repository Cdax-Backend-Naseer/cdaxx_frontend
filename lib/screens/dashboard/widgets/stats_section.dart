// Stats Section Widget
// Displays platform statistics for social proof

import 'package:flutter/material.dart';
import '../../../models/dashboard/dashboard_public_model.dart';

class StatsSection extends StatelessWidget {
  final PublicStats stats;

  const StatsSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Section Title
          Text(
            'Join Our Learning Community',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Thousands of learners are already advancing their careers',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),

          // Stats Grid
          Row(
            children: [
              // Total Courses
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.menu_book,
                  stats.totalCourses.toString(),
                  'Courses',
                  theme,
                ),
              ),
              
              // Divider
              Container(
                height: 60,
                width: 1,
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
              
              // Total Students
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.people,
                  _formatNumber(stats.totalStudents),
                  'Students',
                  theme,
                ),
              ),
              
              // Divider (if rating exists)
              if (stats.averageRating != null) ...[
                Container(
                  height: 60,
                  width: 1,
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
                
                // Average Rating
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.star,
                    stats.averageRating!.toStringAsFixed(1),
                    'Rating',
                    theme,
                    color: Colors.amber[600],
                  ),
                ),
              ],
            ],
          ),

          // Top Instructor (if available)
          if (stats.topInstructor != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      Icons.school,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Instructor',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          stats.topInstructor!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    ThemeData theme, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: color ?? theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}