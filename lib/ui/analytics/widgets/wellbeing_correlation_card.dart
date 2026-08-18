import 'package:flutter/material.dart';
import '../../../domain/engines/wellbeing_correlation_engine.dart';
import '../../reflection/reflection_bottom_sheet.dart';

class WellbeingCorrelationCard extends StatelessWidget {
  final WellbeingSummary summary;

  const WellbeingCorrelationCard({
    super.key,
    required this.summary,
  });

  IconData _getMoodIcon(String moodKey) {
    final match = kDefaultMoodOptions.where((m) => m.key == moodKey).firstOrNull;
    return match?.icon ?? Icons.sentiment_satisfied;
  }

  String _getMoodLabel(String moodKey) {
    final match = kDefaultMoodOptions.where((m) => m.key == moodKey).firstOrNull;
    return match?.label ?? moodKey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = summary.totalReflectionsLogged > 0 ||
        summary.avgEnergyOnCompletedDays > 0;

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
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bolt,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wellbeing & Energy Correlation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Impact of habit consistency on self-reported energy',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!hasData) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                      Icons.insights,
                      size: 36,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No energy ratings recorded yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete habits and log energy ratings to see wellbeing correlation insights',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Comparison Metric Row: Completed vs Missed Days
              Row(
                children: [
                  Expanded(
                    child: _buildEnergyMetric(
                      context,
                      title: 'On Completed Days',
                      energyScore: summary.avgEnergyOnCompletedDays,
                      color: theme.colorScheme.primary,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildEnergyMetric(
                      context,
                      title: 'On Missed Days',
                      energyScore: summary.avgEnergyOnMissedDays,
                      color: theme.colorScheme.onSurfaceVariant,
                      icon: Icons.cancel_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Boost Summary Banner
              if (summary.energyBoostPercentage > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '+${summary.energyBoostPercentage}% higher energy reported on habit completion days',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 7-day or recent timeline energy bars
              Text(
                'Recent Energy & Completion Trends',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildTimelineChart(context, summary.timelinePoints.take(7).toList().reversed.toList()),

              // Mood Breakdown
              if (summary.moodCounts.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Top Recorded Moods',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: summary.moodCounts.entries.map((entry) {
                    final moodKey = entry.key;
                    final count = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getMoodIcon(moodKey), size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${_getMoodLabel(moodKey)} ($count)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyMetric(
    BuildContext context, {
    required String title,
    required double energyScore,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final displayScore = energyScore > 0 ? energyScore.toStringAsFixed(1) : '-';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                displayScore,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (energyScore > 0) ...[
                const SizedBox(width: 2),
                Text(
                  ' / 5',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineChart(BuildContext context, List<WellbeingDayDataPoint> points) {
    final theme = Theme.of(context);
    if (points.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((p) {
        final energy = p.energyLevel ?? 0;
        final heightFraction = energy > 0 ? (energy / 5.0).clamp(0.15, 1.0) : 0.08;
        final barHeight = 44.0 * heightFraction;
        final dayLabel = _formatDayOfWeek(p.date);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Energy label above bar
                Text(
                  energy > 0 ? '$energy' : '-',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: p.habitCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),

                // Bar
                Container(
                  height: barHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: energy > 0
                        ? (p.habitCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),

                // Completion status icon / dot
                Icon(
                  p.habitCompleted ? Icons.check_circle : Icons.circle_outlined,
                  size: 10,
                  color: p.habitCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
                const SizedBox(height: 2),

                // Day Label
                Text(
                  dayLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDayOfWeek(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}
