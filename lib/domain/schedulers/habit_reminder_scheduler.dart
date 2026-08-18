import '../models/habit.dart';

abstract class HabitReminderScheduler {
  Future<void> schedule(Habit habit);
  Future<void> cancel(String habitId);
  Future<void> rescheduleAll();
}
