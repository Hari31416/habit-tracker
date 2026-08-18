import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../../domain/models/habit_target_type.dart';
import '../../../domain/models/time_window.dart';

class IntListConverter extends TypeConverter<List<int>, String> {
  const IntListConverter();

  @override
  List<int> fromSql(String fromDb) {
    if (fromDb.trim().isEmpty) return const [];
    try {
      return fromDb
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map(int.parse)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  String toSql(List<int> value) {
    return value.join(',');
  }
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.trim().isEmpty) return const [];
    try {
      final dynamic decoded = jsonDecode(fromDb);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // Fallback to comma separated
      return fromDb
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}

class TimeWindowConverter extends TypeConverter<TimeWindow, String> {
  const TimeWindowConverter();

  @override
  TimeWindow fromSql(String fromDb) {
    try {
      final Map<String, dynamic> json = jsonDecode(fromDb) as Map<String, dynamic>;
      return TimeWindow(
        startTime: json['startTime'] as String? ?? '08:00',
        endTime: json['endTime'] as String? ?? '20:00',
      );
    } catch (_) {
      return const TimeWindow(startTime: '08:00', endTime: '20:00');
    }
  }

  @override
  String toSql(TimeWindow value) {
    return jsonEncode({
      'startTime': value.startTime,
      'endTime': value.endTime,
    });
  }
}

class HabitFrequencyTypeConverter extends TypeConverter<HabitFrequencyType, String> {
  const HabitFrequencyTypeConverter();

  @override
  HabitFrequencyType fromSql(String fromDb) {
    return HabitFrequencyType.fromString(fromDb);
  }

  @override
  String toSql(HabitFrequencyType value) {
    return value.nameValue;
  }
}

class HabitTargetTypeConverter extends TypeConverter<HabitTargetType, String> {
  const HabitTargetTypeConverter();

  @override
  HabitTargetType fromSql(String fromDb) {
    return HabitTargetType.fromString(fromDb);
  }

  @override
  String toSql(HabitTargetType value) {
    return value.nameValue;
  }
}
