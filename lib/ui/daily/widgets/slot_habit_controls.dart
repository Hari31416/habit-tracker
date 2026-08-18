import 'package:flutter/material.dart';
import '../../../domain/engines/subday_slot_engine.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_log.dart';
import '../../common/haptics_helper.dart';

class SlotHabitControls extends StatelessWidget {
  final Habit habit;
  final List<HabitLog> logsForDate;
  final Color accentColor;
  final ValueChanged<int> onToggleSlot;

  const SlotHabitControls({
    super.key,
    required this.habit,
    required this.logsForDate,
    required this.accentColor,
    required this.onToggleSlot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slots = SubdaySlotEngine.generateSlots(habit, logsForDate);
    final completedCount = slots.where((s) => s.completed).length;
    final totalSlots = slots.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: slots.map((slot) {
          final isDone = slot.completed;
          final backgroundColor = isDone
              ? accentColor
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5);
          final contentColor =
              isDone ? Colors.white : theme.colorScheme.onSurfaceVariant;
          final borderSide = isDone
              ? BorderSide.none
              : BorderSide(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.7),
                );

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: borderSide,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final willCompleteAll =
                      !isDone && (completedCount + 1 >= totalSlots);
                  if (willCompleteAll) {
                    HapticsHelper.performHeavyConfirmationHaptic();
                  } else {
                    HapticsHelper.performLightHaptic();
                  }
                  onToggleSlot(slot.index);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDone) ...[
                        const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        slot.timeLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight:
                              isDone ? FontWeight.bold : FontWeight.w500,
                          color: contentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
