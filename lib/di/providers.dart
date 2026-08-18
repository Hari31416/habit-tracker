import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/background/day_rollover_task.dart';
import '../data/local/app_database.dart';
import '../data/local/daos/gamification_dao.dart';
import '../data/local/daos/habit_category_dao.dart';
import '../data/local/daos/habit_dao.dart';
import '../data/local/daos/habit_log_dao.dart';
import '../data/repositories/gamification_repository_impl.dart';
import '../data/repositories/habit_repository_impl.dart';
import '../data/schedulers/flutter_habit_reminder_scheduler.dart';
import '../data/schedulers/local_notifications_scheduler.dart';
import '../data/schedulers/notification_action_handler.dart';
import '../domain/repositories/gamification_repository.dart';
import '../domain/repositories/habit_repository.dart';
import '../domain/schedulers/habit_reminder_scheduler.dart';
import '../services/app_shortcuts_service.dart';
import '../services/focus_timer_background_service.dart';
import '../services/widget_sync_service.dart';

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
  final habitDao = ref.watch(habitDaoProvider);
  return FlutterHabitReminderScheduler(habitDao);
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

final localNotificationsSchedulerProvider =
    Provider<LocalNotificationsScheduler>((ref) {
  final repo = ref.watch(habitRepositoryProvider);
  return LocalNotificationsScheduler(repo);
});

final widgetSyncServiceProvider = Provider<WidgetSyncService>((ref) {
  final habitRepo = ref.watch(habitRepositoryProvider);
  final gamificationRepo = ref.watch(gamificationRepositoryProvider);
  return WidgetSyncService(habitRepo, gamificationRepo);
});

final notificationActionHandlerProvider =
    Provider<NotificationActionHandler>((ref) {
  final habitRepo = ref.watch(habitRepositoryProvider);
  final widgetSync = ref.watch(widgetSyncServiceProvider);
  final reminderScheduler = ref.watch(habitReminderSchedulerProvider);
  return NotificationActionHandler(habitRepo, widgetSync, reminderScheduler);
});

final dayRolloverTaskProvider = Provider<DayRolloverTask>((ref) {
  final widgetSync = ref.watch(widgetSyncServiceProvider);
  return DayRolloverTask(widgetSync);
});

final appShortcutsServiceProvider = Provider<AppShortcutsService>((ref) {
  final habitRepo = ref.watch(habitRepositoryProvider);
  return AppShortcutsService(habitRepo);
});

final focusTimerBackgroundServiceProvider =
    Provider<FocusTimerBackgroundService>((ref) {
  final habitRepo = ref.watch(habitRepositoryProvider);
  final widgetSync = ref.watch(widgetSyncServiceProvider);
  final service = FocusTimerBackgroundService(habitRepo, widgetSync);
  ref.onDispose(() => service.dispose());
  return service;
});
