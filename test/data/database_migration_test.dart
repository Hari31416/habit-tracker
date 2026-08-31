// Drift schema migration harness.
//
// After bumping AppDatabase.schemaVersion and changing tables:
//   1. dart run drift_dev schema dump lib/data/local/app_database.dart \
//        drift_schemas/drift_schema_vN.json
//   2. make schema-generate
//   3. Extend this file with from→to coverage for the new version.
//
// Makefile: `make schema-dump` (current version) and `make schema-generate`.

import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v6.dart' as v6;
import '../generated_migrations/schema_v7.dart' as v7;
import '../generated_migrations/schema_v8.dart' as v8;
import '../generated_migrations/schema_v9.dart' as v9;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('current schema opens without migration (9 → 9)', () async {
    final connection = await verifier.startAt(9);
    final db = AppDatabase.forSchemaVerification(connection);
    await verifier.migrateAndValidate(db, 9);
    await db.close();
  });

  test('upgrade from v6 to v7 adds elastic columns and keeps rows', () async {
    final schema = await verifier.schemaAt(6);
    final createdAt = DateTime.utc(2026, 3, 15).millisecondsSinceEpoch;
    final updatedAt = DateTime.utc(2026, 3, 16).millisecondsSinceEpoch;
    final logTs = DateTime.utc(2026, 3, 20, 7, 45).millisecondsSinceEpoch;

    final oldDb = v6.DatabaseAtV6(schema.newConnection());
    await oldDb.into(oldDb.habits).insert(
          v6.HabitsCompanion.insert(
            id: 'habit_mig_v6',
            title: 'Migration Walk',
            color: '#10B981',
            frequencyType: 'daily',
            targetType: 'numeric',
            targetValue: const Value(8000.0),
            healthMetric: const Value('steps'),
            healthSyncEnabled: const Value(1),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        );
    await oldDb.into(oldDb.habitLogs).insert(
          v6.HabitLogsCompanion.insert(
            id: 'log_mig_v6',
            habitId: 'habit_mig_v6',
            date: '2026-03-20',
            timestamp: logTs,
            completed: 1,
            value: const Value(5000.0),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        );
    await oldDb.close();

    final db = AppDatabase.forSchemaVerification(schema.newConnection());
    await verifier.migrateAndValidate(db, 9);
    await db.close();

    final migrated = v9.DatabaseAtV9(schema.newConnection());
    final habit = await (migrated.select(migrated.habits)
          ..where((t) => t.id.equals('habit_mig_v6')))
        .getSingle();
    expect(habit.title, 'Migration Walk');
    expect(habit.targetValue, 8000.0);
    expect(habit.healthMetric, 'steps');
    expect(habit.miniTargetValue, isNull);
    expect(habit.eliteTargetValue, isNull);
    expect(habit.isNegative, 0);

    final log = await (migrated.select(migrated.habitLogs)
          ..where((t) => t.id.equals('log_mig_v6')))
        .getSingle();
    expect(log.value, 5000.0);
    expect(log.targetTier, isNull);

    // New v9 columns accept writes after upgrade.
    await (migrated.update(migrated.habits)
          ..where((t) => t.id.equals('habit_mig_v6')))
        .write(
      const v9.HabitsCompanion(
        miniTargetValue: Value(2500.0),
        eliteTargetValue: Value(12000.0),
        isNegative: Value(1),
      ),
    );
    await (migrated.update(migrated.habitLogs)
          ..where((t) => t.id.equals('log_mig_v6')))
        .write(const v9.HabitLogsCompanion(targetTier: Value('mini')));

    final updatedHabit = await (migrated.select(migrated.habits)
          ..where((t) => t.id.equals('habit_mig_v6')))
        .getSingle();
    expect(updatedHabit.miniTargetValue, 2500.0);
    expect(updatedHabit.eliteTargetValue, 12000.0);
    expect(updatedHabit.isNegative, 1);

    final updatedLog = await (migrated.select(migrated.habitLogs)
          ..where((t) => t.id.equals('log_mig_v6')))
        .getSingle();
    expect(updatedLog.targetTier, 'mini');

    await migrated.close();
  });

  test('upgrade from v7 to v9 adds habit_routines, routine_logs, is_negative, and clean_since', () async {
    final schema = await verifier.schemaAt(7);
    final createdAt = DateTime.utc(2026, 3, 15).millisecondsSinceEpoch;
    final updatedAt = DateTime.utc(2026, 3, 16).millisecondsSinceEpoch;

    final oldDb = v7.DatabaseAtV7(schema.newConnection());
    await oldDb.into(oldDb.habits).insert(
          v7.HabitsCompanion.insert(
            id: 'habit_mig_v7',
            title: 'Migration Walk v7',
            color: '#10B981',
            frequencyType: 'daily',
            targetType: 'numeric',
            targetValue: const Value(8000.0),
            miniTargetValue: const Value(2500.0),
            eliteTargetValue: const Value(12000.0),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        );
    await oldDb.close();

    final db = AppDatabase.forSchemaVerification(schema.newConnection());
    await verifier.migrateAndValidate(db, 9);
    await db.close();

    final migrated = v9.DatabaseAtV9(schema.newConnection());
    final habit = await (migrated.select(migrated.habits)
          ..where((t) => t.id.equals('habit_mig_v7')))
        .getSingle();
    expect(habit.title, 'Migration Walk v7');
    expect(habit.miniTargetValue, 2500.0);
    expect(habit.eliteTargetValue, 12000.0);
    expect(habit.isNegative, 0);

    // New v9 tables accept inserts
    await migrated.into(migrated.habitRoutines).insert(
          v9.HabitRoutinesCompanion.insert(
            id: 'routine_mig_v8',
            title: 'Morning Routine',
            color: '#3B82F6',
            habitIds: const Value('["habit_mig_v7"]'),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        );

    final routine = await (migrated.select(migrated.habitRoutines)
          ..where((t) => t.id.equals('routine_mig_v8')))
        .getSingle();
    expect(routine.title, 'Morning Routine');
    expect(routine.bonusXp, 30);

    await migrated.close();
  });

  test('upgrade from v8 to v9 adds is_negative and clean_since columns', () async {
    final schema = await verifier.schemaAt(8);
    final createdAt = DateTime.utc(2026, 3, 15).millisecondsSinceEpoch;
    final updatedAt = DateTime.utc(2026, 3, 16).millisecondsSinceEpoch;

    final oldDb = v8.DatabaseAtV8(schema.newConnection());
    await oldDb.into(oldDb.habits).insert(
          v8.HabitsCompanion.insert(
            id: 'habit_mig_v8',
            title: 'Migration Walk v8',
            color: '#10B981',
            frequencyType: 'daily',
            targetType: 'numeric',
            targetValue: const Value(8000.0),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        );
    await oldDb.close();

    final db = AppDatabase.forSchemaVerification(schema.newConnection());
    await verifier.migrateAndValidate(db, 9);
    await db.close();

    final migrated = v9.DatabaseAtV9(schema.newConnection());
    final habit = await (migrated.select(migrated.habits)
          ..where((t) => t.id.equals('habit_mig_v8')))
        .getSingle();
    expect(habit.title, 'Migration Walk v8');
    expect(habit.isNegative, 0);
    expect(habit.cleanSince, isNull);

    // New v9 columns accept writes after upgrade.
    final cleanSinceEpoch = DateTime.utc(2026, 3, 20, 10, 0).millisecondsSinceEpoch;
    await (migrated.update(migrated.habits)
          ..where((t) => t.id.equals('habit_mig_v8')))
        .write(
      v9.HabitsCompanion(
        isNegative: const Value(1),
        cleanSince: Value(cleanSinceEpoch),
      ),
    );

    final updatedHabit = await (migrated.select(migrated.habits)
          ..where((t) => t.id.equals('habit_mig_v8')))
        .getSingle();
    expect(updatedHabit.isNegative, 1);
    expect(updatedHabit.cleanSince, cleanSinceEpoch);

    await migrated.close();
  });
}
