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
import 'database_seeder.dart';
import 'tables/achievements.dart';
import 'tables/habit_categories.dart';
import 'tables/habit_logs.dart';
import 'tables/habits.dart';
import 'tables/user_gamification.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Habits, HabitLogs, HabitCategories, UserGamification, Achievements],
  daos: [HabitDao, HabitLogDao, HabitCategoryDao, GamificationDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await DatabaseSeeder.seedIfEmpty(this);
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
