import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/color_utils.dart';
import '../common/habit_icon_registry.dart';
import '../form/habit_form_bottom_sheet.dart';
import '../navigation/habit_bottom_navigation.dart';
import '../navigation/screen.dart';
import 'controllers/analytics_controller.dart';
import 'widgets/adherence_area_chart.dart';
import 'widgets/monthly_heatmap_grid.dart';
import 'widgets/wellbeing_correlation_card.dart';

class HabitAnalyticsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToDaily;
  final VoidCallback? onNavigateToMatrix;
  final VoidCallback? onNavigateToBadges;
  final ValueChanged<String>? onNavigateToDetail;

  const HabitAnalyticsScreen({
    super.key,
    this.onNavigateToDaily,
    this.onNavigateToMatrix,
    this.onNavigateToBadges,
    this.onNavigateToDetail,
  });

  @override
  ConsumerState<HabitAnalyticsScreen> createState() =>
      _HabitAnalyticsScreenState();
}

class _HabitAnalyticsScreenState extends ConsumerState<HabitAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: HabitBottomNavigation(
        currentRoute: Screen.analytics,
        onNavigate: (route) {
          if (route == Screen.daily) {
            widget.onNavigateToDaily?.call();
          } else if (route == Screen.matrix) {
            widget.onNavigateToMatrix?.call();
          } else if (route == Screen.analytics) {
            // Already here
          } else if (route == Screen.badges) {
            widget.onNavigateToBadges?.call();
          }
        },
        onAddHabitClick: () {
          HabitFormBottomSheet.show(context);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Quick Timeframe Filter
            Material(
              color: theme.colorScheme.surface,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Analytics',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const _AnalyticsTopBarPill(),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: _AnalyticsContent(
                onNavigateToDetail: widget.onNavigateToDetail,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsTopBarPill extends ConsumerWidget {
  const _AnalyticsTopBarPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final completed = ref.watch(
      analyticsControllerProvider.select((s) => s.completedTodayCount),
    );
    final scheduled = ref.watch(
      analyticsControllerProvider.select((s) => s.scheduledTodayCount),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 15,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 5),
          Text(
            '$completed/$scheduled Today',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsContent extends ConsumerWidget {
  final ValueChanged<String>? onNavigateToDetail;

  const _AnalyticsContent({
    this.onNavigateToDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      analyticsControllerProvider.select((s) => s.isLoading),
    );

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Consistency Card
          const _HeroConsistencyCard(),

          const SizedBox(height: 14),

          // 2. Secondary Metrics Row
          const _SecondaryMetricsRow(),

          const SizedBox(height: 14),

          // 3. Top Habits Leaderboard
          _LeaderboardCard(
            onNavigateToDetail: onNavigateToDetail,
          ),

          // 4. Adherence Trend Section
          const _AdherenceTrendSection(),

          const SizedBox(height: 20),

          // 5. Wellbeing & Energy Correlation Section
          const _WellbeingCorrelationSection(),

          const SizedBox(height: 20),

          // 6. Monthly Activity Heatmap
          const _MonthlyHeatmapSection(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _HeroConsistencyCard extends ConsumerWidget {
  const _HeroConsistencyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final consistency30Days = ref.watch(
      analyticsControllerProvider.select((s) => s.consistency30Days),
    );
    final delta = ref.watch(
      analyticsControllerProvider.select((s) => s.consistencyDelta30Days),
    );

    final isPositiveOrZero = delta >= 0;
    final deltaColor =
        isPositiveOrZero ? theme.colorScheme.primary : theme.colorScheme.error;
    final deltaIcon = isPositiveOrZero
        ? Icons.trending_up
        : Icons.trending_down;
    final deltaText = isPositiveOrZero
        ? '+$delta% vs last 30 days'
        : '$delta% vs last 30 days';

    final consistencyFraction =
        (consistency30Days / 100.0).clamp(0.0, 1.0);

    return Semantics(
      identifier: 'analytics_consistency_card',
      label: 'Your Consistency $consistency30Days%',
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        color: theme.colorScheme.surface,
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Consistency',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$consistency30Days%',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(deltaIcon, size: 14, color: deltaColor),
                      const SizedBox(width: 4),
                      Text(
                        deltaText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: deltaColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Circular Progress Indicator Ring
            SizedBox(
              width: 80,
              height: 80,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: consistencyFraction),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return CustomPaint(
                      size: const Size(76, 76),
                      painter: _ConsistencyRingPainter(
                        progress: value,
                        trackColor: theme.colorScheme.surfaceContainerHighest,
                        progressColor: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SecondaryMetricsRow extends ConsumerWidget {
  const _SecondaryMetricsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bestStreak = ref.watch(
      analyticsControllerProvider.select((s) => s.bestStreakRecord),
    );
    final completedToday = ref.watch(
      analyticsControllerProvider.select((s) => s.completedTodayCount),
    );

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            icon: Icons.local_fire_department,
            iconTint: theme.colorScheme.tertiary,
            value: '$bestStreak',
            label: 'Best Streak',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: Icons.check,
            iconTint: theme.colorScheme.primary,
            value: '$completedToday',
            label: 'Completed',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: Icons.schedule,
            iconTint: theme.colorScheme.tertiary,
            value: '18h 25m',
            label: 'Focus Time',
          ),
        ),
      ],
    );
  }

  static Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required Color iconTint,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      color: theme.colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconTint.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Icon(icon, size: 16, color: iconTint),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardCard extends ConsumerWidget {
  final ValueChanged<String>? onNavigateToDetail;

  const _LeaderboardCard({
    this.onNavigateToDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leaderboard = ref.watch(
      analyticsControllerProvider.select((s) => s.leaderboard),
    );

    if (leaderboard.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Card(
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
                Text(
                  'Top Habits (30 Days)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...leaderboard.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final habitColor = ColorUtils.parseHexColor(item.habit.color);
                  final iconData = HabitIconRegistry.getIcon(item.habit.icon);
                  final progressFraction = item.bestStreak > 0
                      ? (item.currentStreak / item.bestStreak).clamp(0.1, 1.0)
                      : 0.5;

                  return InkWell(
                    onTap: () => onNavigateToDetail?.call(item.habit.id),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: Text(
                              '${index + 1}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: habitColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(iconData, size: 18, color: habitColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.habit.title,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${item.currentStreak} ${item.unitLabel}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progressFraction,
                                    minHeight: 4,
                                    color: habitColor,
                                    backgroundColor:
                                        theme.colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _AdherenceTrendSection extends ConsumerWidget {
  const _AdherenceTrendSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendPoints = ref.watch(
      analyticsControllerProvider.select((s) => s.trendDataPoints),
    );
    final trendRange = ref.watch(
      analyticsControllerProvider.select((s) => s.trendRange),
    );
    final controller = ref.read(analyticsControllerProvider.notifier);

    return AdherenceAreaChart(
      dataPoints: trendPoints,
      selectedRange: trendRange,
      onRangeSelected: controller.setTrendRange,
    );
  }
}

class _WellbeingCorrelationSection extends ConsumerWidget {
  const _WellbeingCorrelationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wellbeingSummary = ref.watch(
      analyticsControllerProvider.select((s) => s.wellbeingSummary),
    );

    return WellbeingCorrelationCard(
      summary: wellbeingSummary,
    );
  }
}

class _MonthlyHeatmapSection extends ConsumerWidget {
  const _MonthlyHeatmapSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapMonth = ref.watch(
      analyticsControllerProvider.select((s) => s.heatmapMonth),
    );
    final heatmapData = ref.watch(
      analyticsControllerProvider.select((s) => s.heatmapData),
    );
    final controller = ref.read(analyticsControllerProvider.notifier);

    return MonthlyHeatmapGrid(
      month: heatmapMonth,
      dayDataMap: heatmapData,
      onPreviousMonth: controller.previousHeatmapMonth,
      onNextMonth: controller.nextHeatmapMonth,
    );
  }
}

class _ConsistencyRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _ConsistencyRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweepAngle = progress * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConsistencyRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
