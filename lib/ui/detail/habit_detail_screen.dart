import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/engines/streak_calculator.dart';
import '../../domain/models/habit_frequency_type.dart';
import '../../domain/models/habit_target_type.dart';
import '../common/color_utils.dart';
import '../common/habit_icon_registry.dart';
import '../common/haptics_helper.dart';
import '../daily/widgets/numeric_habit_controls.dart';
import '../daily/widgets/slot_habit_controls.dart';
import '../form/habit_form_bottom_sheet.dart';
import '../gamification/dialogs/shield_bank_bottom_sheet.dart';
import 'controllers/habit_detail_controller.dart';
import 'widgets/circular_focus_timer.dart';
import 'widgets/habit_monthly_calendar.dart';
import 'widgets/motivation_card.dart';
import 'widgets/stats_metric_strip.dart';
import 'widgets/ten_dot_progress_bar.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;
  final VoidCallback onBack;
  final ValueChanged<String> onNavigateToFocusScreen;

  const HabitDetailScreen({
    super.key,
    required this.habitId,
    required this.onBack,
    required this.onNavigateToFocusScreen,
  });

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  StreamSubscription? _navigateBackSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
          ref.read(habitDetailControllerProvider(widget.habitId).notifier);
      _navigateBackSubscription =
          controller.navigateBackEvent.listen((_) {
        if (mounted) {
          widget.onBack();
        }
      });
    });
  }

  @override
  void dispose() {
    _navigateBackSubscription?.cancel();
    super.dispose();
  }

  void _showDeleteConfirmDialog(BuildContext context, HabitDetailController controller) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text(
            'Delete Habit?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to delete this habit and all of its recorded history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                controller.deleteHabit();
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uiState = ref.watch(habitDetailControllerProvider(widget.habitId));
    final controller =
        ref.read(habitDetailControllerProvider(widget.habitId).notifier);

    if (uiState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    final habit = uiState.habit;
    if (habit == null || uiState.isDeleted) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
          ),
        ),
        body: const Center(
          child: Text('Habit not found'),
        ),
      );
    }

    final accentColor = ColorUtils.parseHexColor(habit.color);
    final iconData = HabitIconRegistry.getIcon(habit.icon);
    final isWeekly = habit.frequencyType == HabitFrequencyType.weekly;
    final streakUnit = isWeekly ? 'weeks' : 'days';
    final isCompleted = uiState.isCompletedOnSelectedDate;
    final isShielded = uiState.isShieldedOnSelectedDate;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedClean = DateTime(
      uiState.selectedDate.year,
      uiState.selectedDate.month,
      uiState.selectedDate.day,
    );
    final isPast = selectedClean.isBefore(today);
    final isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, selectedClean);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          habit.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: widget.onBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Habit Shields Bank',
            onPressed: () {
              HapticsHelper.performLightHaptic();
              ShieldBankBottomSheet.show(context);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Options',
            onSelected: (value) {
              HapticsHelper.performLightHaptic();
              switch (value) {
                case 'edit':
                  HabitFormBottomSheet.show(
                    context,
                    habitIdToEdit: habit.id,
                  );
                  break;
                case 'pin':
                  controller.setPinned(!habit.pinned);
                  break;
                case 'archive':
                  controller.setArchived(!habit.archived);
                  break;
                case 'delete':
                  _showDeleteConfirmDialog(context, controller);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Edit Habit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(
                      habit.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(habit.pinned ? 'Unpin Habit' : 'Pin Habit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(
                      habit.archived ? Icons.unarchive : Icons.archive,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(habit.archived ? 'Restore Habit' : 'Archive Habit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Habit',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // 1. Hero Header Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              color: theme.colorScheme.surface,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Icon Container (40x40)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            iconData,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title & Category
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (uiState.category != null)
                                Text(
                                  uiState.category!.name,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Mark as done check button (38x38)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? accentColor
                                : isShielded
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                if (!isCompleted) {
                                  HapticsHelper.performHeavyConfirmationHaptic();
                                } else {
                                  HapticsHelper.performLightHaptic();
                                }
                                controller.toggleCheckInForDate(
                                  uiState.selectedDate,
                                );
                              },
                              child: Icon(
                                isCompleted
                                    ? Icons.check
                                    : isShielded
                                        ? Icons.shield
                                        : Icons.check,
                                size: 20,
                                color: isCompleted
                                    ? Colors.white
                                    : isShielded
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Partial progress controls
                    if (habit.targetType == HabitTargetType.numeric) ...[
                      const SizedBox(height: 10),
                      NumericHabitControls(
                        habit: habit,
                        currentValue: uiState.currentValueOnSelectedDate,
                        isCompleted: isCompleted,
                        accentColor: accentColor,
                        onValueChange: (val) {
                          controller.updateNumericValue(val);
                        },
                        onDeltaAdd: (delta) {
                          controller.addNumericDelta(delta);
                        },
                      ),
                    ] else if (habit.frequencyType ==
                            HabitFrequencyType.subdayInterval ||
                        habit.frequencyType ==
                            HabitFrequencyType.timesPerDay) ...[
                      const SizedBox(height: 10),
                      SlotHabitControls(
                        habit: habit,
                        logsForDate: uiState.logsForSelectedDate,
                        accentColor: accentColor,
                        onToggleSlot: (slotIdx) {
                          controller.toggleSlot(slotIdx);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Shield Protection Status/Action Banner for selected date
            if (isShielded) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Streak Freeze Active',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'This day is protected by a shield. Streak is safe!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticsHelper.performLightHaptic();
                          controller.toggleShieldForSelectedDate();
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ] else if (isPast && isScheduled && !isCompleted) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                color: theme.colorScheme.surface,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Missed Date (${DateFormat('MMM d').format(uiState.selectedDate)})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Bank: ${uiState.shieldBank?.availableShields ?? 0}/${uiState.shieldBank?.maxCapacity ?? 3} shields available',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.shield, size: 16),
                        label: const Text('Protect'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        onPressed: (uiState.shieldBank?.availableShields ?? 0) > 0
                            ? () {
                                HapticsHelper.performHeavyConfirmationHaptic();
                                controller.toggleShieldForSelectedDate();
                              }
                            : () {
                                HapticsHelper.performLightHaptic();
                                ShieldBankBottomSheet.show(context);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 2. Compact 3-Metric Stats Strip
            StatsMetricStrip(
              streak: uiState.streak,
              streakUnit: streakUnit,
              accentColor: accentColor,
            ),

            const SizedBox(height: 14),

            // 3. 10-Dot Progress Bar (for NUMERIC and TIMER targets)
            TenDotProgressBar(
              habit: habit,
              currentValue: uiState.currentValueOnSelectedDate,
              accentColor: accentColor,
              onDotClick: (targetVal) {
                controller.set10DotProgress(targetVal);
              },
            ),

            // 4. Hero Focus Timer (for TIMER habits)
            if (habit.targetType == HabitTargetType.timer) ...[
              const SizedBox(height: 14),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                color: theme.colorScheme.surface,
                elevation: 1,
                child: CircularFocusTimer(
                  habitId: habit.id,
                  habitTitle: habit.title,
                  defaultDurationMinutes: habit.targetValue ?? 25.0,
                  remainingUnloggedMinutes:
                      ((habit.targetValue ?? 25.0) - uiState.currentValueOnSelectedDate)
                          .clamp(0.0, double.infinity),
                  accentColor: accentColor,
                  onFocusScreenClick: () {
                    widget.onNavigateToFocusScreen(habit.id);
                  },
                ),
              ),
            ],

            // 5. Scheduled Notifications List
            if (habit.reminderTimes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                color: theme.colorScheme.surface,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.alarm,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scheduled Reminders',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...habit.reminderTimes.map((reminderTime) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                reminderTime,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Active',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],

            // 6. Motivation Notes Card
            if (habit.motivationNotes != null &&
                habit.motivationNotes!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              MotivationCard(
                motivationNotes: habit.motivationNotes!,
                accentColor: accentColor,
              ),
            ],

            const SizedBox(height: 14),

            // 7. Monthly History Calendar
            HabitMonthlyCalendar(
              habit: habit,
              logs: uiState.allLogs,
              shields: uiState.allShields,
              currentMonth: uiState.currentMonth,
              selectedDate: uiState.selectedDate,
              accentColor: accentColor,
              onPreviousMonth: controller.previousMonth,
              onNextMonth: controller.nextMonth,
              onDateClick: controller.selectDate,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
