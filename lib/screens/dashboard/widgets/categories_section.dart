// Categories Section Widget
// Displays popular course categories as chips

import 'package:flutter/material.dart';

class CategoriesSection extends StatelessWidget {
  final List<String> categories;
  final Function(String) onCategoryTap;

  const CategoriesSection({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          'Explore Categories',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Find courses in your field of interest',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        
        const SizedBox(height: 16),

        // Categories Chips
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((category) {
            return _buildCategoryChip(context, category, theme);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(BuildContext context, String category, ThemeData theme) {
    final icon = _getCategoryIcon(category);
    
    return InkWell(
      onTap: () => onCategoryTap(category),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mobile':
      case 'mobile development':
        return Icons.phone_android;
      case 'web':
      case 'web development':
        return Icons.web;
      case 'data':
      case 'data science':
        return Icons.bar_chart;
      case 'ai':
      case 'artificial intelligence':
        return Icons.psychology;
      case 'cloud':
      case 'cloud computing':
        return Icons.cloud;
      case 'design':
      case 'ui/ux':
        return Icons.design_services;
      case 'business':
        return Icons.business_center;
      case 'marketing':
        return Icons.campaign;
      case 'programming':
      case 'coding':
        return Icons.code;
      case 'database':
        return Icons.storage;
      case 'security':
      case 'cybersecurity':
        return Icons.security;
      case 'devops':
        return Icons.settings_applications;
      default:
        return Icons.category;
    }
  }
}