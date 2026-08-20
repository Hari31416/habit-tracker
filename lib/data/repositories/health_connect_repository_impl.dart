import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/engines/health_sync_engine.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/models/health/health_connect_models.dart';
import '../../domain/models/health/health_metric_type.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/repositories/health_connect_repository.dart';
import '../../services/app_logger.dart';
import '../../services/health_connect_service.dart';
import '../../services/widget_sync_service.dart';

/// Implementation of HealthConnectRepository coordinating Health Connect queries,
/// domain calculations, and local database log synchronization.
class HealthConnectRepositoryImpl implements HealthConnectRepository {
  static const String lastSyncTimeKey = 'health_connect_last_sync_time';

  final HealthConnectService service;
  final HabitRepository habitRepository;
  final WidgetSyncService? widgetSyncService;
  final HealthSyncEngine engine;
  final SharedPreferences? sharedPreferences;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  HealthConnectRepositoryImpl({
    required this.service,
    required this.habitRepository,
    this.widgetSyncService,
    this.engine = const HealthSyncEngine(),
    this.sharedPreferences,
  });

  @override
  Future<HealthConnectStatus> checkAvailability() => service.checkAvailability();

  @override
  Future<bool> openHealthConnectInstall() => service.openHealthConnectInstall();

  @override
  Future<bool> hasPermissions(List<HealthMetricType> metrics) => service.hasPermissions(metrics);

  @override
  Future<bool> requestPermissions(List<HealthMetricType> metrics) =>
      service.requestPermissions(metrics);

  @override
  Future<DailyHealthMetrics?> getDailyMetrics(DateTime date) async {
    final dateStr = _dateFormat.format(date);
    final allHabits = await habitRepository.getActiveHabits().first;
    final neededMetrics = allHabits
        .where((h) => h.healthSyncEnabled && h.healthMetric != null)
        .map((h) => h.healthMetric!)
        .toSet()
        .toList();

    if (neededMetrics.isEmpty) {
      neededMetrics.addAll(HealthMetricType.values);
    }

    return service.getDailyMetrics(dateStr, neededMetrics);
  }

  @override
  Future<List<DailyHealthMetrics>> getMetricsRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startStr = _dateFormat.format(startDate);
    final endStr = _dateFormat.format(endDate);
    final allHabits = await habitRepository.getActiveHabits().first;
    final neededMetrics = allHabits
        .where((h) => h.healthSyncEnabled && h.healthMetric != null)
        .map((h) => h.healthMetric!)
        .toSet()
        .toList();

    if (neededMetrics.isEmpty) {
      neededMetrics.addAll(HealthMetricType.values);
    }

    return service.getMetricsRange(startStr, endStr, neededMetrics);
  }

  @override
  Future<HealthSyncSummary> syncHabitsForDate([DateTime? date]) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = _dateFormat.format(targetDate);

    try {
      final allHabits = await habitRepository.getActiveHabits().first;
      final eligibleHabits = allHabits
          .where((h) => h.healthSyncEnabled && h.healthMetric != null && !h.archived)
          .toList();

      if (eligibleHabits.isEmpty) {
        return HealthSyncSummary(
          syncTime: DateTime.now(),
          habitsChecked: 0,
          habitsUpdated: 0,
          habitsCompleted: 0,
        );
      }

      final neededMetrics = eligibleHabits.map((h) => h.healthMetric!).toSet().toList();
      final metrics = await service.getDailyMetrics(dateStr, neededMetrics);

      if (metrics == null) {
        return HealthSyncSummary(
          syncTime: DateTime.now(),
          habitsChecked: eligibleHabits.length,
          habitsUpdated: 0,
          habitsCompleted: 0,
        );
      }

      // Collect existing logs for eligible habits
      final logsByHabit = <String, List<HabitLog>>{};
      for (final habit in eligibleHabits) {
        final logs = await habitRepository.getLogsForHabitAndDate(habit.id, targetDate).first;
        logsByHabit[habit.id] = logs;
      }

      final updates = engine.evaluateAll(
        habits: eligibleHabits,
        metrics: metrics,
        logsByHabit: logsByHabit,
      );

      var updatedCount = 0;
      var newlyCompletedCount = 0;
      final updatedTitles = <String>[];

      for (final update in updates) {
        if (update.shouldUpdate) {
          await habitRepository.updateNumericValue(
            update.habit.id,
            targetDate,
            update.syncValue,
          );
          updatedCount++;
          updatedTitles.add(update.habit.title);
          if (update.wasNewlyCompleted) {
            newlyCompletedCount++;
          }
        }
      }

      if (updatedCount > 0) {
        await widgetSyncService?.syncAllWidgetsImmediate(targetDate);
      }

      final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
      await prefs.setString(lastSyncTimeKey, DateTime.now().toUtc().toIso8601String());

      return HealthSyncSummary(
        syncTime: DateTime.now(),
        habitsChecked: eligibleHabits.length,
        habitsUpdated: updatedCount,
        habitsCompleted: newlyCompletedCount,
        updatedHabitTitles: updatedTitles,
      );
    } catch (e, stack) {
      AppLogger.w('syncHabitsForDate error for $dateStr', error: e, stackTrace: stack);
      return HealthSyncSummary.error(e.toString());
    }
  }

  @override
  Future<HealthSyncSummary> syncRecentDays({int days = 3}) async {
    final now = DateTime.now();
    var totalChecked = 0;
    var totalUpdated = 0;
    var totalCompleted = 0;
    final allUpdatedTitles = <String>{};

    for (var i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final summary = await syncHabitsForDate(date);
      if (summary.isSuccess) {
        totalChecked += summary.habitsChecked;
        totalUpdated += summary.habitsUpdated;
        totalCompleted += summary.habitsCompleted;
        allUpdatedTitles.addAll(summary.updatedHabitTitles);
      }
    }

    return HealthSyncSummary(
      syncTime: DateTime.now(),
      habitsChecked: totalChecked,
      habitsUpdated: totalUpdated,
      habitsCompleted: totalCompleted,
      updatedHabitTitles: allUpdatedTitles.toList(),
    );
  }

  @override
  Future<bool> scheduleBackgroundSync({int intervalMinutes = 30}) =>
      service.schedulePeriodicSync(intervalMinutes: intervalMinutes);

  @override
  Future<bool> cancelBackgroundSync() => service.cancelPeriodicSync();

  @override
  Future<DateTime?> getLastSyncTime() async {
    final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
    final str = prefs.getString(lastSyncTimeKey);
    if (str == null || str.isEmpty) return null;
    try {
      return DateTime.parse(str).toLocal();
    } catch (_) {
      return null;
    }
  }
}
