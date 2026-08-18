import '../models/habit.dart';

abstract class HabitReminderScheduler {
  Future<void> schedule(Habit habit, {bool catchUpIfDue = false});
  Future<void> cancel(String habitId);
  Future<void> rescheduleAll();
}
