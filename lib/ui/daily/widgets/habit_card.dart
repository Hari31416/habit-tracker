import 'package:flutter/material.dart';
import '../../../domain/engines/streak_calculator.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../../domain/models/habit_target_type.dart';
import '../../../domain/models/habit_with_progress.dart';
import '../../common/color_utils.dart';
import '../../common/habit_icon_registry.dart';
import '../../common/haptics_helper.dart';

class HabitCard extends StatelessWidget {
  final HabitWithProgress habitWithProgress;
  final ValueChanged<String> onHabitClick;
  final VoidCallback onToggleCheckIn;
  final ValueChanged<double>? onValueChange;
  final ValueChanged<double>? onDeltaAdd;
  final ValueChanged<int>? onToggleSlot;
  final VoidCallback? onTogglePin;
  final VoidCallback? onStartFocus;

  const HabitCard({
    super.key,
    required this.habitWithProgress,
    required this.onHabitClick,
    required this.onToggleCheckIn,
    this.onValueChange,
    this.onDeltaAdd,
    this.onToggleSlot,
    this.onTogglePin,
    this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = habitWithProgress.habit;
    final category = habitWithProgress.category;
    final isCompleted = habitWithProgress.isCompletedOnDate;
    final streak = habitWithProgress.streak;

    final habitColor = ColorUtils.parseHexColor(habit.color);
    final iconData = HabitIconRegistry.getIcon(habit.icon);
    final outlineVariant = theme.colorScheme.outlineVariant;

    final streakUnit =
        habit.frequencyType == HabitFrequencyType.weekly ? 'wks' : 'd';
    final streakLabel = '${streak.currentStreak} $streakUnit streak';

    final containerColor = isCompleted
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
        : theme.colorScheme.surface;

    final borderColor = habit.pinned
        ? theme.colorScheme.primary.withValues(alpha: 0.3)
        : outlineVariant.withValues(alpha: 0.35);

    return Card(
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
                            if (habit.pinned) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.push_pin,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),

                        // Category / Description
                        _buildCategoryText(theme, habit, category),
                        const SizedBox(height: 2),

                        // Streak or target status
                        _buildStreakOrStatus(theme, habit, streak, streakLabel),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Right Completion Control / Focus Action (Touch target >= 48dp)
                  _buildActionControl(context, theme, habit, isCompleted, habitColor),
                ],
              ),
            ],
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
  ) {
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
    Color habitColor,
  ) {
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
              color: isCompleted ? habitColor : Colors.transparent,
              border: isCompleted
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
                : null,
          ),
        ),
      ),
    );
  }
}
