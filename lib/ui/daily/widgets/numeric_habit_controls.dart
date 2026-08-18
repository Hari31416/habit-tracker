import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/engines/dynamic_step_engine.dart';
import '../../../domain/models/habit.dart';
import '../../common/haptics_helper.dart';
import '../dialogs/direct_numeric_input_dialog.dart';

class NumericHabitControls extends StatelessWidget {
  final Habit habit;
  final double currentValue;
  final bool isCompleted;
  final Color accentColor;
  final ValueChanged<double> onValueChange;
  final ValueChanged<double> onDeltaAdd;

  const NumericHabitControls({
    super.key,
    required this.habit,
    required this.currentValue,
    required this.isCompleted,
    required this.accentColor,
    required this.onValueChange,
    required this.onDeltaAdd,
  });

  void _showDirectInputDialog(BuildContext context, double targetValue) {
    showDialog(
      context: context,
      builder: (dialogCtx) => DirectNumericInputDialog(
        habitTitle: habit.title,
        currentValue: currentValue,
        targetValue: targetValue,
        unit: habit.unit,
        onDismiss: () => Navigator.of(dialogCtx).pop(),
        onConfirm: (newValue) {
          Navigator.of(dialogCtx).pop();
          final previouslyMet = currentValue >= targetValue;
          onValueChange(newValue);
          if (!previouslyMet && newValue >= targetValue) {
            HapticsHelper.performHeavyConfirmationHaptic();
          } else {
            HapticsHelper.performLightHaptic();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetValue = habit.targetValue ?? 1.0;
    final unit = habit.unit ?? '';
    final stepConfig =
        DynamicStepEngine.getDynamicStepConfig(targetValue, habit.unit);

    final progress = (currentValue / targetValue).clamp(0.0, 1.0);

    final numberFormatter = NumberFormat.decimalPattern();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Row: Label + Edit Pencil
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  numberFormatter.format(currentValue),
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
                    ' / ${numberFormatter.format(targetValue)} $unit'.trimRight(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              iconSize: 16,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.edit,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Edit value',
              onPressed: () {
                HapticsHelper.performLightHaptic();
                _showDirectInputDialog(context, targetValue);
              },
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

        // Stepper & Quick Add Chips Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Minus / Plus Steppers
            Row(
              children: [
                // Minus primary step
                Material(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.7),
                  shape: CircleBorder(
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: currentValue > 0
                        ? () {
                            HapticsHelper.performLightHaptic();
                            onDeltaAdd(-stepConfig.primaryStep);
                          }
                        : null,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: currentValue > 0
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Plus primary step
                Material(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: CircleBorder(
                    side: BorderSide(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final newTotal = currentValue + stepConfig.primaryStep;
                      final wasMet = currentValue >= targetValue;
                      if (!wasMet && newTotal >= targetValue) {
                        HapticsHelper.performHeavyConfirmationHaptic();
                      } else {
                        HapticsHelper.performLightHaptic();
                      }
                      onDeltaAdd(stepConfig.primaryStep);
                    },
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Quick Add Chips
            Row(
              children: stepConfig.quickAddValues.map((quickVal) {
                final quickValFormatted = quickVal % 1.0 == 0.0
                    ? '+${quickVal.toInt()}'
                    : '+$quickVal';

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
                        final newTotal = currentValue + quickVal;
                        final wasMet = currentValue >= targetValue;
                        if (!wasMet && newTotal >= targetValue) {
                          HapticsHelper.performHeavyConfirmationHaptic();
                        } else {
                          HapticsHelper.performLightHaptic();
                        }
                        onDeltaAdd(quickVal);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          quickValFormatted,
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
