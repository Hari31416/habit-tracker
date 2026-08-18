import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/preferences/theme_preferences.dart';
import '../common/haptics_helper.dart';
import '../common/theme_toggle_button.dart';
import '../navigation/habit_bottom_navigation.dart';
import '../navigation/screen.dart';
import 'controllers/daily_tracker_controller.dart';
import 'widgets/habit_card.dart';
import 'widgets/historical_banner.dart';

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

class _DailyTrackerScreenState extends ConsumerState<DailyTrackerScreen> {
  bool _isSearchExpanded = false;
  late final TextEditingController _searchController;
  late final TextEditingController _nameInputController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _nameInputController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameInputController.dispose();
    super.dispose();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening';
    } else {
      return 'Hello';
    }
  }

  void _showNameDialog(String currentName) {
    _nameInputController.text = currentName;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'What is your name?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _nameInputController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(userNameProvider.notifier)
                    .setUserName(_nameInputController.text);
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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

  void _showQuickAddDialog() {
    final titleController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Add Habit',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Read 20 pages, Drink Water...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    ref
                        .read(dailyTrackerControllerProvider.notifier)
                        .quickAddHabit(val, null);
                    Navigator.of(ctx).pop();
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final val = titleController.text.trim();
                      if (val.isNotEmpty) {
                        ref
                            .read(dailyTrackerControllerProvider.notifier)
                            .quickAddHabit(val, null);
                        Navigator.of(ctx).pop();
                      }
                    },
                    child: const Text('Add Habit'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uiState = ref.watch(dailyTrackerControllerProvider);
    final controller = ref.read(dailyTrackerControllerProvider.notifier);
    final currentUserName = ref.watch(userNameProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    final timeGreeting = _getTimeGreeting();
    final displayGreeting = currentUserName.isNotEmpty
        ? '$timeGreeting, $currentUserName'
        : timeGreeting;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar & Greeting
            Material(
              color: theme.colorScheme.surface,
              elevation: 1,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Greeting (Clickable for name edit)
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showNameDialog(currentUserName),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  displayGreeting,
                                  style:
                                      theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (currentUserName.isEmpty) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Actions: Theme toggle, Search icon, Sort menu
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ThemeToggleButton(
                          currentTheme: currentThemeMode,
                          onThemeSelected: (mode) {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(mode);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            color: _isSearchExpanded
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          tooltip: 'Search Habits',
                          onPressed: () {
                            HapticsHelper.performLightHaptic();
                            setState(() {
                              _isSearchExpanded = !_isSearchExpanded;
                              if (!_isSearchExpanded) {
                                _searchController.clear();
                                controller.setSearchQuery('');
                              }
                            });
                          },
                        ),
                        PopupMenuButton<HabitSortOption>(
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
                              final isSelected = uiState.sortOption == option;
                              return PopupMenuItem<HabitSortOption>(
                                value: option,
                                child: Text(
                                  option.displayName,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expandable Search Bar
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Material(
                color: theme.colorScheme.surface,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: _searchController,
                    onChanged: controller.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search by title or description...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                controller.setSearchQuery('');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              crossFadeState: _isSearchExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),

            // Historical Date Banner
            HistoricalBanner(
              selectedDate: uiState.selectedDate,
              onReturnToToday: controller.selectToday,
            ),

            // Compact Date Selector: ‹ Mon, Aug 17 › [Calendar]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        DateFormat('EEE, MMM d').format(uiState.selectedDate),
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
                      _selectDatePicker(uiState.selectedDate);
                    },
                  ),
                ],
              ),
            ),

            // Today's Progress Card
            _buildProgressCard(context, theme, uiState),

            // Category Chips Row
            if (uiState.categories.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: uiState.selectedCategoryId == null,
                        label: Text('All (${uiState.totalScheduledForSelectedDate})'),
                        onSelected: (_) {
                          HapticsHelper.performLightHaptic();
                          controller.selectCategory(null);
                        },
                      ),
                    ),
                    ...uiState.categories.map((cat) {
                      final isSelected = uiState.selectedCategoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(cat.name),
                          onSelected: (_) {
                            HapticsHelper.performLightHaptic();
                            controller.selectCategory(cat.id);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            // Habits List
            Expanded(
              child: _buildHabitsList(context, theme, uiState, controller),
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
            _showQuickAddDialog();
          }
        },
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    ThemeData theme,
    DailyTrackerUiState uiState,
  ) {
    final total = uiState.totalScheduledForSelectedDate;
    final completed = uiState.totalCompletedForSelectedDate;
    final percent = total > 0 ? ((completed / total) * 100).toInt() : 0;
    final earnedXp = completed * 25;
    final progressFraction = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        color: theme.colorScheme.surface,
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Circular Progress Ring (90x90)
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(86, 86),
                      painter: _ProgressRingPainter(
                        progress: progressFraction,
                        trackColor: theme.colorScheme.surfaceContainerHighest,
                        progressColor: theme.colorScheme.primary,
                        strokeWidth: 8,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$completed / $total',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'completed',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Percentage & XP Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percent%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      "Today's Progress",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
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
      ),
    );
  }

  Widget _buildHabitsList(
    BuildContext context,
    ThemeData theme,
    DailyTrackerUiState uiState,
    DailyTrackerController controller,
  ) {
    if (uiState.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (uiState.habits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                uiState.searchQuery.isNotEmpty
                    ? 'No matching habits found'
                    : 'No habits scheduled for this day',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "Tap '+' in the bottom bar to create a new habit",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: uiState.habits.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final habitWithProgress = uiState.habits[index];
        return HabitCard(
          key: ValueKey(habitWithProgress.habit.id),
          habitWithProgress: habitWithProgress,
          onHabitClick: (id) {
            widget.onNavigateToDetail?.call(id);
          },
          onToggleCheckIn: () {
            controller.toggleCheckIn(habitWithProgress.habit);
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
            widget.onNavigateToDetail?.call(habitWithProgress.habit.id);
          },
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        progress * 2 * pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
