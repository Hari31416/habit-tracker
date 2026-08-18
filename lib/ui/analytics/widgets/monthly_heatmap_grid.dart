import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/haptics_helper.dart';
import '../controllers/analytics_controller.dart';

class MonthlyHeatmapGrid extends StatefulWidget {
  final DateTime month;
  final Map<DateTime, HeatmapDayData> dayDataMap;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthlyHeatmapGrid({
    super.key,
    required this.month,
    required this.dayDataMap,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  State<MonthlyHeatmapGrid> createState() => _MonthlyHeatmapGridState();
}

class _MonthlyHeatmapGridState extends State<MonthlyHeatmapGrid> {
  void _showDayDetailDialog(BuildContext context, HeatmapDayData detail) {
    final theme = Theme.of(context);
    final dateStr =
        DateFormat('EEEE, MMM d, yyyy').format(detail.date);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            dateStr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Completion Rate: ${detail.ratePercent}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Completed Habits: ${detail.completedCount} of ${detail.scheduledCount}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final daysInMonth =
        DateTime(widget.month.year, widget.month.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(widget.month.year, widget.month.month, 1);
    // Sunday is 0 in Dart (weekday % 7: Monday is 1, Sunday is 7%7=0)
    final dayOfWeekOffset = firstDayOfMonth.weekday % 7;
    final totalCells =
        (((dayOfWeekOffset + daysInMonth + 6) ~/ 7) * 7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Navigation Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(widget.month),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_left),
                  tooltip: 'Previous Month',
                  iconSize: 20,
                  onPressed: () {
                    HapticsHelper.performLightHaptic();
                    widget.onPreviousMonth();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right),
                  tooltip: 'Next Month',
                  iconSize: 20,
                  onPressed: () {
                    HapticsHelper.performLightHaptic();
                    widget.onNextMonth();
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Heatmap Grid
        Column(
          children: List.generate(totalCells ~/ 7, (row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = (row * 7) + col;
                  final dayNumber = cellIndex - dayOfWeekOffset + 1;

                  if (dayNumber >= 1 && dayNumber <= daysInMonth) {
                    final date = DateTime(
                      widget.month.year,
                      widget.month.month,
                      dayNumber,
                    );
                    final dayData = widget.dayDataMap[date] ??
                        HeatmapDayData(
                          date: date,
                          completedCount: 0,
                          scheduledCount: 0,
                          ratePercent: 0,
                        );
                    final rate = dayData.ratePercent;

                    final Color cellColor;
                    if (rate == 100) {
                      cellColor = primary;
                    } else if (rate >= 50) {
                      cellColor = primary.withValues(alpha: 0.65);
                    } else if (rate > 0) {
                      cellColor = primary.withValues(alpha: 0.3);
                    } else {
                      cellColor = theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4);
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: InkWell(
                            onTap: () {
                              HapticsHelper.performLightHaptic();
                              _showDayDetailDialog(context, dayData);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '$dayNumber',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: rate >= 50
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: rate >= 50
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(2),
                        child: AspectRatio(aspectRatio: 1),
                      ),
                    );
                  }
                }),
              ),
            );
          }),
        ),

        const SizedBox(height: 14),

        // Heatmap Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            ...[
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              primary.withValues(alpha: 0.3),
              primary.withValues(alpha: 0.65),
              primary,
            ].map((color) {
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            const SizedBox(width: 6),
            Text(
              'More',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
