import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../../domain/engines/streak_calculator.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../../domain/models/habit_target_type.dart';
import '../../../domain/models/habit_tier.dart';
import '../../../domain/models/habit_with_progress.dart';
import '../../common/color_utils.dart';
import '../../common/habit_icon_registry.dart';
import '../../common/haptics_helper.dart';
import '../../common/previews/phial_previews.dart';
import '../../common/previews/preview_fixtures.dart';
import 'elastic_tier_progress_bar.dart';
import 'numeric_habit_controls.dart';
import 'slot_habit_controls.dart';

class HabitCard extends StatelessWidget {
  final HabitWithProgress habitWithProgress;
  final ValueChanged<String> onHabitClick;
  final VoidCallback onToggleCheckIn;
  final ValueChanged<HabitTier>? onSelectTier;
  final VoidCallback? onToggleShield;
  final ValueChanged<double>? onValueChange;
  final ValueChanged<double>? onDeltaAdd;
  final ValueChanged<int>? onToggleSlot;
  final VoidCallback? onTogglePin;
  final VoidCallback? onStartFocus;
  final VoidCallback? onReflect;

  const HabitCard({
    super.key,
    required this.habitWithProgress,
    required this.onHabitClick,
    required this.onToggleCheckIn,
    this.onSelectTier,
    this.onToggleShield,
    this.onValueChange,
    this.onDeltaAdd,
    this.onToggleSlot,
    this.onTogglePin,
    this.onStartFocus,
    this.onReflect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = habitWithProgress.habit;
    final category = habitWithProgress.category;
    final isCompleted = habitWithProgress.isCompletedOnDate;
    final isShielded = habitWithProgress.isShieldedOnDate;
    final streak = habitWithProgress.streak;

    final habitColor = ColorUtils.parseHexColor(habit.color);
    final iconData = HabitIconRegistry.getIcon(habit.icon);
    final outlineVariant = theme.colorScheme.outlineVariant;

    final streakUnit =
        habit.frequencyType == HabitFrequencyType.weekly ? 'wks' : 'd';
    final streakLabel = '${streak.currentStreak} $streakUnit streak';

    final containerColor = isCompleted
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
        : isShielded
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
            : theme.colorScheme.surface;

    final borderColor = isShielded
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : habit.pinned
            ? theme.colorScheme.primary.withValues(alpha: 0.3)
            : outlineVariant.withValues(alpha: 0.35);

    return Semantics(
      identifier: 'habit_card_${habit.id}',
      label: 'Open ${habit.title}',
      button: true,
      child: Card(
      elevation: isCompleted ? 0.5 : 1.5,
      color: containerColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onHabitClick(habit.id),
        onLongPress: onReflect != null
            ? () {
                HapticsHelper.performLightHaptic();
                onReflect?.call();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  // Left Icon Badge (44x44)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: habitColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      iconData,
                      size: 22,
                      color: habitColor,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Middle: Title, Category, Streak / Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                habit.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (habit.archived) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Archived',
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            if (habit.pinned) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.push_pin,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                            if (habit.healthSyncEnabled) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.favorite_outline,
                                size: 13,
                                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),

                        // Category / Description
                        _buildCategoryText(theme, habit, category),
                        const SizedBox(height: 2),

                        // Streak or target status
                        _buildStreakOrStatus(theme, habit, streak, streakLabel, isShielded),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Right Completion Control / Focus Action (Touch target >= 48dp)
                  _buildActionControl(context, theme, habit, isCompleted, isShielded, habitColor),
                ],
              ),

              // Elastic Goals ProgressBar / Auxiliary controls (hidden if archived)
              if (!habit.archived) ...[
                if (habit.hasElasticTiers) ...[
                  const SizedBox(height: 8),
                  ElasticTierProgressBar(
                    habit: habit,
                    currentValue: habitWithProgress.currentValueOnDate,
                    achievedTier: habitWithProgress.achievedTier,
                    accentColor: habitColor,
                    onSelectTier: (tier) {
                      if (onSelectTier != null) {
                        onSelectTier!(tier);
                      } else {
                        onToggleCheckIn();
                      }
                    },
                  ),
                ] else if (habit.targetType == HabitTargetType.numeric && !isCompleted) ...[
                  const SizedBox(height: 8),
                  NumericHabitControls(
                    habit: habit,
                    currentValue: habitWithProgress.currentValueOnDate,
                    isCompleted: isCompleted,
                    accentColor: habitColor,
                    onValueChange: (newVal) => onValueChange?.call(newVal),
                    onDeltaAdd: (delta) => onDeltaAdd?.call(delta),
                  ),
                ] else if ((habit.frequencyType == HabitFrequencyType.subdayInterval ||
                        habit.frequencyType == HabitFrequencyType.timesPerDay) &&
                    !isCompleted) ...[
                  const SizedBox(height: 8),
                  SlotHabitControls(
                    habit: habit,
                    logsForDate: habitWithProgress.logsForDate,
                    accentColor: habitColor,
                    onToggleSlot: (slotIdx) => onToggleSlot?.call(slotIdx),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCategoryText(
    ThemeData theme,
    dynamic habit,
    dynamic category,
  ) {
    final categoryText = category?.name ?? habit.description;
    if (categoryText == null || (categoryText as String).trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      categoryText,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStreakOrStatus(
    ThemeData theme,
    dynamic habit,
    StreakResult streak,
    String streakLabel,
    bool isShielded,
  ) {
    if (habit.isNegative) {
      final habitColor = ColorUtils.parseHexColor(habit.color);
      final cleanDays = streak.currentStreak;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 13,
            color: habitColor,
          ),
          const SizedBox(width: 3),
          Text(
            '$cleanDays days clean',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: habitColor,
            ),
          ),
        ],
      );
    }

    if (isShielded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield,
            size: 13,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 3),
          Text(
            'Shielded • $streakLabel',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      );
    }

    if (habit.hasElasticTiers && habitWithProgress.achievedTier != HabitTier.none) {
      final tier = habitWithProgress.achievedTier;
      final Color tierColor;
      final IconData tierIcon;
      final String tierName;

      switch (tier) {
        case HabitTier.elite:
          tierColor = const Color(0xFF8B5CF6);
          tierIcon = Icons.workspace_premium;
          tierName = 'Elite (35 XP)';
          break;
        case HabitTier.base:
          tierColor = const Color(0xFF10B981);
          tierIcon = Icons.check_circle;
          tierName = 'Base (20 XP)';
          break;
        case HabitTier.mini:
          tierColor = const Color(0xFFF59E0B);
          tierIcon = Icons.local_fire_department;
          tierName = 'Mini (Momentum Saved)';
          break;
        case HabitTier.none:
          tierColor = theme.colorScheme.onSurfaceVariant;
          tierIcon = Icons.circle_outlined;
          tierName = 'None';
          break;
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tierIcon,
            size: 13,
            color: tierColor,
          ),
          const SizedBox(width: 3),
          Text(
            '$tierName • $streakLabel',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: tierColor,
            ),
          ),
        ],
      );
    }

