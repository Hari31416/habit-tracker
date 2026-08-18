import 'package:flutter/material.dart';
import '../../../domain/engines/streak_calculator.dart';

class StatsMetricStrip extends StatelessWidget {
  final StreakResult streak;
  final String streakUnit;
  final Color accentColor;

  const StatsMetricStrip({
    super.key,
    required this.streak,
    required this.streakUnit,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Current Streak Card
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            iconColor: theme.colorScheme.tertiary,
            value: '${streak.currentStreak}',
            label: 'Current ($streakUnit)',
          ),
        ),
        const SizedBox(width: 8),

        // Best Streak Card
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events,
            iconColor: theme.colorScheme.primary,
            value: '${streak.bestStreak}',
            label: 'Best ($streakUnit)',
          ),
        ),
        const SizedBox(width: 8),

        // Total Times Card
        Expanded(
          child: _StatCard(
            icon: Icons.check,
            iconColor: accentColor,
            value: '${streak.totalCompletions}',
            label: 'Total Times',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      color: theme.colorScheme.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
