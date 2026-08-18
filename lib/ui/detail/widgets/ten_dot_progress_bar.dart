import 'dart:math';
import 'package:flutter/material.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../../domain/models/habit_target_type.dart';
import '../../common/haptics_helper.dart';

class TenDotProgressBar extends StatelessWidget {
  final Habit habit;
  final double currentValue;
  final Color accentColor;
  final ValueChanged<double> onDotClick;

  const TenDotProgressBar({
    super.key,
    required this.habit,
    required this.currentValue,
    required this.accentColor,
    required this.onDotClick,
  });

  @override
  Widget build(BuildContext context) {
    // Show strictly for NUMERIC and TIMER, and not for subday/times-per-day slot models
    if (habit.targetType == HabitTargetType.boolean ||
        habit.frequencyType == HabitFrequencyType.subdayInterval ||
        habit.frequencyType == HabitFrequencyType.timesPerDay) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final targetValue = habit.targetValue ?? 1.0;
    final fillCount =
        min(10, ((currentValue / targetValue) * 10).floor()).clamp(0, 10);

    final percent = min(100, ((currentValue / targetValue) * 100).toInt());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10-Dot Progress',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (index) {
              final dotIndex = index + 1;
              final isFilled = dotIndex <= fillCount;
              final targetForDot = (dotIndex / 10.0 * targetValue).ceilToDouble();

              return Material(
                color: isFilled
                    ? accentColor
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                shape: CircleBorder(
                  side: isFilled
                      ? BorderSide.none
                      : BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: 1,
                        ),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    if (dotIndex == 10 || targetForDot >= targetValue) {
                      HapticsHelper.performHeavyConfirmationHaptic();
                    } else {
                      HapticsHelper.performLightHaptic();
                    }
                    onDotClick(targetForDot);
                  },
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: Center(
                      child: Text(
                        '$dotIndex',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isFilled
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
