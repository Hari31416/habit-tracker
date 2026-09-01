import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../common/color_utils.dart';
import '../../common/habit_icon_registry.dart';
import '../../common/haptics_helper.dart';
import '../controllers/week_matrix_controller.dart';

class WeekMatrixGrid extends StatelessWidget {
  final List<MatrixRow> rows;
  final void Function(String habitId, DateTime date) onToggleCell;
  final void Function(String habitId, DateTime date)? onToggleShieldCell;
  final ValueChanged<String> onHabitClick;

  const WeekMatrixGrid({
    super.key,
    required this.rows,
    required this.onToggleCell,
    this.onToggleShieldCell,
    required this.onHabitClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (rows.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        color: theme.colorScheme.surface,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No active habits for this week',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final firstRowCells = rows.first.cells;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      color: theme.colorScheme.surface,
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header Row: Habit Column + 7 Day Columns (Mo 17, Tu 18, etc.)
            Row(
              children: [
                Expanded(
                  flex: 17,
                  child: Text(
                    'Habits',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 23,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: firstRowCells.map((cell) {
                      final dayName = DateFormat('EEE')
                          .format(cell.date)
                          .substring(0, 2);
                      final dayNum = cell.date.day.toString();

                      return SizedBox(
                        width: 24,
                        child: Column(
                          children: [
                            Text(
                              dayName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: cell.isToday
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: cell.isToday
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              dayNum,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: cell.isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: cell.isToday
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Habit Rows
            ...rows.map((row) {
              return _MatrixRowWidget(
                key: ValueKey(row.habit.id),
                row: row,
                onHabitClick: onHabitClick,
                onToggleCell: onToggleCell,
                onToggleShieldCell: onToggleShieldCell,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MatrixRowWidget extends StatelessWidget {
  final MatrixRow row;
  final ValueChanged<String> onHabitClick;
  final void Function(String habitId, DateTime date) onToggleCell;
  final void Function(String habitId, DateTime date)? onToggleShieldCell;

  const _MatrixRowWidget({
    super.key,
    required this.row,
    required this.onHabitClick,
    required this.onToggleCell,
    this.onToggleShieldCell,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = row.habit;
    final accentColor = ColorUtils.parseHexColor(habit.color);
    final iconData = HabitIconRegistry.getIcon(habit.icon);

    final String freqBadge;
    switch (habit.frequencyType) {
      case HabitFrequencyType.daily:
        freqBadge = 'Daily';
        break;
      case HabitFrequencyType.weekly:
        freqBadge = '${habit.targetCountPerWeek ?? 1}x/wk';
        break;
      case HabitFrequencyType.customDays:
        freqBadge = 'Custom';
        break;
      case HabitFrequencyType.subdayInterval:
        freqBadge = 'Interval';
        break;
      case HabitFrequencyType.timesPerDay:
        freqBadge = 'Subday';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Left Habit Info: Compact Icon + Title
          Expanded(
            flex: 17,
            child: InkWell(
              onTap: () => onHabitClick(habit.id),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          size: 15,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${row.completedCountThisWeek}/${row.targetCountThisWeek}${row.shieldedCountThisWeek > 0 ? " • ${row.shieldedCountThisWeek}🛡️" : ""} • $freqBadge',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 7 Day Cells (Compact tappable circles)
          Expanded(
            flex: 23,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.cells.map((cell) {
                return _MatrixCellWidget(
                  key: ValueKey('${habit.id}_${cell.date.toIso8601String()}'),
                  cell: cell,
                  accentColor: accentColor,
                  onTap: () {
                    if (habit.isNegative) return;
                    final isDone = cell.status == MatrixCellStatus.completed;
                    final isShielded = cell.status == MatrixCellStatus.shielded;
                    if (!isDone && !isShielded) {
                      HapticsHelper.performHeavyConfirmationHaptic();
                    } else {
                      HapticsHelper.performLightHaptic();
                    }
                    onToggleCell(habit.id, cell.date);
                  },
                  onLongPress: () {
                    if (habit.isNegative) return;
                    HapticsHelper.performLightHaptic();
                    onToggleShieldCell?.call(habit.id, cell.date);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixCellWidget extends StatelessWidget {
  final MatrixCell cell;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MatrixCellWidget({
    super.key,
    required this.cell,
    required this.accentColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = cell.status == MatrixCellStatus.completed;
    final isShielded = cell.status == MatrixCellStatus.shielded;
    final isScheduled = cell.status == MatrixCellStatus.scheduledIncomplete;

    final Color cellColor;
    if (isDone) {
      cellColor = accentColor;
    } else if (isShielded) {
      cellColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.85);
    } else if (cell.isToday) {
      cellColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.4);
    } else {
      cellColor = Colors.transparent;
    }

    final Border? border;
    if (isShielded) {
      border = Border.all(
        color: theme.colorScheme.primary.withValues(alpha: 0.7),
        width: 1.2,
      );
    } else if (cell.isToday && !isDone) {
      border = Border.all(
        color: theme.colorScheme.primary,
        width: 1.5,
      );
    } else if (isScheduled) {
      border = Border.all(
        color: theme.colorScheme.outlineVariant,
        width: 1,
      );
    } else {
      border = null;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cellColor,
          border: border,
        ),
        child: Center(
          child: isDone
              ? const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                )
              : isShielded
                  ? Icon(
                      Icons.shield,
                      size: 13,
                      color: theme.colorScheme.primary,
                    )
                  : (!isScheduled &&
                          cell.status == MatrixCellStatus.notScheduled)
                      ? Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.6),
                          ),
                        )
                      : null,
        ),
      ),
    );
  }
}

