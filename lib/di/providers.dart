import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/app_database.dart';
import '../data/local/daos/gamification_dao.dart';
import '../data/local/daos/habit_category_dao.dart';
import '../data/local/daos/habit_dao.dart';
import '../data/local/daos/habit_log_dao.dart';
import '../data/repositories/gamification_repository_impl.dart';
import '../data/repositories/habit_repository_impl.dart';
import '../data/schedulers/no_op_habit_reminder_scheduler.dart';
import '../domain/repositories/gamification_repository.dart';
import '../domain/repositories/habit_repository.dart';
import '../domain/schedulers/habit_reminder_scheduler.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final habitDaoProvider = Provider<HabitDao>((ref) {
  return ref.watch(databaseProvider).habitDao;
});

final habitLogDaoProvider = Provider<HabitLogDao>((ref) {
  return ref.watch(databaseProvider).habitLogDao;
});

final habitCategoryDaoProvider = Provider<HabitCategoryDao>((ref) {
  return ref.watch(databaseProvider).habitCategoryDao;
});

final gamificationDaoProvider = Provider<GamificationDao>((ref) {
  return ref.watch(databaseProvider).gamificationDao;
});

final habitReminderSchedulerProvider = Provider<HabitReminderScheduler>((ref) {
  return const NoOpHabitReminderScheduler();
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepositoryImpl(
    habitDao: ref.watch(habitDaoProvider),
    habitLogDao: ref.watch(habitLogDaoProvider),
    habitCategoryDao: ref.watch(habitCategoryDaoProvider),
    reminderScheduler: ref.watch(habitReminderSchedulerProvider),
  );
});

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepositoryImpl(
    habitDao: ref.watch(habitDaoProvider),
    habitLogDao: ref.watch(habitLogDaoProvider),
    habitCategoryDao: ref.watch(habitCategoryDaoProvider),
    gamificationDao: ref.watch(gamificationDaoProvider),
  );
});
