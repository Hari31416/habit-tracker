import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../common/haptics_helper.dart';
import '../form/habit_form_bottom_sheet.dart';
import '../navigation/habit_bottom_navigation.dart';
import '../navigation/screen.dart';
import 'controllers/week_matrix_controller.dart';
import 'widgets/week_matrix_grid.dart';

class HabitWeekMatrixScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToDaily;
  final VoidCallback? onNavigateToAnalytics;
  final VoidCallback? onNavigateToBadges;
  final ValueChanged<String>? onNavigateToDetail;

  const HabitWeekMatrixScreen({
    super.key,
    this.onNavigateToDaily,
    this.onNavigateToAnalytics,
    this.onNavigateToBadges,
    this.onNavigateToDetail,
  });

  @override
  ConsumerState<HabitWeekMatrixScreen> createState() =>
      _HabitWeekMatrixScreenState();
}

class _HabitWeekMatrixScreenState extends ConsumerState<HabitWeekMatrixScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uiState = ref.watch(weekMatrixControllerProvider);
    final controller = ref.read(weekMatrixControllerProvider.notifier);

    final startStr = DateFormat('MMM d').format(uiState.weekStart);
    final endStr = DateFormat('MMM d').format(uiState.weekEnd);

    return Scaffold(
      bottomNavigationBar: HabitBottomNavigation(
        currentRoute: Screen.matrix,
        onNavigate: (route) {
          if (route == Screen.daily) {
            widget.onNavigateToDaily?.call();
          } else if (route == Screen.matrix) {
            // Already here
          } else if (route == Screen.analytics) {
            widget.onNavigateToAnalytics?.call();
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
            // Top App Bar with Integrated Week Stepper
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
                      'Week Matrix',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_left),
                            tooltip: 'Previous Week',
                            onPressed: () {
                              HapticsHelper.performLightHaptic();
                              controller.previousWeek();
                            },
                          ),
                          Text(
                            '$startStr – $endStr',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'Next Week',
                            onPressed: () {
                              HapticsHelper.performLightHaptic();
                              controller.nextWeek();
                            },
                          ),
                          if (!uiState.isCurrentWeek) ...[
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                HapticsHelper.performLightHaptic();
                                controller.currentWeek();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'This Week',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
                          // 1. Weekly Adherence Summary Strip
                          _buildAdherenceSummaryStrip(context, uiState),

                          const SizedBox(height: 14),

                          // 2. Interactive Week Matrix Grid
                          WeekMatrixGrid(
                            rows: uiState.rows,
                            onToggleCell: (habitId, date) {
                              controller.toggleCell(habitId, date);
                            },
                            onToggleShieldCell: (habitId, date) {
                              controller.toggleShieldCell(habitId, date);
                            },
                            onHabitClick: (habitId) {
                              widget.onNavigateToDetail?.call(habitId);
                            },
                          ),

                          const SizedBox(height: 14),

                          // 3. Daily Completions Breakdown Bar Chart
                          _buildDailyCompletionsChart(
                            context,
                            uiState.dailyStats,
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

  Widget _buildAdherenceSummaryStrip(
    BuildContext context,
    WeekMatrixUiState uiState,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  '${uiState.adherencePercentage}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Adherence',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  '${uiState.totalCompleted} / ${uiState.totalScheduled}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Check-ins',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  uiState.totalShielded > 0
                      ? '${uiState.totalShielded} 🛡️'
                      : '${uiState.rows.length}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: uiState.totalShielded > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  uiState.totalShielded > 0 ? 'Protected' : 'Active Habits',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCompletionsChart(
    BuildContext context,
    List<DailyCompletionStat> dailyStats,
  ) {
    final theme = Theme.of(context);
    final maxCount = dailyStats.fold<int>(
      1,
      (max, s) => s.completedCount > max ? s.completedCount : max,
    );

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
              'Daily Completions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dailyStats.map((dayStat) {
                  final barFraction = (dayStat.completedCount / maxCount)
                      .clamp(0.06, 1.0);

                  return SizedBox(
                    width: 36,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${dayStat.completedCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: dayStat.completedCount > 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 18,
                          height: 56,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: barFraction,
                              ),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, value, child) {
                                return Container(
                                  height: 56 * value,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                    color: dayStat.completedCount > 0
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surfaceContainerHighest,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayStat.dayLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}
