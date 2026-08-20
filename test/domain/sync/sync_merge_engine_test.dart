import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_shield.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/sync/sync_envelope.dart';
import 'package:habit_tracker/domain/sync/sync_merge_engine.dart';

void main() {
  group('SyncMergeEngine Deterministic 2-Way Merge Tests', () {
    final baseTime = DateTime.utc(2026, 8, 20, 10, 0, 0);
    final earlierTime = DateTime.utc(2026, 8, 20, 9, 0, 0);
    final laterTime = DateTime.utc(2026, 8, 20, 11, 0, 0);

    test('natural key deduplication merges logs with distinct UUIDs on identical slot', () {
      final habit = Habit(
        id: 'habit_slots',
        title: 'Drink Water',
        color: '#0EA5E9',
        frequencyType: HabitFrequencyType.timesPerDay,
        timesPerDay: 3,
        targetType: HabitTargetType.boolean,
        createdAt: baseTime,
        updatedAt: baseTime,
      );

      // Local phone logged slot 0 with UUID-A at earlier time
      final localLog = HabitLog(
        id: 'uuid_phone_a',
        habitId: 'habit_slots',
        date: '2026-08-20',
        timestamp: earlierTime,
        intervalIndex: 0,
        completed: false,
        createdAt: earlierTime,
        updatedAt: earlierTime,
      );

      // Remote phone logged same slot 0 with UUID-B at later time (completed: true, note added)
      final remoteLog = HabitLog(
        id: 'uuid_phone_b',
        habitId: 'habit_slots',
        date: '2026-08-20',
        timestamp: laterTime,
        intervalIndex: 0,
        completed: true,
        note: 'First glass of water',
        createdAt: laterTime,
        updatedAt: laterTime,
      );

      final localPayload = SyncDataPayload(
        habits: [habit],
        logs: [localLog],
      );

      final remotePayload = SyncDataPayload(
        habits: [habit],
        logs: [remoteLog],
      );

      final result = SyncMergeEngine.merge(
        local: localPayload,
        remote: remotePayload,
        clock: () => laterTime,
      );

      // Should deduplicate by (habitId, date, intervalIndex) -> exactly 1 merged log
      expect(result.mergedPayload.logs.length, 1);
      final merged = result.mergedPayload.logs.first;
      expect(merged.habitId, 'habit_slots');
      expect(merged.date, '2026-08-20');
      expect(merged.intervalIndex, 0);
      expect(merged.completed, true);
      expect(merged.note, 'First glass of water');
      expect(merged.id, 'uuid_phone_b'); // Winning LWW record ID
    });

    test('daily unslotted habits use sentinel -1 for slot deduplication', () {
      final habit = Habit(
        id: 'habit_meditation',
        title: 'Meditation',
        color: '#8B5CF6',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: baseTime,
        updatedAt: baseTime,
      );

      final localLog = HabitLog(
        id: 'local_uuid',
        habitId: 'habit_meditation',
        date: '2026-08-20',
        timestamp: earlierTime,
        intervalIndex: null, // Unslotted daily habit
        completed: false,
        createdAt: earlierTime,
        updatedAt: earlierTime,
      );

      final remoteLog = HabitLog(
        id: 'remote_uuid',
        habitId: 'habit_meditation',
        date: '2026-08-20',
        timestamp: laterTime,
        intervalIndex: null, // Unslotted daily habit
        completed: true,
        mood: 'calm',
        createdAt: laterTime,
        updatedAt: laterTime,
      );

      final result = SyncMergeEngine.merge(
        local: SyncDataPayload(habits: [habit], logs: [localLog]),
        remote: SyncDataPayload(habits: [habit], logs: [remoteLog]),
        clock: () => laterTime,
      );

      expect(result.mergedPayload.logs.length, 1);
      final merged = result.mergedPayload.logs.first;
      expect(merged.completed, true);
      expect(merged.mood, 'calm');
    });

    test('soft delete tombstones propagate and override older active records', () {
      final localHabit = Habit(
        id: 'habit_active_local',
        title: 'Old Title',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        isDeleted: false,
        createdAt: earlierTime,
        updatedAt: earlierTime,
      );

      // Remote deleted this habit at laterTime
      final remoteHabit = localHabit.copyWith(
        isDeleted: true,
        updatedAt: laterTime,
      );

      final result = SyncMergeEngine.merge(
        local: SyncDataPayload(habits: [localHabit]),
        remote: SyncDataPayload(habits: [remoteHabit]),
        clock: () => laterTime,
      );

      expect(result.mergedPayload.habits.length, 1);
      expect(result.mergedPayload.habits.first.isDeleted, true);
      expect(result.stats.habitsDeleted, 1);
    });

    test('fact-first merge recomputes total XP across habits checked in on separate devices', () {
      final habitA = Habit(
        id: 'habit_a',
        title: 'Morning Yoga',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: earlierTime,
        updatedAt: earlierTime,
      );

      final habitB = Habit(
        id: 'habit_b',
        title: 'Evening Reading',
        color: '#3B82F6',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: earlierTime,
        updatedAt: earlierTime,
      );

      // Phone A completed Habit A (earning XP)
      final logA = HabitLog(
        id: 'log_a',
        habitId: 'habit_a',
        date: '2026-08-20',
        timestamp: earlierTime,
        completed: true,
        createdAt: earlierTime,
        updatedAt: earlierTime,
      );

      // Phone B completed Habit B (earning XP)
      final logB = HabitLog(
        id: 'log_b',
        habitId: 'habit_b',
        date: '2026-08-20',
        timestamp: laterTime,
        completed: true,
        createdAt: laterTime,
        updatedAt: laterTime,
      );

      final localPayload = SyncDataPayload(
        habits: [habitA, habitB],
        logs: [logA],
        gamification: const SyncUserGamification(totalXp: 20, currentLevel: 1),
      );

      final remotePayload = SyncDataPayload(
        habits: [habitA, habitB],
        logs: [logB],
        gamification: const SyncUserGamification(totalXp: 20, currentLevel: 1),
      );

      final result = SyncMergeEngine.merge(
        local: localPayload,
        remote: remotePayload,
        clock: () => laterTime,
      );

      // Both habits completed on 2026-08-20 -> Perfect Day bonus (50 XP) + Habit A (20 XP) + Habit B (20 XP) + streak multipliers
      expect(result.mergedPayload.logs.length, 2);
      expect(result.mergedPayload.gamification.totalXp, greaterThan(40));
    });

    test('preserves max lastCelebratedLevel so celebrated modals do not replay', () {
      final habit = Habit(
        id: 'habit_1',
        title: 'Workout',
        color: '#EC4899',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: baseTime,
        updatedAt: baseTime,
      );

      final localPayload = SyncDataPayload(
        habits: [habit],
        gamification: const SyncUserGamification(
          totalXp: 500,
          currentLevel: 4,
          lastCelebratedLevel: 4,
        ),
      );

      final remotePayload = SyncDataPayload(
        habits: [habit],
        gamification: const SyncUserGamification(
          totalXp: 300,
          currentLevel: 3,
          lastCelebratedLevel: 2,
        ),
      );

      final result = SyncMergeEngine.merge(
        local: localPayload,
        remote: remotePayload,
        clock: () => baseTime,
      );

      expect(result.mergedPayload.gamification.lastCelebratedLevel, 4);
    });

    test('merges categories and updates with LWW', () {
      final localCat = HabitCategory(
        id: 'cat_health',
        name: 'Health',
        color: '#10B981',
        createdAt: earlierTime,
        updatedAt: earlierTime,
      );

      final remoteCat = HabitCategory(
        id: 'cat_health',
        name: 'Health & Wellness',
        color: '#059669',
        createdAt: earlierTime,
        updatedAt: laterTime,
      );

      final result = SyncMergeEngine.merge(
        local: SyncDataPayload(categories: [localCat]),
        remote: SyncDataPayload(categories: [remoteCat]),
        clock: () => laterTime,
      );

      expect(result.mergedPayload.categories.length, 1);
      expect(result.mergedPayload.categories.first.name, 'Health & Wellness');
      expect(result.stats.categoriesUpdated, 1);
    });
  });
}
