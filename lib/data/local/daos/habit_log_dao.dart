import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habit_logs.dart';

part 'habit_log_dao.g.dart';

@DriftAccessor(tables: [HabitLogs])
class HabitLogDao extends DatabaseAccessor<AppDatabase> with _$HabitLogDaoMixin {
  HabitLogDao(super.db);

  Stream<List<HabitLogRow>> watchLogsForHabit(String habitId) {
    return (select(habitLogs)
          ..where((l) => l.habitId.equals(habitId) & l.isDeleted.equals(false))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<HabitLogRow>> getLogsForHabitOnce(String habitId) {
    return (select(habitLogs)
          ..where((l) => l.habitId.equals(habitId) & l.isDeleted.equals(false))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.timestamp, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Stream<List<HabitLogRow>> watchLogsForDate(String date) {
    return (select(habitLogs)
          ..where((l) => l.date.equals(date) & l.isDeleted.equals(false)))
        .watch();
  }

  Future<List<HabitLogRow>> getLogsForDateOnce(String date) {
    return (select(habitLogs)
          ..where((l) => l.date.equals(date) & l.isDeleted.equals(false)))
        .get();
  }

  Stream<List<HabitLogRow>> watchLogsForHabitAndDate(String habitId, String date) {
    return (select(habitLogs)
          ..where((l) => l.habitId.equals(habitId) & l.date.equals(date) & l.isDeleted.equals(false)))
        .watch();
  }

  Future<List<HabitLogRow>> getLogsForHabitAndDateOnce(String habitId, String date) {
    return (select(habitLogs)
          ..where((l) => l.habitId.equals(habitId) & l.date.equals(date) & l.isDeleted.equals(false)))
        .get();
  }

  Stream<List<HabitLogRow>> watchLogsForDateRange(String startDate, String endDate) {
    return (select(habitLogs)
          ..where((l) =>
              l.date.isBiggerOrEqualValue(startDate) &
              l.date.isSmallerOrEqualValue(endDate) &
              l.isDeleted.equals(false))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<HabitLogRow>> getLogsForDateRangeOnce(String startDate, String endDate) {
    return (select(habitLogs)
          ..where((l) =>
              l.date.isBiggerOrEqualValue(startDate) &
              l.date.isSmallerOrEqualValue(endDate) &
              l.isDeleted.equals(false))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Stream<List<HabitLogRow>> watchLogsForHabitAndDateRange(
    String habitId,
    String startDate,
    String endDate,
  ) {
    return (select(habitLogs)
          ..where((l) =>
              l.habitId.equals(habitId) &
              l.date.isBiggerOrEqualValue(startDate) &
              l.date.isSmallerOrEqualValue(endDate) &
              l.isDeleted.equals(false))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Stream<List<HabitLogRow>> watchAllLogs() {
    return (select(habitLogs)
          ..where((l) => l.isDeleted.equals(false))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<HabitLogRow>> getAllLogsOnce() {
    return (select(habitLogs)
          ..where((l) => l.isDeleted.equals(false))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.timestamp, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<List<HabitLogRow>> getAllLogsIncludingDeleted() {
    return select(habitLogs).get();
  }

  Future<void> upsertLog(HabitLogsCompanion log) {
    return into(habitLogs).insertOnConflictUpdate(log);
  }

  Future<void> insertLogs(List<HabitLogsCompanion> logList) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(habitLogs, logList);
    });
  }

  Future<void> updateLog(HabitLogsCompanion log) {
    return update(habitLogs).replace(log);
  }

  Future<int> deleteLogRow(HabitLogRow log) {
    return deleteLogById(log.id);
  }

  Future<int> deleteLogById(String id, [DateTime? updatedAt]) {
    final now = (updatedAt ?? DateTime.now()).toUtc();
    return (update(habitLogs)..where((l) => l.id.equals(id))).write(
      HabitLogsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> deleteLogsForHabitAndDate(String habitId, String date, [DateTime? updatedAt]) {
    final now = (updatedAt ?? DateTime.now()).toUtc();
    return (update(habitLogs)
          ..where((l) => l.habitId.equals(habitId) & l.date.equals(date)))
        .write(
      HabitLogsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> deleteSlotLog(String habitId, String date, int intervalIndex, [DateTime? updatedAt]) {
    final now = (updatedAt ?? DateTime.now()).toUtc();
    return (update(habitLogs)
          ..where((l) =>
              l.habitId.equals(habitId) &
              l.date.equals(date) &
              l.intervalIndex.equals(intervalIndex)))
        .write(
      HabitLogsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateReflectionForHabitAndDate(
    String habitId,
    String date, {
    int? energyLevel,
    String? mood,
    String? note,
  }) async {
    final now = DateTime.now().toUtc();
    final companion = HabitLogsCompanion(
      energyLevel: Value(energyLevel),
      mood: Value(mood),
      note: Value(note),
      updatedAt: Value(now),
    );
    await (update(habitLogs)
          ..where((l) => l.habitId.equals(habitId) & l.date.equals(date)))
        .write(companion);
  }
}
