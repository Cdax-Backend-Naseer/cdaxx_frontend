import 'package:flutter/material.dart';
import '../../courses/data/models/module.dart';

class ModuleRow extends StatelessWidget {
  const ModuleRow({
    super.key,
    required this.module,
    this.onPlay,
    this.isLocked, // Optional override for locking
    this.lockReason, // Custom lock message
    // Optional theme colors
    this.titleColor,
    this.subtitleColor,
    this.lockedTextColor,
  });

  final Module module;
  final VoidCallback? onPlay;
  final bool? isLocked;
  final String? lockReason;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? lockedTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use the override if provided, otherwise use module's isLocked
    final bool locked = isLocked ?? (module.isLocked ?? true);

    // Use custom lock reason if provided
    final String lockMessage = lockReason ?? '';

    final effectiveTitleColor =
        titleColor ?? theme.textTheme.bodyLarge?.color ?? Colors.white;
    final effectiveSubtitleColor =
        subtitleColor ?? theme.textTheme.bodyMedium?.color ?? Colors.white70;
    final effectiveLockedColor =
        lockedTextColor ?? theme.colorScheme.primary ?? const Color(0xFF38BDF8);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: locked
              ? const Color(0xFF374151).withOpacity(0.5)
              : const Color(0xFF38BDF8).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          locked ? Icons.lock_outline : Icons.play_circle_outline,
          color: locked ? Colors.white70 : effectiveLockedColor,
          size: 24,
        ),
      ),
      title: Text(
        module.title,
        style: TextStyle(
          color: effectiveTitleColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            '${(module.durationSec / 60).round()} min',
            style: TextStyle(
              color: effectiveSubtitleColor,
              fontSize: 12,
            ),
          ),
          if (locked && lockMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                lockMessage,
                style: TextStyle(
                  color: effectiveLockedColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      trailing: locked
          ? null
          : IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveLockedColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow,
            color: effectiveLockedColor,
            size: 20,
          ),
        ),
        onPressed: onPlay,
      ),
    );
  }
}