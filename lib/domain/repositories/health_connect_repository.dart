import '../models/health/health_connect_models.dart';
import '../models/health/health_metric_type.dart';

/// Repository interface for interacting with Google Health Connect
/// and synchronizing physical habit metrics.
abstract class HealthConnectRepository {
  /// Checks availability of Google Health Connect on this device.
  Future<HealthConnectStatus> checkAvailability();

  /// Opens Google Play Store to install Health Connect if needed.
  Future<bool> openHealthConnectInstall();

  /// Checks if permissions have been granted for the specified metric types.
  Future<bool> hasPermissions(List<HealthMetricType> metrics);

  /// Requests permission from the user for the specified metric types.
  Future<bool> requestPermissions(List<HealthMetricType> metrics);

  /// Fetches daily health metrics for a specific date (YYYY-MM-DD).
  Future<DailyHealthMetrics?> getDailyMetrics(DateTime date);

  /// Fetches daily health metrics across a date range.
  Future<List<DailyHealthMetrics>> getMetricsRange(DateTime startDate, DateTime endDate);

  /// Synchronizes all active health-enabled habits for a given date (defaults to today).
  Future<HealthSyncSummary> syncHabitsForDate([DateTime? date]);

  /// Synchronizes all active health-enabled habits across recent days (e.g. past 7 days).
  Future<HealthSyncSummary> syncRecentDays({int days = 3});

  /// Schedules periodic background synchronization via Android WorkManager.
  Future<bool> scheduleBackgroundSync({int intervalMinutes = 30});

  /// Cancels periodic background synchronization.
  Future<bool> cancelBackgroundSync();

  /// Gets the timestamp of the last successful health synchronization.
  Future<DateTime?> getLastSyncTime();
}
