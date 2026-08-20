import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/health/health_metric_type.dart';
import 'package:habit_tracker/domain/models/sync/sync_envelope.dart';

void main() {
  group('Health Connect Backup and Sync Envelope Tests', () {
    test('Habit with health metric serializes to JSON and deserializes accurately', () {
      final now = DateTime.now().toUtc();
      final habit = Habit(
        id: 'h_steps_1',
        title: 'Daily Steps 10k',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.numeric,
        targetValue: 10000,
        unit: 'steps',
        healthMetric: HealthMetricType.steps,
        healthSyncEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final envelope = SyncEnvelope(
        appVersion: '0.9.0',
        exportedAt: now,
        deviceId: 'device_test_1',
        data: SyncDataPayload(
          habits: [habit],
        ),
      );

      final jsonString = envelope.toFormattedJson();
      final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final restoredEnvelope = SyncEnvelope.fromJson(decodedMap);

      expect(restoredEnvelope.data.habits.length, 1);
      final restoredHabit = restoredEnvelope.data.habits.first;
      expect(restoredHabit.id, habit.id);
      expect(restoredHabit.title, habit.title);
      expect(restoredHabit.healthMetric, HealthMetricType.steps);
      expect(restoredHabit.healthSyncEnabled, isTrue);
    });
  });
}
