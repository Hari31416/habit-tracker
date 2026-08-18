import '../../domain/models/habit.dart';
import '../../domain/schedulers/habit_reminder_scheduler.dart';

class NoOpHabitReminderScheduler implements HabitReminderScheduler {
  const NoOpHabitReminderScheduler();

  @override
  Future<void> schedule(Habit habit, {bool catchUpIfDue = false}) async {
    // No-op for Phases 1-4. Wired to Local Notifications & WorkManager in Phase 5.
  }

  @override
  Future<void> cancel(String habitId) async {
    // No-op for Phases 1-4. Wired to Local Notifications & WorkManager in Phase 5.
  }

  @override
  Future<void> rescheduleAll() async {
    // No-op for Phases 1-4. Wired to Local Notifications & WorkManager in Phase 5.
  }
}
