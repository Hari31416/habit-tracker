import '../../domain/engines/dynamic_step_engine.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_target_type.dart';

class NotificationActionPayload {
  final String actionId;
  final String label;
  final String habitId;
  final double? delta;

  const NotificationActionPayload({
    required this.actionId,
    required this.label,
    required this.habitId,
    this.delta,
  });
}

class NotificationPayload {
  static const String channelId = 'habit_reminders';
  static const String channelName = 'Habit Reminders';
  static const String channelDescription =
      'Timely reminders to complete your scheduled habits';

  static const String actionMarkDone =
      'app.phial.habits.ACTION_MARK_DONE';
  static const String actionAddDelta =
      'app.phial.habits.ACTION_ADD_DELTA';
  static const String actionViewHabit =
      'app.phial.habits.ACTION_VIEW_HABIT';

  final int notificationId;
  final String title;
  final String body;
  final String deepLinkUri;
  final List<NotificationActionPayload> actions;

  const NotificationPayload({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.deepLinkUri,
    required this.actions,
  });

  /// Android notification IDs must fit in a signed 32-bit int, and the plugin
  /// multiplies the id by 16 for action request codes.
  static int requestCodeFor(String habitId, int reminderIndex) {
    return ((habitId.hashCode * 31) + reminderIndex).toSigned(32) & 0x0FFFFFFF;
  }

  static NotificationPayload buildNotification(
    Habit habit,
    int reminderIndex,
  ) {
    final notificationId = requestCodeFor(habit.id, reminderIndex);
    final deepLinkUri = 'phial://habits/detail/${habit.id}';
    final actions = <NotificationActionPayload>[];
    String bodyText;

    switch (habit.targetType) {
      case HabitTargetType.boolean:
        bodyText = 'Ready for your daily check-in?';
        actions.add(
          NotificationActionPayload(
            actionId: actionMarkDone,
            label: 'Check-In',
            habitId: habit.id,
          ),
        );
        actions.add(
          NotificationActionPayload(
            actionId: actionViewHabit,
            label: 'View Habit',
            habitId: habit.id,
          ),
        );
        break;

      case HabitTargetType.numeric:
        final stepConfig = DynamicStepEngine.getDynamicStepConfig(
          habit.targetValue ?? 1.0,
          habit.unit,
        );
        final primaryStep = stepConfig.primaryStep;
        final stepText = primaryStep % 1.0 == 0.0
            ? '${primaryStep.toInt()}'
            : '$primaryStep';
        final unitSuffix =
            habit.unit != null && habit.unit!.isNotEmpty ? ' ${habit.unit}' : '';
        final stepLabel = '+$stepText$unitSuffix';

        bodyText = 'Log progress ($stepLabel) toward daily goal.';
        actions.add(
          NotificationActionPayload(
            actionId: actionMarkDone,
            label: 'Mark Done',
            habitId: habit.id,
          ),
        );
        actions.add(
          NotificationActionPayload(
            actionId: actionAddDelta,
            label: 'Log Progress',
            habitId: habit.id,
            delta: primaryStep,
          ),
        );
        actions.add(
          NotificationActionPayload(
            actionId: actionViewHabit,
            label: 'View Habit',
            habitId: habit.id,
          ),
        );
        break;

      case HabitTargetType.timer:
        final timerConfig = DynamicStepEngine.getDynamicTimerConfig(
          habit.targetValue ?? 25.0,
        );
        final primaryStep = timerConfig.primaryStep;
        final stepLabel = '+${primaryStep.toInt()} min';

        bodyText = 'Log progress ($stepLabel) toward daily goal.';
        actions.add(
          NotificationActionPayload(
            actionId: actionMarkDone,
            label: 'Mark Done',
            habitId: habit.id,
          ),
        );
        actions.add(
          NotificationActionPayload(
            actionId: actionAddDelta,
            label: 'Log Progress',
            habitId: habit.id,
            delta: primaryStep,
          ),
        );
        actions.add(
          NotificationActionPayload(
            actionId: actionViewHabit,
            label: 'View Habit',
            habitId: habit.id,
          ),
        );
        break;
    }

    return NotificationPayload(
      notificationId: notificationId,
      title: habit.title,
      body: bodyText,
      deepLinkUri: deepLinkUri,
      actions: actions,
    );
  }
}
