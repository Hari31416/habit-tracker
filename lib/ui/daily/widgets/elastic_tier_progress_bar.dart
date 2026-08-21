import 'package:flutter/material.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_tier.dart';
import '../../common/haptics_helper.dart';

class ElasticTierProgressBar extends StatelessWidget {
  final Habit habit;
  final double currentValue;
  final HabitTier achievedTier;
  final Color accentColor;
  final ValueChanged<HabitTier> onSelectTier;

  const ElasticTierProgressBar({
    super.key,
    required this.habit,
    required this.currentValue,
    required this.achievedTier,
    required this.accentColor,
    required this.onSelectTier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final miniVal = habit.miniTargetValue ?? 1.0;
    final baseVal = habit.targetValue ?? 1.0;
    final eliteVal = habit.eliteTargetValue ?? (baseVal * 1.5);
    final unitStr = habit.unit != null && habit.unit!.isNotEmpty ? ' ${habit.unit}' : '';

    final isMiniDone = achievedTier.isAtLeast(HabitTier.mini);
    final isBaseDone = achievedTier.isAtLeast(HabitTier.base);
    final isEliteDone = achievedTier == HabitTier.elite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Three-tier milestone bar
        Row(
          children: [
            Expanded(
              child: _buildTierSegment(
                theme: theme,
                title: 'Mini',
                targetStr: '${_formatVal(miniVal)}$unitStr',
                isAchieved: isMiniDone,
                color: const Color(0xFFF59E0B),
                icon: Icons.local_fire_department,
                onTap: () {
                  HapticsHelper.performLightHaptic();
                  onSelectTier(HabitTier.mini);
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildTierSegment(
                theme: theme,
                title: 'Base',
                targetStr: '${_formatVal(baseVal)}$unitStr',
                isAchieved: isBaseDone,
                color: const Color(0xFF10B981),
                icon: Icons.check_circle_outline,
                onTap: () {
                  HapticsHelper.performLightHaptic();
                  onSelectTier(HabitTier.base);
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildTierSegment(
                theme: theme,
                title: 'Elite',
                targetStr: '${_formatVal(eliteVal)}$unitStr',
                isAchieved: isEliteDone,
                color: const Color(0xFF8B5CF6),
                icon: Icons.workspace_premium,
                onTap: () {
                  HapticsHelper.performLightHaptic();
                  onSelectTier(HabitTier.elite);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTierSegment({
    required ThemeData theme,
    required String title,
    required String targetStr,
    required bool isAchieved,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bgColor = isAchieved
        ? color.withValues(alpha: 0.18)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final borderColor = isAchieved
        ? color.withValues(alpha: 0.7)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.3);
    final textColor = isAchieved ? color : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor, width: isAchieved ? 1.5 : 1.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: textColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                targetStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: isAchieved ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatVal(double v) {
    return v % 1.0 == 0.0 ? v.toInt().toString() : v.toString();
  }
}
