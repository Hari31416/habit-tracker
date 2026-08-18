import '../../domain/repositories/habit_repository.dart';
import '../../services/widget_sync_service.dart';

class DayRolloverTask {
  static const String uniqueWorkName = 'habit_day_rollover';

  final WidgetSyncService _widgetSyncService;
  final HabitRepository? _habitRepository;

  DayRolloverTask(
    this._widgetSyncService, [
    this._habitRepository,
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

  @pragma('vm:entry-point')
  Future<bool> executeRollover([DateTime? rolloverDate]) async {
    try {
      final date = rolloverDate ?? DateTime.now();
      final yesterday = date.subtract(const Duration(days: 1));
      
      // Auto-protect any uncompleted active habits for yesterday if shields are available
      await _habitRepository?.autoProtectMissedDays(yesterday);
      
      await _widgetSyncService.syncAllWidgets(date);
      return true;
    } catch (_) {
      return false;
    }
  }
}
