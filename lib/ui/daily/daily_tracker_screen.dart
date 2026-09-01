import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/preferences/theme_preferences.dart';
import '../../domain/models/habit.dart';
import '../common/haptics_helper.dart';
import '../form/habit_form_bottom_sheet.dart';
import '../navigation/habit_bottom_navigation.dart';
import '../navigation/screen.dart';
import '../reflection/reflection_bottom_sheet.dart';
import 'controllers/daily_tracker_controller.dart';
import 'widgets/habit_card.dart';
import 'widgets/historical_banner.dart';
import 'widgets/profile_settings_bottom_sheet.dart';
import 'widgets/progress_ring.dart';
import 'widgets/routine_section.dart';

class DailyTrackerScreen extends ConsumerStatefulWidget {
  final ValueChanged<String>? onNavigateToDetail;
  final VoidCallback? onNavigateToMatrix;
  final VoidCallback? onNavigateToAnalytics;
  final VoidCallback? onNavigateToBadges;
  final VoidCallback? onOpenAddHabit;

  const DailyTrackerScreen({
    super.key,
    this.onNavigateToDetail,
    this.onNavigateToMatrix,
    this.onNavigateToAnalytics,
    this.onNavigateToBadges,
    this.onOpenAddHabit,
  });

  @override
  ConsumerState<DailyTrackerScreen> createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends ConsumerState<DailyTrackerScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;

