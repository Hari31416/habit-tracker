import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/gamification/gamification_models.dart';
import 'package:habit_tracker/domain/gamification/player_title.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/services/widget_sync_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../ui/gamification_controller_test.dart'
    show FakeGamificationRepository;
import '../ui/habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime.now();

  final habits = List.generate(
    20,
    (i) => Habit(
      id: 'bench_habit_$i',
      title: 'Habit $i',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      pinned: i < 3,
      createdAt: today,
      updatedAt: today,
    ),
  );

  const testProgression = PlayerProgression(
    totalXp: 1200,
    level: 6,
    title: PlayerTitle.apprentice,
    nextLevelTargetXp: 1800,
    unlockedBadgesCount: 8,
    totalBadgesCount: 20,
  );

  group('Phase 4 Performance Benchmarks', () {
    test('Benchmark 1: Burst Check-In Widget Sync (50 Rapid Check-Ins Debounced vs Synchronous)', () async {
      final habitRepo = FakeHabitRepository(initialHabits: habits);
      final gamificationRepo = FakeGamificationRepository(progression: testProgression);

      // 1. Un-debounced synchronous simulation (50 individual sync passes)
      final swSync = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        final syncService = WidgetSyncService(habitRepo, gamificationRepo);
        await syncService.syncAllWidgetsImmediate(today);
      }
      swSync.stop();

      // 2. Debounced asynchronous simulation (50 rapid calls coalescing into 1 pass)
      final debouncedSyncService = WidgetSyncService(habitRepo, gamificationRepo);
      final swDebounce = Stopwatch()..start();
      late Future<void> finalSyncFuture;
      for (var i = 0; i < 50; i++) {
        finalSyncFuture = debouncedSyncService.syncAllWidgets(today);
      }
      final unblockedTimeMicroseconds = swDebounce.elapsedMicroseconds;
      await finalSyncFuture;
      swDebounce.stop();

      final msSync = swSync.elapsedMicroseconds / 1000.0;
      final msDebounceTotal = swDebounce.elapsedMicroseconds / 1000.0;
      final msDebounceUnblocked = unblockedTimeMicroseconds / 1000.0;
      final speedup = msSync / (msDebounceUnblocked > 0 ? msDebounceUnblocked : 0.001);

      print('\n=== Benchmark 1: Burst Widget Sync (50 Check-Ins) ===');
      print('Before (50 Synchronous Awaited Passes)   : ${msSync.toStringAsFixed(2)} ms');
      print('After  (Debounced UI Dispatch Time)       : ${msDebounceUnblocked.toStringAsFixed(2)} ms');
      print('After  (Total Coalesced Execution Time)   : ${msDebounceTotal.toStringAsFixed(2)} ms');
      print('UI Unblocked Speedup                      : ${speedup.toStringAsFixed(2)}x');

      expect(debouncedSyncService.lastDailyFocus, isNotNull);
      expect(debouncedSyncService.lastDailyFocus!.totalScheduled, 20);
      debouncedSyncService.dispose();
    });

    test('Benchmark 2: Timezone Database Initialization (latest.dart benchmark)', () {
      final sw = Stopwatch()..start();
      tz_data.initializeTimeZones();
      sw.stop();

      final ms = sw.elapsedMicroseconds / 1000.0;
      print('\n=== Benchmark 2: Non-Blocking Timezone Init ===');
      print('Timezone DB Initialization (latest.dart)  : ${ms.toStringAsFixed(3)} ms');
      expect(ms, isNonNegative);
    });
  });
}
