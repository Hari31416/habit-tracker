import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/preferences/theme_mode.dart';
import '../../data/preferences/theme_preferences.dart';
import '../../domain/gamification/gamification_engine.dart';
import '../../domain/models/habit.dart';
import '../common/haptics_helper.dart';
import '../form/habit_form_bottom_sheet.dart';
import '../gamification/dialogs/shield_bank_bottom_sheet.dart';
import '../navigation/habit_bottom_navigation.dart';
import '../navigation/screen.dart';
import '../reflection/reflection_bottom_sheet.dart';
import '../settings/backup_settings_bottom_sheet.dart';
import '../settings/health_connect_settings_bottom_sheet.dart';
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

class _DailyTrackerScreenState extends ConsumerState<DailyTrackerScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final TextEditingController _nameInputController;

  late final AnimationController _toastAnimationController;
  late final Animation<double> _toastFadeAnimation;
  late final Animation<Offset> _toastSlideAnimation;
  Timer? _toastTimer;
  Habit? _activeReflectionHabit;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _nameInputController = TextEditingController();

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
    _nameInputController.dispose();
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

  void _showProfileSheet(
      BuildContext context, String currentUserName, AppThemeMode currentThemeMode) {
    HapticsHelper.performLightHaptic();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        currentUserName.isNotEmpty
                            ? currentUserName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUserName.isNotEmpty
                                ? currentUserName
                                : 'Set your name',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getTimeGreeting(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Name',
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _showNameDialog(currentUserName);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Appearance section
                Text(
                  'Appearance',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<AppThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: AppThemeMode.system,
                      icon: Icon(Icons.brightness_auto, size: 18),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      icon: Icon(Icons.light_mode, size: 18),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      icon: Icon(Icons.dark_mode, size: 18),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {currentThemeMode},
                  onSelectionChanged: (Set<AppThemeMode> newSelection) {
                    HapticsHelper.performLightHaptic();
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(newSelection.first);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: 14),

                // Streak Shield Bank Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: theme.colorScheme.onSecondaryContainer,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Streak Shields Bank',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle:
                      const Text('Manage streak freezes and protection'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ShieldBankBottomSheet.show(context);
                  },
                ),
                const SizedBox(height: 4),

                // Google Health Connect Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_outline,
                      color: theme.colorScheme.onTertiaryContainer,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Google Health Connect',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle:
                      const Text('Auto-sync steps, exercise, hydration & sleep'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    HealthConnectSettingsBottomSheet.show(context);
                  },
                ),
                const SizedBox(height: 4),

                // Data & Backup Option
                Semantics(
                  identifier: 'settings_data_backup',
                  label: 'Data & Backup',
                  button: true,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sync_outlined,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Data & Backup',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle:
                        const Text('Export, import, and spreadsheet sync'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      BackupSettingsBottomSheet.show(context);
                    },
                  ),
                ),
              ],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ref.read(dailyTrackerControllerProvider.notifier);
    final currentUserName = ref.watch(userNameProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Integrated M3 Search Bar & Header
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 6),
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
                        horizontal: 8, vertical: 4),
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
                              onTap: () => _showProfileSheet(
                                  context, currentUserName, currentThemeMode),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: CircleAvatar(
                                  radius: 18,
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

                const SizedBox(height: 6),

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
    final habits = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.habits),
    );

    final percent = total > 0 ? ((completed / total) * 100).toInt() : 0;
    final earnedXp = habits.fold<int>(0, (sum, item) {
      final baseXp = GamificationEngine.calculateHabitDayBaseXp(
        item.habit,
        item.logsForDate,
        item.isCompletedOnDate,
      );
      final multiplier = GamificationEngine.calculateStreakMultiplier(
        item.streak.currentStreak,
      );
      return sum + GamificationEngine.applyMultiplier(baseXp, multiplier);
    });
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
    final controller = ref.read(dailyTrackerControllerProvider.notifier);

    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
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
    final selectedDate = ref.watch(
      dailyTrackerControllerProvider.select((s) => s.selectedDate),
    );
    final controller = ref.read(dailyTrackerControllerProvider.notifier);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (habits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  searchQuery.isNotEmpty ? Icons.search_off : Icons.track_changes_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                searchQuery.isNotEmpty
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
                searchQuery.isNotEmpty
                    ? 'Try searching for a different keyword or category'
                    : 'Create your own habit or load starter habits to explore features.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              if (searchQuery.isEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
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
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: habits.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final habitWithProgress = habits[index];
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
