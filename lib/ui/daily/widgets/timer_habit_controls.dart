import 'package:flutter/material.dart';
import '../../../domain/engines/dynamic_step_engine.dart';
import '../../../domain/models/habit.dart';
import '../../common/haptics_helper.dart';

class TimerHabitControls extends StatelessWidget {
  final Habit habit;
  final double currentMinutes;
  final bool isCompleted;
  final Color accentColor;
  final ValueChanged<double> onDeltaAddMinutes;
  final VoidCallback onStartFocus;

  const TimerHabitControls({
    super.key,
    required this.habit,
    required this.currentMinutes,
    required this.isCompleted,
    required this.accentColor,
    required this.onDeltaAddMinutes,
    required this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetMinutes = habit.targetValue ?? 25.0;
    final timerConfig = DynamicStepEngine.getDynamicTimerConfig(targetMinutes);

    final progress = (currentMinutes / targetMinutes).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '${currentMinutes.round()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? accentColor
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    ' / ${targetMinutes.round()} mins',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Actions Row: Start Focus button + Quick-add +X min chips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Start Focus Button
            Material(
              color: accentColor.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: accentColor.withValues(alpha: 0.4),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticsHelper.performLightHaptic();
                  onStartFocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Focus',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quick Add Minutes Chips
            Row(
              children: timerConfig.quickAddValues.map((quickMin) {
                final label = '+${quickMin.toInt()}m';

                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Material(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        final newTotal = currentMinutes + quickMin;
                        final wasMet = currentMinutes >= targetMinutes;
                        if (!wasMet && newTotal >= targetMinutes) {
                          HapticsHelper.performHeavyConfirmationHaptic();
                        } else {
                          HapticsHelper.performLightHaptic();
                        }
                        onDeltaAddMinutes(quickMin);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }
}
