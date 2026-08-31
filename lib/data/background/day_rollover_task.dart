import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/habit_repository.dart';
import '../../services/widget_sync_service.dart';
import '../local/app_database.dart';
import '../repositories/gamification_repository_impl.dart';
import '../repositories/habit_repository_impl.dart';
import '../schedulers/no_op_habit_reminder_scheduler.dart';

/// Top-level background entry point for executing day rollover
/// from background alarms / workers.
@pragma('vm:entry-point')
Future<bool> executeBackgroundDayRollover([DateTime? rolloverDate]) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    final db = AppDatabase.backgroundInstance();
    final habitRepo = HabitRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
    );
    final gamificationRepo = GamificationRepositoryImpl(
      gamificationDao: db.gamificationDao,
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      routineDao: db.routineDao,
    );
    final widgetSync = WidgetSyncService(habitRepo, gamificationRepo);
    final prefs = await SharedPreferences.getInstance();
    final task = DayRolloverTask(widgetSync, habitRepo, prefs);
    final result = await task.executeRollover(rolloverDate);
    await db.close();
    return result;
  } catch (e, stack) {
    debugPrint('Background day rollover failed: $e\n$stack');
    return false;
  }
}

class DayRolloverTask {
  static const String uniqueWorkName = 'habit_day_rollover';
  static const String lastRolloverDateKey = 'last_rollover_date';

  final WidgetSyncService _widgetSyncService;
  final HabitRepository? _habitRepository;
  final SharedPreferences? _sharedPreferences;

  DayRolloverTask(
    this._widgetSyncService, [
    this._habitRepository,
    this._sharedPreferences,
  ]);

  static Duration calculateDelayToNextMidnight([DateTime? referenceDateTime]) {
    final now = referenceDateTime ?? DateTime.now();
    final tomorrowMidnightPlusOne = DateTime(
      now.year,
      now.month,
      now.day + 1,
      0,
      1,
    );
    final difference = tomorrowMidnightPlusOne.difference(now);
    return difference.isNegative ? const Duration(minutes: 1) : difference;
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @pragma('vm:entry-point')
  Future<bool> executeRollover([DateTime? rolloverDate]) async {
    try {
      final date = rolloverDate ?? DateTime.now();
      final todayStr = _formatDate(date);

      final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
      final lastRollover = prefs.getString(lastRolloverDateKey);

      if (lastRollover == todayStr) {
        // Rollover already completed for today
        return true;
      }

      final yesterday = DateTime(date.year, date.month, date.day).subtract(const Duration(days: 1));

      if (lastRollover != null) {
        final parts = lastRollover.split('-');
        if (parts.length == 3) {
          final lastDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          var current = lastDate;
          int iterations = 0;
          while (!current.isAfter(yesterday) && iterations < 30) {
            await _habitRepository?.autoProtectMissedDays(current);
            current = current.add(const Duration(days: 1));
            iterations++;
          }
        } else {
          await _habitRepository?.autoProtectMissedDays(yesterday);
        }
      } else {
        await _habitRepository?.autoProtectMissedDays(yesterday);
      }

      await _widgetSyncService.syncAllWidgets(date);
      await prefs.setString(lastRolloverDateKey, todayStr);
      return true;
    } catch (e, stack) {
      debugPrint('Day rollover task error: $e\n$stack');
      return false;
    }
  }
}
