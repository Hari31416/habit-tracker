import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../../domain/models/habit_target_type.dart';
import '../../common/haptics_helper.dart';
import '../../common/previews/phial_previews.dart';
import '../../common/previews/preview_fixtures.dart';

class TenDotProgressBar extends StatelessWidget {
  final Habit habit;
  final double currentValue;
  final Color accentColor;
  final ValueChanged<double>? onDotClick;

  const TenDotProgressBar({
    super.key,
    required this.habit,
    required this.currentValue,
    required this.accentColor,
    this.onDotClick,
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
                  onTap: onDotClick != null
                      ? () {
                          if (dotIndex == 10 || targetForDot >= targetValue) {
                            HapticsHelper.performHeavyConfirmationHaptic();
                          } else {
                            HapticsHelper.performLightHaptic();
                          }
                          onDotClick!(targetForDot);
                        }
                      : null,
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

// ==========================================
// Widget Previews
// ==========================================

@PhialMultiBrightnessPreview(name: '10-Dot Progress - Half Complete', group: 'Detail')
Widget previewTenDotProgressBarHalf() {
  return PhialPreviewWrapper(
    child: TenDotProgressBar(
      habit: PreviewFixtures.sampleHabit(
        targetType: HabitTargetType.numeric,
        targetValue: 10.0,
      ),
      currentValue: 5.0,
      accentColor: const Color(0xFF3B82F6),
      onDotClick: (_) {},
    ),
  );
}

@Preview(name: '10-Dot Progress - Fully Complete', group: 'Detail')
Widget previewTenDotProgressBarFull() {
  return PhialPreviewWrapper(
    child: TenDotProgressBar(
      habit: PreviewFixtures.sampleHabit(
        targetType: HabitTargetType.numeric,
        targetValue: 2000.0,
      ),
      currentValue: 2000.0,
      accentColor: const Color(0xFF10B981),
      onDotClick: (_) {},
    ),
  );
}

@Preview(name: '10-Dot Progress - Empty', group: 'Detail')
Widget previewTenDotProgressBarEmpty() {
  return PhialPreviewWrapper(
    child: TenDotProgressBar(
      habit: PreviewFixtures.sampleHabit(
        targetType: HabitTargetType.numeric,
        targetValue: 50.0,
      ),
      currentValue: 0.0,
      accentColor: const Color(0xFFF59E0B),
      onDotClick: (_) {},
    ),
  );
}
