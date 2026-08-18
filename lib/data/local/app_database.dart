import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/habit_frequency_type.dart';
import '../../domain/models/habit_target_type.dart';
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

  AppDatabase._(super.e);

  /// Default connection used by the running app. Reuses one instance per
  /// isolate so notification actions and Riverpod share the same database.
  factory AppDatabase([QueryExecutor? executor]) {
    if (executor != null) {
      return AppDatabase._(executor);
    }
    return _sharedInstance ??= AppDatabase._(_openConnection());
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await DatabaseSeeder.seedIfEmpty(this);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(habitShields);
          await m.addColumn(userGamification, userGamification.maxShieldsCapacity);
          await m.addColumn(userGamification, userGamification.autoConsumeShields);
        }
        if (from < 3) {
          await m.addColumn(habitLogs, habitLogs.energyLevel);
          await m.addColumn(habitLogs, habitLogs.mood);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        await DatabaseSeeder.seedIfEmpty(this);
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