  late final AnimationController _toastAnimationController;
  late final Animation<double> _toastFadeAnimation;
  late final Animation<Offset> _toastSlideAnimation;
  Timer? _toastTimer;
  Habit? _activeReflectionHabit;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  void _showReflectionToast(Habit habit) {
    _toastTimer?.cancel();
    setState(() {
      _activeReflectionHabit = habit;
    });
    _toastAnimationController.forward(from: 0.0);
    _toastTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _toastAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _activeReflectionHabit = null;
            });
          }
        });
      }
    });
  }

  void _dismissReflectionToast() {
    _toastTimer?.cancel();
    _toastAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _activeReflectionHabit = null;
        });
      }
    });
  }

  Future<void> _selectDatePicker(DateTime selectedDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ref.read(dailyTrackerControllerProvider.notifier).selectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ref.read(dailyTrackerControllerProvider.notifier);
    final currentUserName = ref.watch(userNameProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Integrated M3 Search Bar & Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    child: Row(
                      children: [
                        // Avatar (Leading action - Profile & Settings)
                        Tooltip(
                          message: currentUserName.isNotEmpty
                              ? '$currentUserName (Settings)'
                              : 'Profile & Settings',
                          child: Semantics(
                            identifier: 'profile_settings_button',
                            label: 'Profile & Settings',
                            button: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () =>
                                  ProfileSettingsBottomSheet.show(context),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: currentUserName.isNotEmpty
                                      ? Text(
                                          currentUserName[0].toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: theme
                                                .colorScheme.onPrimaryContainer,
                                          ),
                                        )
                                      : Icon(
                                          Icons.person_outline,
                                          size: 18,
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Search Input
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {});
                              controller.setSearchQuery(val);
                            },
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: currentUserName.isNotEmpty
                                  ? 'Search habits, $currentUserName...'
                                  : 'Search habits...',
                              hintStyle:
                                  theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.75),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8),
                            ),
                          ),
                        ),

                        // Trailing Action Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                iconSize: 18,
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.clear,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                tooltip: 'Clear Search',
                                onPressed: () {
                                  _searchController.clear();
                                  controller.setSearchQuery('');
                                  setState(() {});
                                },
                              ),
                            const _DailySortMenuButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Historical Date Banner
                const _DailyHistoricalBanner(),

                // Compact Date Selector: ‹ Mon, Aug 17 › [Calendar]
                _DailyDateSelector(
                  onSelectDatePicker: _selectDatePicker,
                ),

                // Today's Progress Card
                const _DailyProgressCard(),

                // Category Chips Row
                const _DailyCategoryChipsRow(),

                const SizedBox(height: 4),

                // Habits List
                Expanded(
                  child: _DailyHabitsList(
                    onNavigateToDetail: widget.onNavigateToDetail,
                    onShowReflectionToast: _showReflectionToast,
                  ),
                ),
              ],
            ),

            // Floating Reflection Toast
            if (_activeReflectionHabit != null)
              Consumer(
                builder: (context, ref, _) {
                  final selectedDate = ref.watch(
                    dailyTrackerControllerProvider.select((s) => s.selectedDate),
                  );
                  return Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: _buildReflectionToast(theme, selectedDate),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: HabitBottomNavigation(
        currentRoute: Screen.daily,
        onNavigate: (route) {
          if (route == Screen.matrix) {
            widget.onNavigateToMatrix?.call();
          } else if (route == Screen.analytics) {
            widget.onNavigateToAnalytics?.call();
          } else if (route == Screen.badges) {
            widget.onNavigateToBadges?.call();
          }
        },
        onAddHabitClick: () {
          if (widget.onOpenAddHabit != null) {
            widget.onOpenAddHabit!();
          } else {
            HabitFormBottomSheet.show(context);
          }
        },
      ),
    );
  }

  Widget _buildReflectionToast(ThemeData theme, DateTime selectedDate) {
    final habit = _activeReflectionHabit;
    if (habit == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _toastSlideAnimation,
      child: FadeTransition(
        opacity: _toastFadeAnimation,
        child: Dismissible(
          key: ValueKey('reflection_toast_${habit.id}'),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => _dismissReflectionToast(),
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
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Completed "${habit.title}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
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
                      _dismissReflectionToast();
                      ReflectionBottomSheet.show(
                        context,
                        habit: habit,
                        date: selectedDate,
                      );
                    },
                    child: Text(
                      'Reflect',
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



class _DailySortMenuButton extends ConsumerWidget {
  const _DailySortMenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentSort = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.sortOption),
    );
    final controller = ref.read(dailyTrackerControllerProvider.notifier);

    return PopupMenuButton<HabitSortOption>(
      iconSize: 20,
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.sort,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      tooltip: 'Sort Habits',
      onSelected: (option) {
        HapticsHelper.performLightHaptic();
        controller.setSortOption(option);
      },
      itemBuilder: (context) {
        return HabitSortOption.values.map((option) {
          final isSelected = currentSort == option;
          return PopupMenuItem<HabitSortOption>(
            value: option,
            child: Text(
              option.displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          );
        }).toList();
      },
    );
  }
}

class _DailyHistoricalBanner extends ConsumerWidget {
  const _DailyHistoricalBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.selectedDate),
    );
    final controller = ref.read(dailyTrackerControllerProvider.notifier);

    return HistoricalBanner(
      selectedDate: selectedDate,
      onReturnToToday: controller.selectToday,
    );
  }
}

class _DailyDateSelector extends ConsumerWidget {
  final Future<void> Function(DateTime selectedDate) onSelectDatePicker;

  const _DailyDateSelector({
    required this.onSelectDatePicker,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.selectedDate),
    );
    final controller = ref.read(dailyTrackerControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
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
                  controller.previousDay();
                },
              ),
              Text(
                DateFormat('EEE, MMM d').format(selectedDate),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
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
                  controller.nextDay();
                },
              ),
            ],
          ),
          IconButton(
            iconSize: 22,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            icon: Icon(
              Icons.calendar_month,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Select Date',
            onPressed: () {
              HapticsHelper.performLightHaptic();
              onSelectDatePicker(selectedDate);
            },
          ),
        ],
      ),
    );
  }
}

class _DailyProgressCard extends ConsumerWidget {
  const _DailyProgressCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = ref.watch(
      dailyTrackerControllerProvider
          .select((s) => s.totalScheduledForSelectedDate),
    );
    final completed = ref.watch(
      dailyTrackerControllerProvider
          .select((s) => s.totalCompletedForSelectedDate),
    );
    final earnedXp = ref.watch(
      dailyTrackerControllerProvider
          .select((s) => s.totalXpEarnedForSelectedDate),
    );
    final percent = total > 0 ? ((completed / total) * 100).toInt() : 0;
    final progressFraction = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        color: theme.colorScheme.surface,
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Hero Circular Progress Ring (80x80)
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(76, 76),
                      painter: ProgressRingPainter(
                        progress: progressFraction,
                        trackColor: theme.colorScheme.surfaceContainerHighest,
                        progressColor: theme.colorScheme.primary,
                        strokeWidth: 7,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percent%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '$completed / $total',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),

