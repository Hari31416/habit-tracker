import '../../domain/models/habit_target_type.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/schedulers/habit_reminder_scheduler.dart';
import '../../services/widget_sync_service.dart';
import 'notification_channel_handler.dart';

class NotificationActionHandler {
  final HabitRepository _repository;
  final WidgetSyncService? _widgetSyncService;
  final HabitReminderScheduler? _reminderScheduler;

  NotificationActionHandler(
    this._repository, [
    this._widgetSyncService,
    this._reminderScheduler,
  ]);

  @pragma('vm:entry-point')
  Future<void> handleAction({
    required String action,
    required String habitId,
    double? delta,
    DateTime? date,
  }) async {
    final today = date ?? DateTime.now();
    final habit = await _repository.getHabitByIdOnce(habitId);

    switch (action) {
      case NotificationPayload.actionMarkDone:
        if (habit != null) {
          switch (habit.targetType) {
            case HabitTargetType.boolean:
              await _repository.toggleBooleanCheckIn(habitId, today);
              break;
            case HabitTargetType.numeric:
            case HabitTargetType.timer:
              await _repository.updateNumericValue(
                habitId,
                today,
                habit.targetValue ?? 1.0,
              );
              break;
          }
        } else {
          await _repository.toggleBooleanCheckIn(habitId, today);
        }
        break;

      case NotificationPayload.actionAddDelta:
        final amount = delta ?? 1.0;
        await _repository.addNumericDelta(habitId, today, amount);
        break;
    }

    await _widgetSyncService?.syncAllWidgets();

    // Reschedule the next notification for this habit
    // (mirrors Kotlin HabitReminderReceiver.onReceive calling scheduler.schedule)
    if (habit != null) {
      await _reminderScheduler?.schedule(habit);
    }
  }
}

