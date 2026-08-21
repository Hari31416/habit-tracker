import 'package:flutter/material.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_tier.dart';
import '../../common/haptics_helper.dart';

class ElasticGoalsCard extends StatelessWidget {
  final Habit habit;
  final HabitTier achievedTier;
  final double currentValue;
  final ValueChanged<HabitTier> onSelectTier;

  const ElasticGoalsCard({
    super.key,
    required this.habit,
    required this.achievedTier,
    required this.currentValue,
    required this.onSelectTier,
  });

  @override
  Widget build(BuildContext context) {
    if (!habit.hasElasticTiers) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final miniVal = habit.miniTargetValue ?? 1.0;
    final baseVal = habit.targetValue ?? 1.0;
    final eliteVal = habit.eliteTargetValue ?? (baseVal * 1.5);
    final unitStr = habit.unit != null && habit.unit!.isNotEmpty ? ' ${habit.unit}' : '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Elastic Goals & Bad-Day Mode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Completing a Mini target preserves streak continuity on difficult days.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),

            // Tier Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildTierCard(
                    theme: theme,
                    tier: HabitTier.mini,
                    title: 'Mini',
                    subtitle: 'Bad Day',
                    targetStr: '${_formatVal(miniVal)}$unitStr',
                    xpStr: '5 XP',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.local_fire_department,
                    isAchieved: achievedTier.isAtLeast(HabitTier.mini),
                    isSelected: achievedTier == HabitTier.mini,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTierCard(
                    theme: theme,
                    tier: HabitTier.base,
                    title: 'Base',
                    subtitle: 'Standard',
                    targetStr: '${_formatVal(baseVal)}$unitStr',
                    xpStr: '20 XP',
                    color: const Color(0xFF10B981),
                    icon: Icons.check_circle_outline,
                    isAchieved: achievedTier.isAtLeast(HabitTier.base),
                    isSelected: achievedTier == HabitTier.base,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTierCard(
                    theme: theme,
                    tier: HabitTier.elite,
                    title: 'Elite',
                    subtitle: 'High Energy',
                    targetStr: '${_formatVal(eliteVal)}$unitStr',
                    xpStr: '35 XP',
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.workspace_premium,
                    isAchieved: achievedTier == HabitTier.elite,
                    isSelected: achievedTier == HabitTier.elite,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required ThemeData theme,
    required HabitTier tier,
    required String title,
    required String subtitle,
    required String targetStr,
    required String xpStr,
    required Color color,
    required IconData icon,
    required bool isAchieved,
    required bool isSelected,
  }) {
    final bgColor = isSelected
        ? color.withValues(alpha: 0.18)
        : isAchieved
            ? color.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    final borderColor = isSelected
        ? color
        : isAchieved
            ? color.withValues(alpha: 0.5)
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.3);

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isSelected ? 2.0 : 1.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticsHelper.performLightHaptic();
          onSelectTier(tier);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isAchieved ? color : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isAchieved ? color : theme.colorScheme.onSurface,
                ),
              ),
              Text(
                targetStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  xpStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 10,
                  ),
                ),
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
