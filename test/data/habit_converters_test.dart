import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/converters/type_converters.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/time_window.dart';

void main() {
  test('intListConverter_roundTripsCorrectly', () {
    const converter = IntListConverter();
    const list = [1, 3, 5];
    final str = converter.toSql(list);
    final result = converter.fromSql(str);
    expect(result, list);
  });

  test('stringListConverter_roundTripsCorrectly', () {
    const converter = StringListConverter();
    const list = ['08:00', '12:30', '18:00'];
    final str = converter.toSql(list);
    final result = converter.fromSql(str);
    expect(result, list);
  });

  test('timeWindowConverter_roundTripsCorrectly', () {
    const converter = TimeWindowConverter();
    const window = TimeWindow(startTime: '08:00', endTime: '20:00');
    final str = converter.toSql(window);
    final result = converter.fromSql(str);
    expect(result, window);
  });

  test('frequencyTypeConverter_roundTripsCorrectly', () {
    const converter = HabitFrequencyTypeConverter();
    for (final type in HabitFrequencyType.values) {
      final str = converter.toSql(type);
      final result = converter.fromSql(str);
      expect(result, type);
    }
  });

  test('targetTypeConverter_roundTripsCorrectly', () {
    const converter = HabitTargetTypeConverter();
    for (final type in HabitTargetType.values) {
      final str = converter.toSql(type);
      final result = converter.fromSql(str);
      expect(result, type);
    }
  });
}
