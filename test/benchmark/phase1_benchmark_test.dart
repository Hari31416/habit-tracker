import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/no_op_habit_reminder_scheduler.dart';
import 'package:habit_tracker/domain/engines/shield_banking_engine.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_shield.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();

  group('Phase 1 Performance Benchmarks', () {
    test('Benchmark 1: Multi-slot check-in (Batch insertLogs + Transaction vs Sequential Upserts)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = HabitRepositoryImpl(
        habitDao: db.habitDao,
        habitLogDao: db.habitLogDao,
        habitShieldDao: db.habitShieldDao,
        habitCategoryDao: db.habitCategoryDao,
        gamificationDao: db.gamificationDao,
        reminderScheduler: const NoOpHabitReminderScheduler(),
      );

      final now = DateTime.now().toUtc();
      final slotsHabit = Habit(
        id: 'bench-slot-habit',
        title: 'Hydration 8 Slots',
        color: '#0EA5E9',
        frequencyType: HabitFrequencyType.timesPerDay,
        timesPerDay: 8,
        targetType: HabitTargetType.boolean,
        createdAt: now,
        updatedAt: now,
      );
      await repo.upsertHabit(slotsHabit);

      const iterations = 50;

      // Unoptimized simulation (Sequential non-transactional upserts)
      final swUnoptimized = Stopwatch()..start();
      for (var iter = 0; iter < iterations; iter++) {
        final dateStr = '2026-01-${(iter + 1).toString().padLeft(2, '0')}';
        for (var i = 0; i < 8; i++) {
          await db.habitLogDao.upsertLog(
            HabitLogsCompanion(
              id: Value(uuid.v4()),
              habitId: const Value('bench-slot-habit'),
              date: Value(dateStr),
              timestamp: Value(now),
              intervalIndex: Value(i),
              completed: const Value(true),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        }
      }
      swUnoptimized.stop();

      // Optimized (Repository method with transaction + batch insertLogs)
      final swOptimized = Stopwatch()..start();
      for (var iter = 0; iter < iterations; iter++) {
        final date = DateTime(2026, 3, 1).add(Duration(days: iter));
        await repo.toggleBooleanCheckIn('bench-slot-habit', date);
      }
      swOptimized.stop();

      print('\n=== Benchmark 1: Multi-Slot Check-in (50 check-ins x 8 slots = 400 rows) ===');
      print('Before (Sequential upserts, no transaction): ${(swUnoptimized.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      print('After  (Transaction + Batch insertLogs)   : ${(swOptimized.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      print('Speedup: ${(swUnoptimized.elapsedMicroseconds / swOptimized.elapsedMicroseconds).toStringAsFixed(2)}x');

      await db.close();
    });

    test('Benchmark 2: autoProtectMissedDays (Batch insert + single calculation vs N+1 roundtrips)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = HabitRepositoryImpl(
        habitDao: db.habitDao,
        habitLogDao: db.habitLogDao,
        habitShieldDao: db.habitShieldDao,
        habitCategoryDao: db.habitCategoryDao,
        gamificationDao: db.gamificationDao,
        reminderScheduler: const NoOpHabitReminderScheduler(),
      );

      final now = DateTime.now().toUtc();
      final habits = <Habit>[];
      for (var i = 0; i < 15; i++) {
        final h = Habit(
          id: 'auto-habit-$i',
          title: 'Habit $i',
          color: '#10B981',
          frequencyType: HabitFrequencyType.daily,
          targetType: HabitTargetType.boolean,
          createdAt: now,
          updatedAt: now,
        );
        habits.add(h);
        await repo.upsertHabit(h);
      }

      // Seed 20 days of historical logs for all 15 habits (days 01 to 20 of May)
      final historicalLogs = <HabitLogsCompanion>[];
      for (final h in habits) {
        for (var d = 1; d <= 20; d++) {
          historicalLogs.add(
            HabitLogsCompanion(
              id: Value(uuid.v4()),
              habitId: Value(h.id),
              date: Value('2026-05-${d.toString().padLeft(2, '0')}'),
              timestamp: Value(now),
              completed: const Value(true),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        }
      }
      await db.habitLogDao.insertLogs(historicalLogs);

      final targetDate = DateTime(2026, 5, 21); // Missed day

      // Simulation of Unoptimized autoProtectMissedDays (re-querying database & re-evaluating bank state per applied shield)
      final swUnoptimized = Stopwatch()..start();
      {
        final activeHabits = (await db.habitDao.watchActiveHabits().first).map(
          (row) => Habit(
            id: row.id,
            title: row.title,
            color: row.color,
            frequencyType: row.frequencyType,
            targetType: row.targetType,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        ).toList();
        final allLogs = (await db.habitLogDao.getAllLogsOnce()).map(
          (r) => HabitLog(
            id: r.id,
            habitId: r.habitId,
            date: r.date,
            timestamp: r.timestamp,
            completed: r.completed,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
        ).toList();
        var allShields = (await db.habitShieldDao.getAllShieldsOnce()).map(
          (r) => HabitShield(
            id: r.id,
            habitId: r.habitId,
            date: r.date,
            autoApplied: r.autoApplied,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
        ).toList();

        var currentBankState = ShieldBankingEngine.calculateBankState(
          habits: activeHabits,
          logs: allLogs,
          shields: allShields,
          maxCapacity: 20,
          autoConsumeEnabled: true,
          referenceDate: targetDate,
        );

        final targetDateStr = '2026-05-21';
        for (final habit in activeHabits) {
          if (currentBankState.availableShields <= 0) break;
          // Apply individual shield
          await db.habitShieldDao.upsertShield(
            HabitShieldsCompanion(
              id: Value(uuid.v4()),
              habitId: Value(habit.id),
              date: Value(targetDateStr),
              autoApplied: const Value(true),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
          // Re-query database and re-calculate
          final updated = await db.habitShieldDao.getAllShieldsOnce();
          allShields = updated.map(
            (r) => HabitShield(
              id: r.id,
              habitId: r.habitId,
              date: r.date,
              autoApplied: r.autoApplied,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ),
          ).toList();
          currentBankState = ShieldBankingEngine.calculateBankState(
            habits: activeHabits,
            logs: allLogs,
            shields: allShields,
            maxCapacity: 20,
            autoConsumeEnabled: true,
            referenceDate: targetDate,
          );
        }
      }
      swUnoptimized.stop();

      // Clean shields
      for (final h in habits) {
        await db.habitShieldDao.deleteShield(h.id, '2026-05-21');
      }

      // Optimized autoProtectMissedDays execution
      final swOptimized = Stopwatch()..start();
      final count = await repo.autoProtectMissedDays(targetDate);
      swOptimized.stop();

      print('\n=== Benchmark 2: autoProtectMissedDays (15 habits with 20-day streak) ===');
      print('Before (N+1 database reads & repeated bank recalc): ${(swUnoptimized.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      print('After  (Single pass + Batch insertShields)        : ${(swOptimized.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      print('Speedup: ${(swUnoptimized.elapsedMicroseconds / swOptimized.elapsedMicroseconds).toStringAsFixed(2)}x');
      expect(count, greaterThan(0));

      await db.close();
    });

    test('Benchmark 3: Week Matrix Query (Scoped Date-Range vs Full Table Scan)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.now().toUtc();

      // Insert habits first for foreign key constraint
      for (var h = 1; h <= 10; h++) {
        await db.habitDao.upsertHabit(
          HabitsCompanion(
            id: Value('habit-$h'),
            title: Value('Habit $h'),
            color: const Value('#10B981'),
            frequencyType: const Value(HabitFrequencyType.daily),
            targetType: const Value(HabitTargetType.boolean),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      // Seed 2000 log rows across 200 days
      final logs = <HabitLogsCompanion>[];
      for (var day = 1; day <= 200; day++) {
        for (var h = 1; h <= 10; h++) {
          final month = (day ~/ 28 + 1).toString().padLeft(2, '0');
          final d = (day % 28 + 1).toString().padLeft(2, '0');
          logs.add(
            HabitLogsCompanion(
              id: Value('log-$day-$h'),
              habitId: Value('habit-$h'),
              date: Value('2026-$month-$d'),
              timestamp: Value(now),
              completed: const Value(true),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        }
      }
      await db.habitLogDao.insertLogs(logs);

      const queryRuns = 100;

      // Before: query full table (2000 rows) on every week view
      final swFull = Stopwatch()..start();
      for (var r = 0; r < queryRuns; r++) {
        final rows = await db.habitLogDao.getAllLogsOnce();
        expect(rows.length, 2000);
      }
      swFull.stop();

      // After: query only the 7 visible days
      final swScoped = Stopwatch()..start();
      for (var r = 0; r < queryRuns; r++) {
        final rows = await db.habitLogDao.getLogsForDateRangeOnce('2026-03-01', '2026-03-07');
        expect(rows.isNotEmpty, isTrue);
      }
      swScoped.stop();

      print('\n=== Benchmark 3: Log Query (100 query cycles on 2,000 log dataset) ===');
      print('Before (Full history scan - getAllLogsOnce): ${(swFull.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      print('After  (Scoped 7-day range query)          : ${(swScoped.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      print('Speedup: ${(swFull.elapsedMicroseconds / swScoped.elapsedMicroseconds).toStringAsFixed(2)}x');

      await db.close();
    });

    test('Benchmark 4: Batch Shield Insertion (insertShields vs Sequential Upsert in Loop)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.now().toUtc();

      // Seed 20 habits
      for (var i = 0; i < 20; i++) {
        await db.habitDao.upsertHabit(
          HabitsCompanion(
            id: Value('habit-$i'),
            title: Value('Habit $i'),
            color: const Value('#10B981'),
            frequencyType: const Value(HabitFrequencyType.daily),
            targetType: const Value(HabitTargetType.boolean),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      final companions = List.generate(
        20,
        (i) => HabitShieldsCompanion(
          id: Value(uuid.v4()),
          habitId: Value('habit-$i'),
          date: const Value('2026-08-18'),
          autoApplied: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Sequential upserts
      final swSequential = Stopwatch()..start();
      for (final comp in companions) {
        await db.habitShieldDao.upsertShield(comp);
      }
      swSequential.stop();

      // Clear
      for (var i = 0; i < 20; i++) {
        await db.habitShieldDao.deleteShield('habit-$i', '2026-08-18');
      }

      // Batch insert
      final swBatch = Stopwatch()..start();
      await db.habitShieldDao.insertShields(companions);
      swBatch.stop();

      print('\n=== Benchmark 4: Shield Insertion (20 shields) ===');
      print('Before (Sequential upsertShield loop): ${(swSequential.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      print('After  (Batch insertShields)         : ${(swBatch.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms');
      print('Speedup: ${(swSequential.elapsedMicroseconds / swBatch.elapsedMicroseconds).toStringAsFixed(2)}x\n');

      await db.close();
    });
  });
}
