import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/preferences/theme_preferences.dart';
import '../common/color_utils.dart';
import '../common/habit_icon_registry.dart';
import '../common/theme_toggle_button.dart';
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
    final uiState = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);

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
            // Top App Bar
            Material(
              color: theme.colorScheme.surface,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
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
                    ThemeToggleButton(
                      currentTheme: themeMode,
                      onThemeSelected: (mode) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(mode);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: uiState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Hero Consistency Card
                          _buildHeroConsistencyCard(context, uiState),

                          const SizedBox(height: 14),

                          // 2. Secondary Metrics Row
                          _buildSecondaryMetricsRow(context, uiState),

                          const SizedBox(height: 14),

                          // 3. Top Habits Leaderboard
                          if (uiState.leaderboard.isNotEmpty) ...[
                            _buildLeaderboardCard(context, uiState.leaderboard),
                            const SizedBox(height: 14),
                          ],

                          // 4. Adherence Trend Section
                          AdherenceAreaChart(
                            dataPoints: uiState.trendDataPoints,
                            selectedRange: uiState.trendRange,
                            onRangeSelected: controller.setTrendRange,
                          ),

                          const SizedBox(height: 20),

                          // 5. Wellbeing & Energy Correlation Section
                          WellbeingCorrelationCard(
                            summary: uiState.wellbeingSummary,
                          ),

                          const SizedBox(height: 20),

                          // 6. Monthly Activity Heatmap
                          MonthlyHeatmapGrid(
                            month: uiState.heatmapMonth,
                            dayDataMap: uiState.heatmapData,
                            onPreviousMonth: controller.previousHeatmapMonth,
                            onNextMonth: controller.nextHeatmapMonth,
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroConsistencyCard(
    BuildContext context,
    AnalyticsUiState uiState,
  ) {
    final theme = Theme.of(context);
    final delta = uiState.consistencyDelta30Days;
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
        (uiState.consistency30Days / 100.0).clamp(0.0, 1.0);

    return Card(
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
                    '${uiState.consistency30Days}%',
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
    );
  }

  Widget _buildSecondaryMetricsRow(
    BuildContext context,
    AnalyticsUiState uiState,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            icon: Icons.local_fire_department,
            iconTint: theme.colorScheme.tertiary,
            value: '${uiState.bestStreakRecord}',
            label: 'Best Streak',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: Icons.check,
            iconTint: theme.colorScheme.primary,
            value: '${uiState.completedTodayCount}',
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

  Widget _buildMetricCard(
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

  Widget _buildLeaderboardCard(
    BuildContext context,
    List<LeaderboardItem> leaderboard,
  ) {
    final theme = Theme.of(context);

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
                onTap: () => widget.onNavigateToDetail?.call(item.habit.id),
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