              // Progress Details & XP Chip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Today's Progress",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total == 0
                          ? 'No habits scheduled'
                          : (completed == total
                              ? 'All habits completed!'
                              : '$completed of $total habits completed'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+$earnedXp XP earned',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCategoryChipsRow extends ConsumerWidget {
  const _DailyCategoryChipsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.categories),
    );
    final selectedCategoryId = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.selectedCategoryId),
    );
    final totalScheduled = ref.watch(
      dailyTrackerControllerProvider
          .select((s) => s.totalScheduledForSelectedDate),
    );
    final categoryCounts = ref.watch(
      dailyTrackerControllerProvider
          .select((s) => s.categoryHabitCounts),
    );
    final archivedHabitsCount = ref.watch(
      dailyTrackerControllerProvider
          .select((s) => s.archivedHabitsCount),
    );
    final controller = ref.read(dailyTrackerControllerProvider.notifier);

    if (categories.isEmpty && archivedHabitsCount == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selectedCategoryId == null,
              label: Text('All ($totalScheduled)'),
              onSelected: (_) {
                HapticsHelper.performLightHaptic();
                controller.selectCategory(null);
              },
            ),
          ),
          ...categories.map((cat) {
            final isSelected = selectedCategoryId == cat.id;
            final count = categoryCounts[cat.id] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text('${cat.name} ($count)'),
                onSelected: (_) {
                  HapticsHelper.performLightHaptic();
                  controller.selectCategory(cat.id);
                },
              ),
            );
          }),
          if (archivedHabitsCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selectedCategoryId == DailyTrackerController.archivedCategoryId,
                label: Text('Archived ($archivedHabitsCount)'),
                onSelected: (_) {
                  HapticsHelper.performLightHaptic();
                  controller.selectCategory(DailyTrackerController.archivedCategoryId);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DailyHabitsList extends ConsumerWidget {
  final ValueChanged<String>? onNavigateToDetail;
  final void Function(Habit habit) onShowReflectionToast;

  const _DailyHabitsList({
    required this.onNavigateToDetail,
    required this.onShowReflectionToast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.isLoading),
    );
    final habits = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.habits),
    );
    final searchQuery = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.searchQuery),
    );
    final selectedCategoryId = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.selectedCategoryId),
    );
    final categories = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.categories),
    );
    final selectedDate = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.selectedDate),
    );
    final controller = ref.read(dailyTrackerControllerProvider.notifier);
    final showRoutines = searchQuery.isEmpty && selectedCategoryId == null;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (habits.isEmpty) {
      final selectedCat = categories
          .where((c) => c.id == selectedCategoryId)
          .firstOrNull;
      final categoryName = selectedCat?.name ?? 'this category';

      final String emptyTitle;
      final String emptySubtitle;
      final IconData emptyIcon;

      if (searchQuery.isNotEmpty) {
        emptyTitle = 'No matching habits found';
        emptySubtitle = 'Try searching for a different keyword';
        emptyIcon = Icons.search_off;
      } else if (selectedCategoryId == DailyTrackerController.archivedCategoryId) {
        emptyTitle = 'No archived habits';
        emptySubtitle = 'Archived habits will appear here.';
        emptyIcon = Icons.archive_outlined;
      } else if (selectedCategoryId != null) {
        emptyTitle = 'No habits in "$categoryName"';
        emptySubtitle = 'Create a habit in this category or view all habits.';
        emptyIcon = Icons.category_outlined;
      } else {
        emptyTitle = 'No habits scheduled for this day';
        emptySubtitle =
            'Create your own habit or load starter habits to explore features.';
        emptyIcon = Icons.track_changes_outlined;
      }

      return ListView(
        key: const ValueKey('daily_empty_list'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          if (showRoutines) ...[
            RoutineSection(
              selectedDate: selectedDate,
              onStartRoutinePlayer: (routine) {
                Navigator.of(context).pushNamed(
                  Screen.routinePlayerRoute(routine.id, selectedDate),
                  arguments: selectedDate,
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      emptyIcon,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    emptySubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      if (searchQuery.isNotEmpty)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('Clear Search'),
                          onPressed: () {
                            HapticsHelper.performLightHaptic();
                            controller.setSearchQuery('');
                          },
                        )
                      else if (selectedCategoryId == DailyTrackerController.archivedCategoryId)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.apps, size: 18),
                          label: const Text('View All Habits'),
                          onPressed: () {
                            HapticsHelper.performLightHaptic();
                            controller.selectCategory(null);
                          },
                        )
                      else if (selectedCategoryId != null) ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create Habit'),
                          onPressed: () {
                            HapticsHelper.performLightHaptic();
                            HabitFormBottomSheet.show(context);
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.apps, size: 18),
                          label: const Text('View All Habits'),
                          onPressed: () {
                            HapticsHelper.performLightHaptic();
                            controller.selectCategory(null);
                          },
                        ),
                      ] else ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create Habit'),
                          onPressed: () {
                            HapticsHelper.performLightHaptic();
                            HabitFormBottomSheet.show(context);
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('Load Demo Habits'),
                          onPressed: () async {
                            HapticsHelper.performLightHaptic();
                            await controller.loadDemoHabits();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Starter demo habits loaded!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final totalCount = showRoutines ? habits.length + 1 : habits.length;

    return ListView.separated(
      key: const ValueKey('daily_habit_list'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: totalCount,
      separatorBuilder: (_, index) {
        if (showRoutines && index == 0) {
          return const SizedBox(height: 8);
        }
        return const SizedBox(height: 8);
      },
      itemBuilder: (context, index) {
        if (showRoutines && index == 0) {
          return RoutineSection(
            selectedDate: selectedDate,
            onStartRoutinePlayer: (routine) {
              Navigator.of(context).pushNamed(
                Screen.routinePlayerRoute(routine.id, selectedDate),
                arguments: selectedDate,
              );
            },
          );
        }

        final habitIndex = showRoutines ? index - 1 : index;
        final habitWithProgress = habits[habitIndex];
        return HabitCard(
          key: ValueKey(habitWithProgress.habit.id),
          habitWithProgress: habitWithProgress,
          onHabitClick: (id) {
            onNavigateToDetail?.call(id);
          },
          onToggleCheckIn: () {
            final wasCompleted = habitWithProgress.isCompletedOnDate;
            controller.toggleCheckIn(habitWithProgress.habit);
            if (!wasCompleted && habitWithProgress.habit.promptReflection) {
              onShowReflectionToast(habitWithProgress.habit);
            }
          },
          onSelectTier: (tier) {
            controller.logTier(habitWithProgress.habit.id, tier);
          },
          onReflect: () {
            final log = habitWithProgress.logsForDate.firstOrNull;
            ReflectionBottomSheet.show(
              context,
              habit: habitWithProgress.habit,
              date: selectedDate,
              initialEnergyLevel: log?.energyLevel,
              initialMood: log?.mood,
              initialNote: log?.note,
            );
          },
          onToggleShield: () {
            controller.toggleShield(habitWithProgress.habit);
          },
          onValueChange: (val) {
            controller.updateNumericValue(habitWithProgress.habit.id, val);
          },
          onDeltaAdd: (delta) {
            controller.addNumericDelta(habitWithProgress.habit.id, delta);
          },
          onToggleSlot: (slotIndex) {
            controller.toggleSlot(habitWithProgress.habit.id, slotIndex);
          },
          onTogglePin: () {
            controller.togglePinned(habitWithProgress.habit);
          },
          onStartFocus: () {
            onNavigateToDetail?.call(habitWithProgress.habit.id);
          },
        );
      },
    );
  }
}
