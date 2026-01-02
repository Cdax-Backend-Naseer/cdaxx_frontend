// Hero Banner Widget
// Displays main hero section for public dashboard

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/dashboard/dashboard_public_model.dart';

class HeroBannerWidget extends StatelessWidget {
  final HeroBanner heroBanner;

  const HeroBannerWidget({
    super.key,
    required this.heroBanner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image (if provided)
          if (heroBanner.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                heroBanner.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.image,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Hero Title
          Text(
            heroBanner.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 12),

          // Hero Subtitle
          Text(
            heroBanner.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // CTA Buttons
          if (screenWidth > 600) ...[
            // Desktop layout - horizontal buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleCTAPress(context),
                  icon: const Icon(Icons.explore),
                  label: Text(heroBanner.ctaLabel),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/signup'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Sign Up Free'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Mobile layout - stacked buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleCTAPress(context),
                    icon: const Icon(Icons.explore),
                    label: Text(heroBanner.ctaLabel),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/signup'),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Sign Up Free'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Features/Benefits row
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildFeatureChip(
                context,
                Icons.play_circle,
                'Free previews',
              ),
              _buildFeatureChip(
                context,
                Icons.workspace_premium,
                'Certificates',
              ),
              _buildFeatureChip(
                context,
                Icons.support,
                'Expert support',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleCTAPress(BuildContext context) {
    if (heroBanner.ctaRoute != null && heroBanner.ctaRoute!.isNotEmpty) {
      context.push(heroBanner.ctaRoute!);
    } else {
      // Default action - browse courses
      context.push('/dashboard/courses');
    }
  }

  Widget _buildFeatureChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}