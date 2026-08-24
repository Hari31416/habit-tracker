import 'package:flutter/material.dart';
import '../../../domain/engines/streak_calculator.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_log.dart';
import '../../../domain/models/habit_routine.dart';
import '../../common/color_utils.dart';
import '../../common/habit_icon_registry.dart';
import '../../common/haptics_helper.dart';

class RoutineChainCard extends StatelessWidget {
  final HabitRoutine routine;
  final List<Habit> allHabits;
  final List<HabitLog> todayLogs;
  final ValueChanged<HabitRoutine> onStartRoutine;
  final ValueChanged<HabitRoutine>? onEditRoutine;
  final ValueChanged<HabitRoutine>? onDeleteRoutine;

  const RoutineChainCard({
    super.key,
    required this.routine,
    required this.allHabits,
    required this.todayLogs,
    required this.onStartRoutine,
    this.onEditRoutine,
    this.onDeleteRoutine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routineColor = ColorUtils.fromHex(routine.color);

    // Map ordered habits in the routine chain
    final habitMap = {for (final h in allHabits) h.id: h};
    final chainHabits = routine.habitIds
        .map((id) => habitMap[id])
        .whereType<Habit>()
        .toList();

    // Calculate completions for today
    final logsByHabit = <String, List<HabitLog>>{};
    for (final log in todayLogs) {
      logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
    }

    var completedCount = 0;
    final stepStatus = <String, bool>{};
    for (final habit in chainHabits) {
      final logs = logsByHabit[habit.id] ?? const [];
      final isDone = StreakCalculator.isHabitCompletedOnDate(habit, logs);
      stepStatus[habit.id] = isDone;
      if (isDone) completedCount++;
    }

    final totalCount = chainHabits.length;
    final allCompleted = totalCount > 0 && completedCount == totalCount;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: allCompleted
              ? routineColor.withValues(alpha: 0.6)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: allCompleted ? 1.5 : 1.0,
        ),
      ),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Routine Icon + Title + Time Window + Overflow
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: routineColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    HabitIconRegistry.getIcon(routine.icon ?? 'link'),
                    color: routineColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (routine.targetTimeWindow != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${routine.targetTimeWindow!.startTime} - ${routine.targetTimeWindow!.endTime}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Bonus XP Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '+${routine.bonusXp} XP',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEditRoutine != null || onDeleteRoutine != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (val) {
                      if (val == 'edit' && onEditRoutine != null) {
                        onEditRoutine!(routine);
                      } else if (val == 'delete' && onDeleteRoutine != null) {
                        onDeleteRoutine!(routine);
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (onEditRoutine != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Stack'),
                            ],
                          ),
                        ),
                      if (onDeleteRoutine != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Stack', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),

            if (routine.description != null && routine.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                routine.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            // Sequential Habit Chain ("After A -> do B -> do C")
            if (chainHabits.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (int i = 0; i < chainHabits.length; i++) ...[
                    _buildHabitStepChip(
                      context: context,
                      stepNumber: i + 1,
                      habit: chainHabits[i],
                      isCompleted: stepStatus[chainHabits[i].id] ?? false,
                    ),
                    if (i < chainHabits.length - 1)
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Bottom Progress & Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Completion status
                Row(
                  children: [
                    Icon(
                      allCompleted
                          ? Icons.check_circle_rounded
                          : Icons.pending_actions_rounded,
                      size: 16,
                      color: allCompleted
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      allCompleted
                          ? 'Stack Complete!'
                          : '$completedCount of $totalCount Done',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: allCompleted
                            ? Colors.green
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // Play / Routine Player Button
                Semantics(
                  identifier: 'btn_start_routine_${routine.id}',
                  button: true,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: routineColor.withValues(alpha: 0.15),
                      foregroundColor: routineColor,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      HapticsHelper.selectionClick();
                      onStartRoutine(routine);
                    },
                    icon: Icon(
                      allCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
                      size: 18,
                    ),
                    label: Text(
                      allCompleted ? 'Replay' : (completedCount > 0 ? 'Resume' : 'Start Routine'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitStepChip({
    required BuildContext context,
    required int stepNumber,
    required Habit habit,
    required bool isCompleted,
  }) {
    final theme = Theme.of(context);
    final habitColor = ColorUtils.fromHex(habit.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : habitColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : Text(
                      '$stepNumber',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            habit.title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w600,
              color: isCompleted
                  ? Colors.green.shade800
                  : theme.colorScheme.onSurface,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
