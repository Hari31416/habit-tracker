import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habit_logs.dart';

part 'habit_log_dao.g.dart';

@DriftAccessor(tables: [HabitLogs])
class HabitLogDao extends DatabaseAccessor<AppDatabase> with _$HabitLogDaoMixin {
  HabitLogDao(super.db);

  Stream<List<HabitLogRow>> watchLogsForHabit(String habitId) {
    return (select(habitLogs)
          ..where((l) => l.habitId.equals(habitId))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<HabitLogRow>> getLogsForHabitOnce(String habitId) {
    return (select(habitLogs)
          ..where((l) => l.habitId.equals(habitId))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.timestamp, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Stream<List<HabitLogRow>> watchLogsForDate(String date) {
    return (select(habitLogs)..where((l) => l.date.equals(date))).watch();
  }

  Future<List<HabitLogRow>> getLogsForDateOnce(String date) {
    return (select(habitLogs)..where((l) => l.date.equals(date))).get();
  }

  Stream<List<HabitLogRow>> watchLogsForHabitAndDate(String habitId, String date) {
    return (select(habitLogs)
          ..where((l) => l.habitId.equals(habitId) & l.date.equals(date)))
        .watch();
  }

  Future<List<HabitLogRow>> getLogsForHabitAndDateOnce(String habitId, String date) {
    return (select(habitLogs)
          ..where((l) => l.habitId.equals(habitId) & l.date.equals(date)))
        .get();
  }

  Stream<List<HabitLogRow>> watchLogsForDateRange(String startDate, String endDate) {
    return (select(habitLogs)
          ..where((l) => l.date.isBiggerOrEqualValue(startDate) & l.date.isSmallerOrEqualValue(endDate))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<HabitLogRow>> getLogsForDateRangeOnce(String startDate, String endDate) {
    return (select(habitLogs)
          ..where((l) => l.date.isBiggerOrEqualValue(startDate) & l.date.isSmallerOrEqualValue(endDate))
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
              l.date.isSmallerOrEqualValue(endDate))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Stream<List<HabitLogRow>> watchAllLogs() {
    return (select(habitLogs)
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<HabitLogRow>> getAllLogsOnce() {
    return (select(habitLogs)
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.timestamp, mode: OrderingMode.desc),
          ]))
        .get();
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
    return delete(habitLogs).delete(log);
  }

  Future<int> deleteLogById(String id) {
    return (delete(habitLogs)..where((l) => l.id.equals(id))).go();
  }

  Future<int> deleteLogsForHabitAndDate(String habitId, String date) {
    return (delete(habitLogs)
          ..where((l) => l.habitId.equals(habitId) & l.date.equals(date)))
        .go();
  }

  Future<int> deleteSlotLog(String habitId, String date, int intervalIndex) {
    return (delete(habitLogs)
          ..where((l) =>
              l.habitId.equals(habitId) &
              l.date.equals(date) &
              l.intervalIndex.equals(intervalIndex)))
        .go();
  }
}
