import 'dart:developer' as developer;

/// Lightweight logging utility for the Habit Tracker application.
class AppLogger {
  static const String _defaultTag = 'HabitTracker';

  /// Log informational messages.
  static void i(String message, {String tag = _defaultTag}) {
    developer.log(message, name: tag, level: 800);
  }

  /// Log warning messages with optional error and stack trace.
  static void w(
    String message, {
    String tag = _defaultTag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error messages with optional error and stack trace.
  static void e(
    String message, {
    String tag = _defaultTag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
