import 'package:drift/native.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/backup_repository_impl.dart';
import 'package:habit_tracker/data/repositories/gamification_repository_impl.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/no_op_habit_reminder_scheduler.dart';

/// Shared in-memory Drift + real repositories for journey tests.
class JourneyHarness {
  late final AppDatabase db;
  late final HabitRepositoryImpl habits;
  late final GamificationRepositoryImpl gamification;
  late final BackupRepositoryImpl backup;

  Future<void> setUp({DateTime Function()? clock}) async {
    db = AppDatabase(NativeDatabase.memory());
    habits = HabitRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
    );
    gamification = GamificationRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
    );
    backup = BackupRepositoryImpl(
      db: db,
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
      clock: clock,
    );
  }

  Future<void> tearDown() => db.close();

  /// Calendar day at local midnight (matches StreakCalculator / repo date keys).
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
}
