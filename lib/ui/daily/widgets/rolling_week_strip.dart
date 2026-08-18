import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/haptics_helper.dart';

class RollingWeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, int> weekLogs;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onTodayClick;

  const RollingWeekStrip({
    super.key,
    required this.selectedDate,
    required this.weekLogs,
    required this.onDateSelected,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onTodayClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentSelected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isToday = currentSelected == today;

    final days = List.generate(7, (index) {
      final offset = index - 3; // -3 to +3
      final d = currentSelected.add(Duration(days: offset));
      return DateTime(d.year, d.month, d.day);
    });

    final monthFormatter = DateFormat('MMMM yyyy');

    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          children: [
            // Header Row: Steppers + Month/Year + Today button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.chevron_left,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        HapticsHelper.performLightHaptic();
                        onPreviousDay();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        monthFormatter.format(selectedDate),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        HapticsHelper.performLightHaptic();
                        onNextDay();
                      },
                    ),
                  ],
                ),
                if (!isToday)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                    icon: Icon(
                      Icons.today,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      'Today',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    onPressed: () {
                      HapticsHelper.performLightHaptic();
                      onTodayClick();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // 7-day strip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((date) {
                final isSelected = date == currentSelected;
                final isDayToday = date == today;
                final completedCount = weekLogs[date] ?? 0;

                return Expanded(
                  child: _DayStripItem(
                    date: date,
                    isSelected: isSelected,
                    isToday: isDayToday,
                    completedCount: completedCount,
                    onClick: () {
                      HapticsHelper.performLightHaptic();
                      onDateSelected(date);
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayStripItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final int completedCount;
  final VoidCallback onClick;

  const _DayStripItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.completedCount,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayName = DateFormat('E').format(date).substring(0, 3);
    final dayNum = date.day.toString();

    final Color backgroundColor;
    if (isSelected) {
      backgroundColor = theme.colorScheme.primary;
    } else if (isToday) {
      backgroundColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.4);
    } else {
      backgroundColor = Colors.transparent;
    }

    final Color contentColor;
    if (isSelected) {
      contentColor = theme.colorScheme.onPrimary;
    } else if (isToday) {
      contentColor = theme.colorScheme.primary;
    } else {
      contentColor = theme.colorScheme.onSurface;
    }

    final Color dayNameColor;
    if (isSelected) {
      dayNameColor = theme.colorScheme.onPrimary.withValues(alpha: 0.85);
    } else if (isToday) {
      dayNameColor = theme.colorScheme.primary;
    } else {
      dayNameColor = theme.colorScheme.onSurfaceVariant;
    }

    final Color dotColor;
    if (completedCount > 0 && isSelected) {
      dotColor = theme.colorScheme.onPrimary;
    } else if (completedCount > 0) {
      dotColor = theme.colorScheme.primary;
    } else {
      dotColor = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onClick,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: dayNameColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayNum,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                    color: contentColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
