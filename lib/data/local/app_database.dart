import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/habit_frequency_type.dart';
import '../../domain/models/habit_target_type.dart';
import '../../domain/models/habit_tier.dart';
import '../../domain/models/health/health_metric_type.dart';
import '../../domain/models/time_window.dart';
import 'converters/type_converters.dart';
import 'daos/gamification_dao.dart';
import 'daos/habit_category_dao.dart';
import 'daos/habit_dao.dart';
import 'daos/habit_log_dao.dart';
import 'daos/habit_shield_dao.dart';
import 'database_seeder.dart';
import 'tables/achievements.dart';
import 'tables/habit_categories.dart';
import 'tables/habit_logs.dart';
import 'tables/habit_shields.dart';
import 'tables/habits.dart';
import 'tables/user_gamification.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Habits, HabitLogs, HabitShields, HabitCategories, UserGamification, Achievements],
  daos: [HabitDao, HabitLogDao, HabitShieldDao, HabitCategoryDao, GamificationDao],
)
class AppDatabase extends _$AppDatabase {
  static AppDatabase? _sharedInstance;

  /// When true, skips defensive ALTER TABLE fixes in [beforeOpen] so
  /// SchemaVerifier migration tests exercise [onUpgrade] alone.
  final bool skipDefensiveSchemaFixes;

  AppDatabase._(super.e, {this.skipDefensiveSchemaFixes = false});

  /// Default connection used by the running app. Reuses one instance per
  /// isolate so notification actions and Riverpod share the same database.
  factory AppDatabase([QueryExecutor? executor]) {
    if (executor != null) {
      return AppDatabase._(executor);
    }
    return _sharedInstance ??= AppDatabase._(_openConnection());
  }

  /// Opens [executor] with production [onUpgrade], without defensive column
  /// ALTERs. Used by `test/data/database_migration_test.dart`.
  @visibleForTesting
  factory AppDatabase.forSchemaVerification(QueryExecutor executor) {
    return AppDatabase._(executor, skipDefensiveSchemaFixes: true);
  }

  /// Database for a background isolate. On the main isolate this returns the
  /// shared instance so we never open the file twice.
  static AppDatabase backgroundInstance() => AppDatabase();

  @override
  Future<void> close() {
    if (identical(this, _sharedInstance)) {
      _sharedInstance = null;
    }
    return super.close();
  }

  @override
  int get schemaVersion => 7;

  Future<void> _safeAddColumn(Migrator m, TableInfo table, GeneratedColumn column) async {
    try {
      await m.addColumn(table, column);
    } catch (_) {
      // Ignore if column already exists from a prior interrupted migration attempt
    }
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await DatabaseSeeder.seedIfEmpty(this);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          try {
            await m.createTable(habitShields);
          } catch (_) {}
          await _safeAddColumn(m, userGamification, userGamification.maxShieldsCapacity);
          await _safeAddColumn(m, userGamification, userGamification.autoConsumeShields);
        }
        if (from < 3) {
          await _safeAddColumn(m, habitLogs, habitLogs.energyLevel);
          await _safeAddColumn(m, habitLogs, habitLogs.mood);
        }
        if (from < 4) {
          await _safeAddColumn(m, habits, habits.promptReflection);
          try {
            await customStatement("UPDATE habits SET prompt_reflection = 1 WHERE id IN ('seed_habit_meditation', 'seed_habit_evening_review', 'seed_habit_deep_work')");
          } catch (_) {}
        }
        if (from < 5) {
          await _safeAddColumn(m, habitCategories, habitCategories.isDeleted);
          await _safeAddColumn(m, habitCategories, habitCategories.createdAt);
          await _safeAddColumn(m, habitCategories, habitCategories.updatedAt);
          await _safeAddColumn(m, habits, habits.isDeleted);
          await _safeAddColumn(m, habitLogs, habitLogs.isDeleted);
          await _safeAddColumn(m, habitShields, habitShields.isDeleted);
          await _safeAddColumn(m, achievements, achievements.createdAt);
          await _safeAddColumn(m, achievements, achievements.updatedAt);
        }
        if (from < 6) {
          await _safeAddColumn(m, habits, habits.healthMetric);
          await _safeAddColumn(m, habits, habits.healthSyncEnabled);
        }
        if (from < 7) {
          await _safeAddColumn(m, habits, habits.miniTargetValue);
          await _safeAddColumn(m, habits, habits.eliteTargetValue);
          await _safeAddColumn(m, habitLogs, habitLogs.targetTier);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA journal_mode = WAL;');
        await customStatement('PRAGMA synchronous = NORMAL;');
        await customStatement('PRAGMA foreign_keys = ON;');
        await customStatement('PRAGMA temp_store = MEMORY;');
        await customStatement('PRAGMA cache_size = -4000;');

        if (skipDefensiveSchemaFixes) {
          return;
        }

        // Defensive column addition if database was left in an inconsistent migration state
        final columnFixes = [
          'ALTER TABLE habit_categories ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1));',
          'ALTER TABLE habit_categories ADD COLUMN created_at INTEGER NOT NULL DEFAULT 1767225600;',
          'ALTER TABLE habit_categories ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 1767225600;',
          'ALTER TABLE habits ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1));',
          'ALTER TABLE habit_logs ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1));',
          'ALTER TABLE habit_shields ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1));',
          'ALTER TABLE achievements ADD COLUMN created_at INTEGER NOT NULL DEFAULT 1767225600;',
          'ALTER TABLE achievements ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 1767225600;',
          'ALTER TABLE habits ADD COLUMN health_metric TEXT;',
          'ALTER TABLE habits ADD COLUMN health_sync_enabled INTEGER NOT NULL DEFAULT 0 CHECK (health_sync_enabled IN (0, 1));',
          'ALTER TABLE habits ADD COLUMN mini_target_value REAL;',
          'ALTER TABLE habits ADD COLUMN elite_target_value REAL;',
          'ALTER TABLE habit_logs ADD COLUMN target_tier TEXT;',
        ];

        for (final stmt in columnFixes) {
          try {
            await customStatement(stmt);
          } catch (_) {
            // Column already exists
          }
        }

        final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
        final updates = [
          'UPDATE habit_categories SET created_at = $nowEpoch, updated_at = $nowEpoch WHERE typeof(created_at) != "integer" OR created_at IS NULL OR typeof(updated_at) != "integer" OR updated_at IS NULL;',
          'UPDATE habit_categories SET is_deleted = 0 WHERE typeof(is_deleted) != "integer" OR is_deleted IS NULL;',
          'UPDATE habits SET is_deleted = 0 WHERE typeof(is_deleted) != "integer" OR is_deleted IS NULL;',
          'UPDATE habit_logs SET is_deleted = 0 WHERE typeof(is_deleted) != "integer" OR is_deleted IS NULL;',
          'UPDATE habit_shields SET is_deleted = 0 WHERE typeof(is_deleted) != "integer" OR is_deleted IS NULL;',
          'UPDATE achievements SET created_at = $nowEpoch, updated_at = $nowEpoch WHERE typeof(created_at) != "integer" OR created_at IS NULL OR typeof(updated_at) != "integer" OR updated_at IS NULL;',
        ];

        for (final upd in updates) {
          try {
            await customStatement(upd);
          } catch (_) {}
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'habit_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
