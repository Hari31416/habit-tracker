import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_log.dart';
import '../../common/haptics_helper.dart';
import '../../reflection/reflection_bottom_sheet.dart';

class ReflectionHistoryTimeline extends StatelessWidget {
  final Habit habit;
  final List<HabitLog> logs;
  final DateTime selectedDate;
  final Color accentColor;
  final VoidCallback? onReflectionUpdated;

  const ReflectionHistoryTimeline({
    super.key,
    required this.habit,
    required this.logs,
    required this.selectedDate,
    required this.accentColor,
    this.onReflectionUpdated,
  });

  IconData _getMoodIcon(String? moodKey) {
    final match = kDefaultMoodOptions.where((m) => m.key == moodKey).firstOrNull;
    return match?.icon ?? Icons.sentiment_satisfied;
  }

  String _getMoodLabel(String? moodKey) {
    final match = kDefaultMoodOptions.where((m) => m.key == moodKey).firstOrNull;
    return match?.label ?? moodKey ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Filter logs that have either a note, energyLevel, mood, or are completed
    final logsWithContent = logs.where((l) {
      return (l.energyLevel != null && l.energyLevel! > 0) ||
          (l.mood != null && l.mood!.trim().isNotEmpty) ||
          (l.note != null && l.note!.trim().isNotEmpty);
    }).toList();

    // Group logs by date to avoid duplicates if multiple slots exist
    final Map<String, HabitLog> reflectionsByDate = {};
    for (final l in logsWithContent) {
      reflectionsByDate.putIfAbsent(l.date, () => l);
    }

    final reflectionList = reflectionsByDate.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final selectedDateLog = logs.where((l) => l.date == selectedDateStr).firstOrNull;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      color: theme.colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_edu,
                      size: 20,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reflections & Mood Timeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Reflect'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: accentColor,
                  ),
                  onPressed: () {
                    HapticsHelper.performLightHaptic();
                    ReflectionBottomSheet.show(
                      context,
                      habit: habit,
                      date: selectedDate,
                      initialEnergyLevel: selectedDateLog?.energyLevel,
                      initialMood: selectedDateLog?.mood,
                      initialNote: selectedDateLog?.note,
                      onSaved: (_) => onReflectionUpdated?.call(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (reflectionList.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 36,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No reflections logged yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rate energy and mood on completion to see your timeline',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reflectionList.length.clamp(0, 10),
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
                itemBuilder: (context, index) {
                  final log = reflectionList[index];
                  DateTime parsedDate;
                  try {
                    parsedDate = DateTime.parse(log.date);
                  } catch (_) {
                    parsedDate = selectedDate;
                  }
                  final formattedDate = DateFormat('MMM d, yyyy').format(parsedDate);
                  final isSelectedDay = log.date == selectedDateStr;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      HapticsHelper.performLightHaptic();
                      ReflectionBottomSheet.show(
                        context,
                        habit: habit,
                        date: parsedDate,
                        initialEnergyLevel: log.energyLevel,
                        initialMood: log.mood,
                        initialNote: log.note,
                        onSaved: (_) => onReflectionUpdated?.call(),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left indicator dot / energy level badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: log.energyLevel != null
                                  ? accentColor.withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelectedDay
                                    ? accentColor
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  size: 14,
                                  color: log.energyLevel != null
                                      ? accentColor
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  log.energyLevel != null ? '${log.energyLevel}/5' : '-',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: log.energyLevel != null
                                        ? accentColor
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Middle: Date, Mood & Micro-note
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      formattedDate,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (log.mood != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primaryContainer
                                              .withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getMoodIcon(log.mood),
                                              size: 12,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              _getMoodLabel(log.mood),
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (log.note != null && log.note!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    log.note!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Edit Icon
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
