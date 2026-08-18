import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/habit.dart';
import '../../domain/models/habit_frequency_type.dart';
import '../../domain/schedulers/habit_reminder_scheduler.dart';
import '../../services/notification_service.dart';
import '../local/daos/habit_dao.dart';
import 'local_notifications_scheduler.dart';
import 'notification_channel_handler.dart';

/// Real implementation of [HabitReminderScheduler] that schedules
/// notifications via [NotificationService] (flutter_local_notifications).
///
/// Mirrors the Kotlin [AlarmHabitReminderScheduler] behavior:
/// - Computes next occurrence per reminder time
/// - Builds notification payload with action buttons
/// - Schedules exact alarms via the platform plugin
///
/// Uses [HabitDao] directly (not HabitRepository) to break the circular
/// dependency, matching the Kotlin pattern where AlarmHabitReminderScheduler
/// takes HabitDao, not HabitRepository.
class FlutterHabitReminderScheduler implements HabitReminderScheduler {
  final HabitDao _habitDao;

  FlutterHabitReminderScheduler(this._habitDao);

  @override
  Future<void> schedule(Habit habit) async {
    // Cancel existing notifications for this habit first
    await cancel(habit.id);

    if (habit.archived || habit.reminderTimes.isEmpty) {
      return;
    }

    // Check if we have notification permission
    final hasPermission = await NotificationService.hasPermission();
    if (!hasPermission) return;

    final now = DateTime.now();
    tz.Location location;
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      location = tz.getLocation(timeZoneName);
    } catch (_) {
      location = tz.local;
    }

    for (int index = 0; index < habit.reminderTimes.length; index++) {
      final timeStr = habit.reminderTimes[index];
      final parsedTime = _parseTime(timeStr);
      if (parsedTime == null) continue;

      final nextDateTime = _calculateNextOccurrence(
        habit,
        parsedTime,
        now,
      );

      final scheduledDate = tz.TZDateTime(
        location,
        nextDateTime.year,
        nextDateTime.month,
        nextDateTime.day,
        nextDateTime.hour,
        nextDateTime.minute,
      );

      // Ensure the scheduled time is in the future
      final tzNow = tz.TZDateTime.now(location);
      if (scheduledDate.isBefore(tzNow)) continue;

      final requestCode = _generateRequestCode(habit.id, index);

      final payload = NotificationPayload.buildNotification(habit, index);

      await NotificationService.scheduleNotification(
        id: requestCode,
        payload: payload,
        scheduledDate: scheduledDate,
      );
    }
  }

  @override
  Future<void> cancel(String habitId) async {
    // Cancel up to 10 possible reminder index slots per habit
    // (same pattern as the Kotlin AlarmHabitReminderScheduler)
    for (int index = 0; index < 10; index++) {
      final requestCode = _generateRequestCode(habitId, index);
      await NotificationService.cancelNotification(requestCode);
    }
  }

  @override
  Future<void> rescheduleAll() async {
    final activeRows = await _habitDao.getActiveHabitsOnce();
    for (final row in activeRows) {
      final habit = _rowToHabit(row);
      await schedule(habit);
    }
  }

  /// Convert a DAO row to a domain Habit for scheduling purposes.
  Habit _rowToHabit(dynamic row) {
    return Habit(
      id: row.id,
      title: row.title,
      description: row.description,
      color: row.color,
      icon: row.icon,
      categoryId: row.categoryId,
      frequencyType: row.frequencyType,
      targetDaysOfWeek: row.targetDaysOfWeek,
      targetCountPerWeek: row.targetCountPerWeek,
      intervalHours: row.intervalHours,
      timesPerDay: row.timesPerDay,
      timeWindow: row.timeWindow,
      targetType: row.targetType,
      targetValue: row.targetValue,
      unit: row.unit,
      pinned: row.pinned,
      reminderTimes: row.reminderTimes,
      motivationNotes: row.motivationNotes,
      archived: row.archived,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Reused from [LocalNotificationsScheduler.calculateNextOccurrence].
  DateTime _calculateNextOccurrence(
    Habit habit,
    DateTime reminderTime, [
    DateTime? referenceDateTime,
  ]) {
    final ref = referenceDateTime ?? DateTime.now();
    DateTime candidateDate = DateTime(ref.year, ref.month, ref.day);

    final refTimeInMinutes = ref.hour * 60 + ref.minute;
    final remTimeInMinutes = reminderTime.hour * 60 + reminderTime.minute;

    if (refTimeInMinutes >= remTimeInMinutes) {
      candidateDate = candidateDate.add(const Duration(days: 1));
    }

    for (int i = 0; i < 14; i++) {
      final checkDate = candidateDate.add(Duration(days: i));
      if (_isHabitScheduledOnDate(habit, checkDate)) {
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

  bool _isHabitScheduledOnDate(Habit habit, DateTime date) {
    switch (habit.frequencyType) {
      case HabitFrequencyType.daily:
      case HabitFrequencyType.timesPerDay:
      case HabitFrequencyType.subdayInterval:
        return true;
      case HabitFrequencyType.weekly:
        return true;
      case HabitFrequencyType.customDays:
        final dow = date.weekday % 7; // 0=Sun, 6=Sat
        return habit.targetDaysOfWeek?.contains(dow) == true;
    }
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

  int _generateRequestCode(String habitId, int reminderIndex) {
    return ((habitId.hashCode * 31) + reminderIndex).abs();
  }
}