    if (streak.currentStreak > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 13,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 2),
          Text(
            streakLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      );
    } else {
      String targetDesc;
      if (habit.targetType == HabitTargetType.numeric) {
        final current = habitWithProgress.currentValueOnDate.toInt();
        final target = (habit.targetValue ?? 0.0).toInt();
        targetDesc = '$current / $target ${habit.unit ?? ''}'.trim();
      } else if (habit.targetType == HabitTargetType.timer) {
        final mins = (habitWithProgress.currentDurationSecondsOnDate / 60.0).toInt();
        final targetMins = (habit.targetValue ?? 0.0).toInt();
        targetDesc = '$mins / $targetMins min';
      } else {
        targetDesc = 'Not started';
      }

      return Text(
        targetDesc,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      );
    }
  }

  Widget _buildActionControl(
    BuildContext context,
    ThemeData theme,
    dynamic habit,
    bool isCompleted,
    bool isShielded,
    Color habitColor,
  ) {
    if (habit.archived) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 15,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              'Archived',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (habit.isNegative) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: habitColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: habitColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 15,
              color: habitColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Clean',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: habitColor,
              ),
            ),
          ],
        ),
      );
    }

    if (habit.targetType == HabitTargetType.timer && !isCompleted) {
      return Material(
        color: habitColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticsHelper.performLightHaptic();
            onStartFocus?.call();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: habitColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Focus',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: habitColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Semantics(
          identifier: 'habit_check_${habit.id}',
          label: isCompleted
              ? 'Undo check-in ${habit.title}'
              : 'Check in ${habit.title}',
          button: true,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (!isCompleted) {
                HapticsHelper.performHeavyConfirmationHaptic();
              } else {
                HapticsHelper.performLightHaptic();
              }
              onToggleCheckIn();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? habitColor
                    : isShielded
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                border: (isCompleted || isShielded)
                    ? null
                    : Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 2,
                      ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : isShielded
                      ? Icon(
                          Icons.shield,
                          color: theme.colorScheme.primary,
                          size: 18,
                        )
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// Widget Previews
// ==========================================

@PhialMultiBrightnessPreview(name: 'Habit Card - Incomplete', group: 'Daily')
Widget previewHabitCardIncomplete() {
  return PhialPreviewWrapper(
    child: HabitCard(
      habitWithProgress: PreviewFixtures.sampleHabitWithProgress(
        isCompleted: false,
      ),
      onHabitClick: (_) {},
      onToggleCheckIn: () {},
    ),
  );
}

@PhialMultiBrightnessPreview(name: 'Habit Card - Completed', group: 'Daily')
Widget previewHabitCardCompleted() {
  return PhialPreviewWrapper(
    child: HabitCard(
      habitWithProgress: PreviewFixtures.sampleHabitWithProgress(
        isCompleted: true,
      ),
      onHabitClick: (_) {},
      onToggleCheckIn: () {},
    ),
  );
}

@Preview(name: 'Habit Card - Shielded', group: 'Daily')
Widget previewHabitCardShielded() {
  return PhialPreviewWrapper(
    child: HabitCard(
      habitWithProgress: PreviewFixtures.sampleHabitWithProgress(
        isShielded: true,
      ),
      onHabitClick: (_) {},
      onToggleCheckIn: () {},
    ),
  );
}

@Preview(name: 'Habit Card - Pinned Numeric', group: 'Daily')
Widget previewHabitCardPinnedNumeric() {
  return PhialPreviewWrapper(
    child: HabitCard(
      habitWithProgress: PreviewFixtures.sampleHabitWithProgress(
        habit: PreviewFixtures.sampleHabit(
          title: 'Drink Water',
          targetType: HabitTargetType.numeric,
          targetValue: 2500,
          unit: 'ml',
          pinned: true,
          color: '#06B6D4',
          icon: 'water_drop',
        ),
        currentValue: 1250,
      ),
      onHabitClick: (_) {},
      onToggleCheckIn: () {},
    ),
  );
}
