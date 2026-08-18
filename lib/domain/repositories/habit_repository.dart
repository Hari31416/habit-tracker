import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/habit_log.dart';

abstract class HabitRepository {
  // Habits
  Stream<List<Habit>> getAllHabits();
  Stream<List<Habit>> getActiveHabits();
  Stream<List<Habit>> getArchivedHabits();
  Stream<List<Habit>> getPinnedHabits();
  Stream<Habit?> getHabitById(String id);
  Future<Habit?> getHabitByIdOnce(String id);
  Stream<List<Habit>> getHabitsByCategory(String categoryId);
  Future<void> upsertHabit(Habit habit);
  Future<void> deleteHabit(Habit habit);
  Future<void> setPinned(String id, bool pinned);
  Future<void> setArchived(String id, bool archived);

  // Logs
  Stream<List<HabitLog>> getLogsForHabit(String habitId);
  Future<List<HabitLog>> getLogsForHabitOnce(String habitId);
  Stream<List<HabitLog>> getLogsForDate(DateTime date);
  Future<List<HabitLog>> getLogsForDateOnce(DateTime date);
  Stream<List<HabitLog>> getLogsForHabitAndDate(String habitId, DateTime date);
  Stream<List<HabitLog>> getLogsForDateRange(DateTime startDate, DateTime endDate);
  Future<List<HabitLog>> getLogsForDateRangeOnce(DateTime startDate, DateTime endDate);
  Stream<List<HabitLog>> getAllLogs();
  Future<List<HabitLog>> getAllLogsOnce();
  Future<void> logCheckIn({
    required String habitId,
    required DateTime date,
    required bool completed,
    double? value,
    int? durationSeconds,
    int? intervalIndex,
    String? note,
  });
  Future<void> toggleBooleanCheckIn(String habitId, DateTime date);
  Future<void> updateNumericValue(String habitId, DateTime date, double value);
  Future<void> addNumericDelta(String habitId, DateTime date, double delta);
  Future<void> toggleSlotCheckIn(String habitId, DateTime date, int slotIndex);
  Future<void> deleteLogsForHabitAndDate(String habitId, DateTime date);

  // Categories
  Stream<List<HabitCategory>> getAllCategories();
  Future<List<HabitCategory>> getAllCategoriesOnce();
  Stream<HabitCategory?> getCategoryById(String id);
  Future<void> upsertCategory(HabitCategory category);
  Future<void> deleteCategory(HabitCategory category);
}
