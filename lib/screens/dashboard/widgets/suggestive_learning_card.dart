import 'package:flutter/material.dart';
import '../../../core/widgets/app_button.dart';

/// Suggestive Learning CTA card
/// - Large image, short description, CTA button
class SuggestiveLearningCard extends StatelessWidget {
  const SuggestiveLearningCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String imageUrl;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.08), // Glass effect background
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  colorBlendMode: BlendMode.darken,
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white, // White text for dark theme
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70, // Light white for description
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              onPressed: onPressed,
              label: 'Start Learning',
              isStyled: true,
            ),
          ],
        ),
      ),
    );
  }
}