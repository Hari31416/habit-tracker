import 'package:flutter/services.dart';
import '../domain/models/health/health_connect_models.dart';
import '../domain/models/health/health_metric_type.dart';
import 'app_logger.dart';

/// Platform channel bridge between Flutter and native Android Health Connect.
class HealthConnectService {
  static const MethodChannel _channel = MethodChannel('app.phial.habits/health_connect');

  const HealthConnectService();

  /// Checks if Google Health Connect is supported and available on this device.
  Future<HealthConnectStatus> checkAvailability() async {
    try {
      final result = await _channel.invokeMethod<String>('checkAvailability');
      return HealthConnectStatus.fromString(result);
    } catch (e, stack) {
      AppLogger.w('HealthConnectService.checkAvailability error', error: e, stackTrace: stack);
      return HealthConnectStatus.notSupported;
    }
  }

  /// Opens Google Play Store to install Health Connect.
  Future<bool> openHealthConnectInstall() async {
    try {
      final result = await _channel.invokeMethod<bool>('openHealthConnectInstall');
      return result ?? false;
    } catch (e, stack) {
      AppLogger.w('HealthConnectService.openHealthConnectInstall error', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Checks if permissions have been granted for the requested health metrics.
  Future<bool> hasPermissions(List<HealthMetricType> metrics) async {
    try {
      final metricIds = metrics.map((m) => m.id).toList();
      final result = await _channel.invokeMethod<bool>(
        'checkPermissions',
        {'metrics': metricIds},
      );
      return result ?? false;
    } catch (e, stack) {
      AppLogger.w('HealthConnectService.hasPermissions error', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Requests user authorization for the specified health metrics.
  Future<bool> requestPermissions(List<HealthMetricType> metrics) async {
    try {
      final metricIds = metrics.map((m) => m.id).toList();
      final result = await _channel.invokeMethod<bool>(
        'requestPermissions',
        {'metrics': metricIds},
      );
      return result ?? false;
    } catch (e, stack) {
      AppLogger.w('HealthConnectService.requestPermissions error', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Queries aggregated daily metrics from Health Connect for a specific date.
  Future<DailyHealthMetrics?> getDailyMetrics(
    String dateStr,
    List<HealthMetricType> metrics,
  ) async {
    try {
      final metricIds = metrics.map((m) => m.id).toList();
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getDailyMetrics',
        {
          'date': dateStr,
          'metrics': metricIds,
        },
      );
      if (result == null) return null;
      return DailyHealthMetrics.fromMap(dateStr, result);
    } catch (e, stack) {
      AppLogger.w('HealthConnectService.getDailyMetrics error for $dateStr', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Queries daily metrics across a range of dates.
  Future<List<DailyHealthMetrics>> getMetricsRange(
    String startDateStr,
    String endDateStr,
    List<HealthMetricType> metrics,
  ) async {
    try {
      final metricIds = metrics.map((m) => m.id).toList();
      final result = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'getMetricRange',
        {
          'startDate': startDateStr,
          'endDate': endDateStr,
          'metrics': metricIds,
        },
      );
      if (result == null) return [];

      return result.map((item) {
        final map = Map<String, dynamic>.from(item);
        final date = map['date']?.toString() ?? startDateStr;
        return DailyHealthMetrics.fromMap(date, map);
      }).toList();
    } catch (e, stack) {
      AppLogger.w('HealthConnectService.getMetricsRange error', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Schedules periodic background health sync via Android WorkManager.
  Future<bool> schedulePeriodicSync({int intervalMinutes = 30}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'schedulePeriodicSync',
        {'intervalMinutes': intervalMinutes},
      );
      return result ?? false;
    } catch (e, stack) {
      AppLogger.w('HealthConnectService.schedulePeriodicSync error', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Cancels periodic background sync.
  Future<bool> cancelPeriodicSync() async {
    try {
      final result = await _channel.invokeMethod<bool>('cancelPeriodicSync');
      return result ?? false;
    } catch (e, stack) {
      AppLogger.w('HealthConnectService.cancelPeriodicSync error', error: e, stackTrace: stack);
      return false;
    }
  }
}
