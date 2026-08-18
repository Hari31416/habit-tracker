import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/engines/streak_calculator.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_log.dart';
import '../../../domain/models/habit_shield.dart';
import '../../../domain/models/habit_target_type.dart';
import '../../common/haptics_helper.dart';

class MonthlyStats {
  final int completionRate;
  final int completedCount;
  final int scheduledCount;
  final int bestStreakInMonth;
  final int shieldedCount;
  final double totalLoggedValue;

  const MonthlyStats({
    required this.completionRate,
    required this.completedCount,
    required this.scheduledCount,
    required this.bestStreakInMonth,
    this.shieldedCount = 0,
    required this.totalLoggedValue,
  });
}

class HabitMonthlyCalendar extends StatelessWidget {
  final Habit habit;
  final List<HabitLog> logs;
  final List<HabitShield> shields;
  final DateTime currentMonth;
  final DateTime? selectedDate;
  final Color accentColor;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateClick;

  const HabitMonthlyCalendar({
    super.key,
    required this.habit,
    required this.logs,
    this.shields = const [],
    required this.currentMonth,
    required this.selectedDate,
    required this.accentColor,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('yyyy-MM-dd');

    // Group logs by date string
    final logsByDate = <String, List<HabitLog>>{};
    for (final log in logs) {
      logsByDate.putIfAbsent(log.date, () => []).add(log);
    }

    final shieldedDates = {for (final s in shields) s.date};

    final year = currentMonth.year;
    final month = currentMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayOfMonth = DateTime(year, month, 1);
    // 0 = Sunday, 1 = Monday ... 6 = Saturday (weekday is 1=Mon..7=Sun in Dart)
    final dayOfWeekOffset = firstDayOfMonth.weekday % 7;

    // Calculate Monthly Stats
    var scheduledDays = 0;
    var completedDays = 0;
    var shieldedDays = 0;
    var currentStreakMonth = 0;
    var bestStreakMonth = 0;
    var totalValue = 0.0;

    for (var day = 1; day <= daysInMonth; day++) {
      final d = DateTime(year, month, day);
      final dateStr = formatter.format(d);
      final isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, d);
      final dayLogs = logsByDate[dateStr] ?? const [];
      final isCompleted = StreakCalculator.isHabitCompletedOnDate(habit, dayLogs);
      final isShielded = shieldedDates.contains(dateStr);

      if (isScheduled) {
        scheduledDays++;
        if (isCompleted) {
          completedDays++;
          currentStreakMonth++;
          if (currentStreakMonth > bestStreakMonth) {
            bestStreakMonth = currentStreakMonth;
          }
        } else if (isShielded) {
          shieldedDays++;
          // Streak chain is preserved across shielded days
          if (currentStreakMonth > bestStreakMonth) {
            bestStreakMonth = currentStreakMonth;
          }
        } else {
          currentStreakMonth = 0;
        }
      }

      totalValue += dayLogs.fold<double>(
        0.0,
        (sum, log) =>
            sum +
            (log.value ??
                (log.completed ? (habit.targetValue ?? 1.0) : 0.0)),
      );
    }

    final completionRate = scheduledDays > 0
        ? ((completedDays / scheduledDays) * 100).round()
        : 0;

    final monthlyStats = MonthlyStats(
      completionRate: completionRate,
      completedCount: completedDays,
      scheduledCount: scheduledDays,
      bestStreakInMonth: bestStreakMonth,
      shieldedCount: shieldedDays,
      totalLoggedValue: totalValue,
    );

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final totalCells = ((dayOfWeekOffset + daysInMonth + 6) ~/ 7) * 7;
    final totalRows = totalCells ~/ 7;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: theme.colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Month Name and Steppers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(currentMonth),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      iconSize: 22,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.chevron_left,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        HapticsHelper.performLightHaptic();
                        onPreviousMonth();
                      },
                    ),
                    IconButton(
                      iconSize: 22,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        HapticsHelper.performLightHaptic();
                        onNextMonth();
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Days of Week Header
            Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((header) {
                return Expanded(
                  child: Center(
                    child: Text(
                      header,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            // Calendar Days Grid
            Column(
              children: List.generate(totalRows, (row) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: List.generate(7, (col) {
                      final cellIndex = (row * 7) + col;
                      final dayNumber = cellIndex - dayOfWeekOffset + 1;

                      if (dayNumber >= 1 && dayNumber <= daysInMonth) {
                        final cellDate = DateTime(year, month, dayNumber);
                        final dateStr = formatter.format(cellDate);
                        final isScheduled =
                            StreakCalculator.isHabitScheduledOnDate(
                                habit, cellDate);
                        final dayLogs =
                            logsByDate[dateStr] ?? const [];
                        final isCompleted =
                            StreakCalculator.isHabitCompletedOnDate(
                                habit, dayLogs);
                        final isShielded = shieldedDates.contains(dateStr);

                        final isSelected = selectedDate != null &&
                            selectedDate!.year == cellDate.year &&
                            selectedDate!.month == cellDate.month &&
                            selectedDate!.day == cellDate.day;

                        final isPast = cellDate.isBefore(todayStart);

                        return Expanded(
                          child: _CalendarDayCell(
                            dayNumber: dayNumber,
                            isCompleted: isCompleted,
                            isShielded: isShielded,
                            isScheduled: isScheduled,
                            isSelected: isSelected,
                            isPast: isPast,
                            accentColor: accentColor,
                            onClick: () {
                              HapticsHelper.performLightHaptic();
                              onDateClick(cellDate);
                            },
                          ),
                        );
                      } else {
                        return const Expanded(child: SizedBox.shrink());
                      }
                    }),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Monthly Summary Metrics Strip
            Material(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricItem(
                      label: 'Rate',
                      value: '${monthlyStats.completionRate}%',
                      valueColor: accentColor,
                    ),
                    _MetricItem(
                      label: 'Completed',
                      value:
                          '${monthlyStats.completedCount}/${monthlyStats.scheduledCount}d',
                    ),
                    _MetricItem(
                      label: 'Best Streak',
                      value: '${monthlyStats.bestStreakInMonth}d',
                    ),
                    if (monthlyStats.shieldedCount > 0)
                      _MetricItem(
                        label: 'Protected',
                        value: '${monthlyStats.shieldedCount} 🛡️',
                        valueColor: theme.colorScheme.primary,
                      )
                    else
                      _MetricItem(
                        label: 'Total',
                        value:
                            '${monthlyStats.totalLoggedValue.round()} ${habit.unit ?? (habit.targetType == HabitTargetType.timer ? "m" : "")}'
                                .trim(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int dayNumber;
  final bool isCompleted;
  final bool isShielded;
  final bool isScheduled;
  final bool isSelected;
  final bool isPast;
  final Color accentColor;
  final VoidCallback onClick;

  const _CalendarDayCell({
    required this.dayNumber,
    required this.isCompleted,
    this.isShielded = false,
    required this.isScheduled,
    required this.isSelected,
    required this.isPast,
    required this.accentColor,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor = switch (isCompleted) {
      true => accentColor,
      false => isShielded
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.85)
          : isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
    };

    final textColor = switch (isCompleted) {
      true => Colors.white,
      false => isShielded
          ? theme.colorScheme.onPrimaryContainer
          : !isScheduled
              ? theme.colorScheme.outlineVariant
              : isSelected
                  ? theme.colorScheme.primary
                  : isPast
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
    };

    final Border? border = switch (isSelected) {
      true => Border.all(color: theme.colorScheme.primary, width: 2),
      false => isShielded
          ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.6), width: 1.5)
          : (isScheduled && !isCompleted && isPast)
              ? Border.all(color: theme.colorScheme.outlineVariant, width: 1)
              : null,
    };

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: backgroundColor,
          shape: CircleBorder(
            side: border != null
                ? BorderSide(
                    color: border.top.color,
                    width: border.top.width,
                  )
                : BorderSide.none,
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onClick,
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : isShielded
                      ? Icon(
                          Icons.shield,
                          color: theme.colorScheme.primary,
                          size: 15,
                        )
                      : Text(
                          '$dayNumber',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: (isSelected || isCompleted || isShielded)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
