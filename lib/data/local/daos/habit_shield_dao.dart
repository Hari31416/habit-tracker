import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habit_shields.dart';

part 'habit_shield_dao.g.dart';

@DriftAccessor(tables: [HabitShields])
class HabitShieldDao extends DatabaseAccessor<AppDatabase> with _$HabitShieldDaoMixin {
  HabitShieldDao(super.db);

  Stream<List<HabitShieldRow>> watchAllShields() {
    return (select(habitShields)..where((s) => s.isDeleted.equals(false))).watch();
  }

  Future<List<HabitShieldRow>> getAllShieldsOnce() {
    return (select(habitShields)..where((s) => s.isDeleted.equals(false))).get();
  }

  Future<List<HabitShieldRow>> getAllShieldsIncludingDeleted() {
    return select(habitShields).get();
  }

  Stream<List<HabitShieldRow>> watchShieldsForHabit(String habitId) {
    return (select(habitShields)
          ..where((s) => s.habitId.equals(habitId) & s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  Future<List<HabitShieldRow>> getShieldsForHabitOnce(String habitId) {
    return (select(habitShields)
          ..where((s) => s.habitId.equals(habitId) & s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .get();
  }

  Stream<List<HabitShieldRow>> watchShieldsForDate(String date) {
    return (select(habitShields)
          ..where((s) => s.date.equals(date) & s.isDeleted.equals(false)))
        .watch();
  }

  Future<List<HabitShieldRow>> getShieldsForDateOnce(String date) {
    return (select(habitShields)
          ..where((s) => s.date.equals(date) & s.isDeleted.equals(false)))
        .get();
  }

  Future<HabitShieldRow?> getShieldForHabitAndDate(String habitId, String date) {
    return (select(habitShields)
          ..where((s) =>
              s.habitId.equals(habitId) &
              s.date.equals(date) &
              s.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Stream<List<HabitShieldRow>> watchShieldsForDateRange(String startDate, String endDate) {
    return (select(habitShields)
          ..where((s) =>
              s.date.isBiggerOrEqualValue(startDate) &
              s.date.isSmallerOrEqualValue(endDate) &
              s.isDeleted.equals(false)))
        .watch();
  }

  Future<List<HabitShieldRow>> getShieldsForDateRangeOnce(String startDate, String endDate) {
    return (select(habitShields)
          ..where((s) =>
              s.date.isBiggerOrEqualValue(startDate) &
              s.date.isSmallerOrEqualValue(endDate) &
              s.isDeleted.equals(false)))
        .get();
  }

  Future<void> upsertShield(HabitShieldsCompanion entity) {
    return into(habitShields).insertOnConflictUpdate(entity);
  }

  Future<void> insertShields(List<HabitShieldsCompanion> shieldList) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(habitShields, shieldList);
    });
  }

  Future<int> deleteShield(String habitId, String date, [DateTime? updatedAt]) {
    final now = (updatedAt ?? DateTime.now()).toUtc();
    return (update(habitShields)
          ..where((s) => s.habitId.equals(habitId) & s.date.equals(date)))
        .write(
      HabitShieldsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> deleteShieldById(String id, [DateTime? updatedAt]) {
    final now = (updatedAt ?? DateTime.now()).toUtc();
    return (update(habitShields)..where((s) => s.id.equals(id))).write(
      HabitShieldsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }
}
