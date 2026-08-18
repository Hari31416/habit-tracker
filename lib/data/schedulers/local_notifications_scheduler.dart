import 'package:intl/intl.dart';
import '../../domain/engines/streak_calculator.dart';
import '../../domain/models/habit.dart';
import '../../domain/repositories/habit_repository.dart';

class ScheduledNotificationItem {
  final String habitId;
  final String habitTitle;
  final String color;
  final String icon;
  final int reminderIndex;
  final DateTime triggerDateTime;
  final int requestCode;

  const ScheduledNotificationItem({
    required this.habitId,
    required this.habitTitle,
    required this.color,
    required this.icon,
    required this.reminderIndex,
    required this.triggerDateTime,
    required this.requestCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledNotificationItem &&
          runtimeType == other.runtimeType &&
          habitId == other.habitId &&
          reminderIndex == other.reminderIndex &&
          requestCode == other.requestCode;

  @override
  int get hashCode =>
      habitId.hashCode ^ reminderIndex.hashCode ^ requestCode.hashCode;
}

class LocalNotificationsScheduler {
  final HabitRepository _repository;
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  // In-memory registry of scheduled notifications for testability and platform bridging
  final Map<String, List<ScheduledNotificationItem>> _scheduledItems = {};

  LocalNotificationsScheduler(this._repository);

  Map<String, List<ScheduledNotificationItem>> get scheduledItems =>
      Map.unmodifiable(_scheduledItems);

  Future<void> schedule(Habit habit) async {
    cancel(habit.id);

    if (habit.archived || habit.reminderTimes.isEmpty) {
      return;
    }

    final items = <ScheduledNotificationItem>[];

    for (int index = 0; index < habit.reminderTimes.length; index++) {
      final timeStr = habit.reminderTimes[index];
      final parsedTime = _parseTime(timeStr);
      if (parsedTime == null) continue;

      final nextDateTime = calculateNextOccurrence(
        habit,
        parsedTime,
        DateTime.now(),
      );

      final requestCode = generateRequestCode(habit.id, index);
      final item = ScheduledNotificationItem(
        habitId: habit.id,
        habitTitle: habit.title,
        color: habit.color,
        icon: habit.icon ?? 'check',
        reminderIndex: index,
        triggerDateTime: nextDateTime,
        requestCode: requestCode,
      );

      items.add(item);
    }

    _scheduledItems[habit.id] = items;
  }

  void cancel(String habitId) {
    _scheduledItems.remove(habitId);
  }

  Future<void> rescheduleAll() async {
    _scheduledItems.clear();
    final activeHabits = await _repository.getActiveHabits().first;
    for (final habit in activeHabits) {
      await schedule(habit);
    }
  }

  DateTime calculateNextOccurrence(
    Habit habit,
    DateTime reminderTime, [
    DateTime? referenceDateTime,
  ]) {
    final ref = referenceDateTime ?? DateTime.now();
    DateTime candidateDate = DateTime(ref.year, ref.month, ref.day);

    // If today's reminder time has already passed, start checking from tomorrow
    final refTimeInMinutes = ref.hour * 60 + ref.minute;
    final remTimeInMinutes = reminderTime.hour * 60 + reminderTime.minute;

    if (refTimeInMinutes >= remTimeInMinutes) {
      candidateDate = candidateDate.add(const Duration(days: 1));
    }

    // Find next date when habit is scheduled (up to 14 days)
    for (int i = 0; i < 14; i++) {
      final checkDate = candidateDate.add(Duration(days: i));
      if (StreakCalculator.isHabitScheduledOnDate(habit, checkDate)) {
        return DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          reminderTime.hour,
          reminderTime.minute,
        );
      }
    }

    return DateTime(
      candidateDate.year,
      candidateDate.month,
      candidateDate.day,
      reminderTime.hour,
      reminderTime.minute,
    );
  }

  DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length < 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  int generateRequestCode(String habitId, int reminderIndex) {
    return ((habitId.hashCode * 31) + reminderIndex).abs();
  }
}
