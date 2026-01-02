import 'package:flutter/material.dart';
import '../../courses/data/models/module.dart';

class ModuleRow extends StatelessWidget {
  const ModuleRow({
    super.key,
    required this.module,
    this.onPlay,

    // 🔹 OPTIONAL THEME COLORS
    this.titleColor,
    this.subtitleColor,
    this.lockedTextColor,
  });

  final Module module;
  final VoidCallback? onPlay;

  // 🔹 New optional params
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? lockedTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = module.isLocked ?? true;

    final effectiveTitleColor =
        titleColor ?? theme.textTheme.bodyLarge?.color;
    final effectiveSubtitleColor =
        subtitleColor ?? theme.textTheme.bodyMedium?.color;
    final effectiveLockedColor =
        lockedTextColor ?? theme.colorScheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(
        isLocked ? Icons.lock : Icons.play_circle,
        color: isLocked ? effectiveLockedColor : effectiveTitleColor,
      ),
      title: Text(
        module.title,
        style: TextStyle(color: effectiveTitleColor),
      ),
      subtitle: Text(
        '${(module.durationSec / 60).round()} min',
        style: TextStyle(color: effectiveSubtitleColor),
      ),
      trailing: isLocked
          ? Text(
        'Subscription required',
        style: TextStyle(
          color: effectiveLockedColor,
          fontWeight: FontWeight.w600,
        ),
      )
          : IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: onPlay,
        color: effectiveTitleColor,
      ),
    );
  }
}
