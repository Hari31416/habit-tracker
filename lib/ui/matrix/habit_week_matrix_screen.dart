import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../common/haptics_helper.dart';
import '../form/habit_form_bottom_sheet.dart';
import '../gamification/dialogs/shield_bank_bottom_sheet.dart';
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

class _HabitWeekMatrixScreenState extends ConsumerState<HabitWeekMatrixScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _toastAnimationController;
  late final Animation<double> _toastFadeAnimation;
  late final Animation<Offset> _toastSlideAnimation;
  Timer? _toastTimer;
  bool _showShieldDepletedToast = false;

  @override
  void initState() {
    super.initState();
    _toastAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _toastFadeAnimation = CurvedAnimation(
      parent: _toastAnimationController,
      curve: Curves.easeInOut,
    );
    _toastSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _toastAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _toastAnimationController.dispose();
    super.dispose();
  }

  void _showShieldExhaustedToast() {
    _toastTimer?.cancel();
    setState(() {
      _showShieldDepletedToast = true;
    });
    _toastAnimationController.forward(from: 0.0);
    _toastTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _toastAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showShieldDepletedToast = false;
            });
          }
        });
      }
    });
  }

  void _dismissShieldExhaustedToast() {
    _toastTimer?.cancel();
    _toastAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showShieldDepletedToast = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        child: Stack(
          children: [
            Column(
              children: [
                // Top App Bar with Integrated Week Stepper
                const _WeekMatrixTopBar(),

                // Scrollable Slivers Content
                Expanded(
                  child: _WeekMatrixContent(
                    onNavigateToDetail: widget.onNavigateToDetail,
                    onShowShieldExhaustedToast: _showShieldExhaustedToast,
                  ),
                ),
              ],
            ),

            // Floating Shield Exhausted Toast (matching Reflect nudge pattern)
            if (_showShieldDepletedToast)
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: _buildShieldExhaustedToast(theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShieldExhaustedToast(ThemeData theme) {
    return SlideTransition(
      position: _toastSlideAnimation,
      child: FadeTransition(
        opacity: _toastFadeAnimation,
        child: Dismissible(
          key: const ValueKey('shield_exhausted_toast'),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => _dismissShieldExhaustedToast(),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black45,
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'No shields available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _dismissShieldExhaustedToast();
                      ShieldBankBottomSheet.show(context);
                    },
                    child: Text(
                      'View Bank',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekMatrixTopBar extends ConsumerWidget {
  const _WeekMatrixTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weekStart = ref.watch(
      weekMatrixControllerProvider.select((s) => s.weekStart),
    );
    final weekEnd = ref.watch(
      weekMatrixControllerProvider.select((s) => s.weekEnd),
    );
    final isCurrentWeek = ref.watch(
      weekMatrixControllerProvider.select((s) => s.isCurrentWeek),
    );
    final controller = ref.read(weekMatrixControllerProvider.notifier);

    final startStr = DateFormat('MMM d').format(weekStart);
    final endStr = DateFormat('MMM d').format(weekEnd);

    return Material(
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
                  if (!isCurrentWeek) ...[
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
    );
  }
}

class _WeekMatrixContent extends ConsumerWidget {
  final ValueChanged<String>? onNavigateToDetail;
  final VoidCallback? onShowShieldExhaustedToast;

  const _WeekMatrixContent({
    this.onNavigateToDetail,
    this.onShowShieldExhaustedToast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      weekMatrixControllerProvider.select((s) => s.isLoading),
    );

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _WeekMatrixAdherenceStrip(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _WeekMatrixGridSection(
              onNavigateToDetail: onNavigateToDetail,
              onShowShieldExhaustedToast: onShowShieldExhaustedToast,
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
          sliver: SliverToBoxAdapter(
            child: _WeekMatrixDailyCompletions(),
          ),
        ),
      ],
    );
  }
}

class _WeekMatrixAdherenceStrip extends ConsumerWidget {
  const _WeekMatrixAdherenceStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final adherencePercentage = ref.watch(
      weekMatrixControllerProvider.select((s) => s.adherencePercentage),
    );
    final totalCompleted = ref.watch(
      weekMatrixControllerProvider.select((s) => s.totalCompleted),
    );
    final totalScheduled = ref.watch(
      weekMatrixControllerProvider.select((s) => s.totalScheduled),
    );
    final totalShielded = ref.watch(
      weekMatrixControllerProvider.select((s) => s.totalShielded),
    );
    final rowCount = ref.watch(
      weekMatrixControllerProvider.select((s) => s.rows.length),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  '$adherencePercentage%',
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
                  '$totalCompleted / $totalScheduled',
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
                  totalShielded > 0 ? '$totalShielded 🛡️' : '$rowCount',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: totalShielded > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  totalShielded > 0 ? 'Protected' : 'Active Habits',
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
}

class _WeekMatrixGridSection extends ConsumerWidget {
  final ValueChanged<String>? onNavigateToDetail;
  final VoidCallback? onShowShieldExhaustedToast;

  const _WeekMatrixGridSection({
    this.onNavigateToDetail,
    this.onShowShieldExhaustedToast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(
      weekMatrixControllerProvider.select((s) => s.rows),
    );
    final controller = ref.read(weekMatrixControllerProvider.notifier);

    return WeekMatrixGrid(
      rows: rows,
      onToggleCell: (habitId, date) {
        controller.toggleCell(habitId, date);
      },
      onToggleShieldCell: (habitId, date) async {
        final success = await controller.toggleShieldCell(habitId, date);
        if (!success) {
          onShowShieldExhaustedToast?.call();
        }
      },
      onHabitClick: (habitId) {
        onNavigateToDetail?.call(habitId);
      },
    );
  }
}

class _WeekMatrixDailyCompletions extends ConsumerWidget {
  const _WeekMatrixDailyCompletions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dailyStats = ref.watch(
      weekMatrixControllerProvider.select((s) => s.dailyStats),
    );

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
