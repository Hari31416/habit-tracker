import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habit_routines.dart';
import '../tables/routine_logs.dart';

part 'routine_dao.g.dart';

@DriftAccessor(tables: [HabitRoutines, RoutineLogs])
class RoutineDao extends DatabaseAccessor<AppDatabase> with _$RoutineDaoMixin {
  RoutineDao(super.db);

  Stream<List<HabitRoutineRow>> watchActiveRoutines() {
    return (select(habitRoutines)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .watch();
  }

  Future<List<HabitRoutineRow>> getActiveRoutinesOnce() {
    return (select(habitRoutines)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  Future<List<HabitRoutineRow>> getAllRoutinesIncludingDeleted() {
    return select(habitRoutines).get();
  }

  Future<HabitRoutineRow?> getRoutineById(String id) {
    return (select(habitRoutines)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertRoutine(HabitRoutinesCompanion companion) {
    return into(habitRoutines).insertOnConflictUpdate(companion);
  }

  Future<void> deleteRoutine(String id, DateTime updatedAt) {
    return (update(habitRoutines)..where((tbl) => tbl.id.equals(id))).write(
      HabitRoutinesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> insertDefaultRoutines(List<HabitRoutinesCompanion> defaults) async {
    await batch((b) {
      b.insertAll(
        habitRoutines,
        defaults,
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  // --- Routine Logs ---

  Stream<List<RoutineLogRow>> watchAllRoutineLogs() {
    return (select(routineLogs)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.completedAt)]))
        .watch();
  }

  Stream<List<RoutineLogRow>> watchRoutineLogsForDate(String date) {
    return (select(routineLogs)
          ..where((tbl) => tbl.date.equals(date) & tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.completedAt)]))
        .watch();
  }

  Future<List<RoutineLogRow>> getRoutineLogsForDateOnce(String date) {
    return (select(routineLogs)
          ..where((tbl) => tbl.date.equals(date) & tbl.isDeleted.equals(false)))
        .get();
  }

  Future<List<RoutineLogRow>> getAllRoutineLogsOnce() {
    return (select(routineLogs)..where((tbl) => tbl.isDeleted.equals(false))).get();
  }

  Future<List<RoutineLogRow>> getAllRoutineLogsIncludingDeleted() {
    return select(routineLogs).get();
  }

  Future<RoutineLogRow?> getRoutineLog(String routineId, String date) {
    return (select(routineLogs)
          ..where((tbl) =>
              tbl.routineId.equals(routineId) &
              tbl.date.equals(date) &
              tbl.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<void> upsertRoutineLog(RoutineLogsCompanion companion) {
    return into(routineLogs).insertOnConflictUpdate(companion);
  }

  Future<void> deleteRoutineLog(String id, DateTime updatedAt) {
    return (update(routineLogs)..where((tbl) => tbl.id.equals(id))).write(
      RoutineLogsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
      ),
    );
  }
}
