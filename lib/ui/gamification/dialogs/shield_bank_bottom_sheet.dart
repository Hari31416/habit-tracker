import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../di/providers.dart';
import '../../../domain/engines/streak_calculator.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_log.dart';
import '../../../domain/models/habit_shield.dart';
import '../../common/color_utils.dart';
import '../../common/habit_icon_registry.dart';
import '../../common/haptics_helper.dart';

class ShieldBankBottomSheet extends ConsumerStatefulWidget {
  const ShieldBankBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ShieldBankBottomSheet(),
    );
  }

  @override
  ConsumerState<ShieldBankBottomSheet> createState() =>
      _ShieldBankBottomSheetState();
}

class _ShieldBankBottomSheetState extends ConsumerState<ShieldBankBottomSheet> {
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gamificationRepo = ref.watch(gamificationRepositoryProvider);
    final habitRepo = ref.watch(habitRepositoryProvider);

    return StreamBuilder(
      stream: gamificationRepo.getShieldBankState(),
      builder: (context, snapshot) {
        final bankState = snapshot.data;
        final available = bankState?.availableShields ?? 0;
        final maxCapacity = bankState?.maxCapacity ?? 3;
        final totalEarned = bankState?.totalShieldsEarned ?? 1;
        final usedCount = bankState?.usedShieldsCount ?? 0;
        final daysToNext = bankState?.daysToNextShield ?? 14;
        final progress = bankState?.progressToNextShield ?? 0.0;
        final autoConsume = bankState?.autoConsumeEnabled ?? true;

        return Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 12,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.shield,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Habit Shields & Grace Days',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Streak Freeze & Protection',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Shield Bank Summary Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              context,
                              '$available / $maxCapacity',
                              'Available',
                              theme.colorScheme.primary,
                            ),
                            _buildStatColumn(
                              context,
                              '$totalEarned',
                              'Total Earned',
                              theme.colorScheme.onSurface,
                            ),
                            _buildStatColumn(
                              context,
                              '$usedCount',
                              'Active Shields',
                              theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          available >= maxCapacity
                              ? 'Max shield capacity reached!'
                              : '$daysToNext days of unbroken consistency to next shield',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Manual Application & Quick Protect Section
                _buildQuickApplySection(context, habitRepo, available),

                const SizedBox(height: 16),

                // How to Apply Explanation Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ways to Apply Shields',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildHowToItem(
                        context,
                        '1. Auto-Protection',
                        'Missed days automatically consume a shield at midnight rollover.',
                      ),
                      const SizedBox(height: 6),
                      _buildHowToItem(
                        context,
                        '2. Habit Detail Calendar',
                        'Open any habit, tap a past missed date in the calendar, and tap "Protect".',
                      ),
                      const SizedBox(height: 6),
                      _buildHowToItem(
                        context,
                        '3. Week Matrix Grid',
                        'Long-press on any day cell in the Week Matrix to toggle a streak freeze.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Settings Controls
                Text(
                  'Protection Settings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Auto-Consume Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Auto-Consume Shields',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Automatically protect missed days on midnight rollover if an active streak is at risk',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: autoConsume,
                  onChanged: (val) {
                    HapticsHelper.performLightHaptic();
                    gamificationRepo.updateShieldSettings(
                      maxCapacity: maxCapacity,
                      autoConsume: val,
                    );
                  },
                ),

                const Divider(height: 16),

                // Max Capacity Stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Max Shield Capacity',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Limit maximum banked shields ($maxCapacity shields)',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          iconSize: 18,
                          icon: const Icon(Icons.remove),
                          onPressed: maxCapacity > 1
                              ? () {
                                  HapticsHelper.performLightHaptic();
                                  gamificationRepo.updateShieldSettings(
                                    maxCapacity: maxCapacity - 1,
                                    autoConsume: autoConsume,
                                  );
                                }
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$maxCapacity',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          iconSize: 18,
                          icon: const Icon(Icons.add),
                          onPressed: maxCapacity < 10
                              ? () {
                                  HapticsHelper.performLightHaptic();
                                  gamificationRepo.updateShieldSettings(
                                    maxCapacity: maxCapacity + 1,
                                    autoConsume: autoConsume,
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildQuickApplySection(
    BuildContext context,
    dynamic habitRepo,
    int availableShields,
  ) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = _dateFormatter.format(yesterday);

    return StreamBuilder<List<Habit>>(
      stream: habitRepo.getActiveHabits(),
      builder: (context, habitSnap) {
        final habits = habitSnap.data ?? [];
        if (habits.isEmpty) return const SizedBox.shrink();

        return StreamBuilder<List<HabitShield>>(
          stream: habitRepo.getAllShields(),
          builder: (context, shieldSnap) {
            final shields = shieldSnap.data ?? [];
            return StreamBuilder<List<HabitLog>>(
              stream: habitRepo.getAllLogs(),
              builder: (context, logSnap) {
                final logs = logSnap.data ?? [];

                // Find habits missed yesterday or recently
                final missedHabitsYesterday = habits.where((h) {
                  final isScheduled =
                      StreakCalculator.isHabitScheduledOnDate(h, yesterday);
                  if (!isScheduled) return false;
                  final hLogs = logs
                      .where((l) => l.habitId == h.id && l.date == yesterdayStr)
                      .toList();
                  final isCompleted =
                      StreakCalculator.isHabitCompletedOnDate(h, hLogs);
                  return !isCompleted;
                }).toList();

                if (missedHabitsYesterday.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                              Icons.history_toggle_off,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Yesterday Missed Habits (${DateFormat('MMM d').format(yesterday)})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...missedHabitsYesterday.map((habit) {
                          final isShielded = shields.any(
                            (s) => s.habitId == habit.id && s.date == yesterdayStr,
                          );
                          final accentColor = ColorUtils.parseHexColor(habit.color);
                          final iconData = HabitIconRegistry.getIcon(habit.icon);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(iconData, size: 16, color: accentColor),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    habit.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isShielded)
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.shield, size: 14),
                                    label: const Text('Protected'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () {
                                      HapticsHelper.performLightHaptic();
                                      habitRepo.removeShield(habit.id, yesterday);
                                    },
                                  )
                                else
                                  FilledButton.tonalIcon(
                                    icon: const Icon(Icons.shield_outlined, size: 14),
                                    label: const Text('Protect'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: availableShields > 0
                                        ? () {
                                            HapticsHelper.performHeavyConfirmationHaptic();
                                            habitRepo.applyShield(
                                              habitId: habit.id,
                                              date: yesterday,
                                            );
                                          }
                                        : null,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHowToItem(BuildContext context, String title, String desc) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String value,
    String label,
    Color valueColor,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
