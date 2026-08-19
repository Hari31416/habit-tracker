import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habit_shields.dart';

part 'habit_shield_dao.g.dart';

@DriftAccessor(tables: [HabitShields])
class HabitShieldDao extends DatabaseAccessor<AppDatabase> with _$HabitShieldDaoMixin {
  HabitShieldDao(super.db);

  Stream<List<HabitShieldRow>> watchAllShields() {
    return select(habitShields).watch();
  }

  Future<List<HabitShieldRow>> getAllShieldsOnce() {
    return select(habitShields).get();
  }

  Stream<List<HabitShieldRow>> watchShieldsForHabit(String habitId) {
    return (select(habitShields)
          ..where((s) => s.habitId.equals(habitId))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  Future<List<HabitShieldRow>> getShieldsForHabitOnce(String habitId) {
    return (select(habitShields)
          ..where((s) => s.habitId.equals(habitId))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .get();
  }

  Stream<List<HabitShieldRow>> watchShieldsForDate(String date) {
    return (select(habitShields)..where((s) => s.date.equals(date))).watch();
  }

  Future<List<HabitShieldRow>> getShieldsForDateOnce(String date) {
    return (select(habitShields)..where((s) => s.date.equals(date))).get();
  }

  Future<HabitShieldRow?> getShieldForHabitAndDate(String habitId, String date) {
    return (select(habitShields)
          ..where((s) => s.habitId.equals(habitId) & s.date.equals(date)))
        .getSingleOrNull();
  }

  Stream<List<HabitShieldRow>> watchShieldsForDateRange(String startDate, String endDate) {
    return (select(habitShields)
          ..where((s) => s.date.isBiggerOrEqualValue(startDate) & s.date.isSmallerOrEqualValue(endDate)))
        .watch();
  }

  Future<List<HabitShieldRow>> getShieldsForDateRangeOnce(String startDate, String endDate) {
    return (select(habitShields)
          ..where((s) => s.date.isBiggerOrEqualValue(startDate) & s.date.isSmallerOrEqualValue(endDate)))
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

  Future<void> deleteShield(String habitId, String date) {
    return (delete(habitShields)
          ..where((s) => s.habitId.equals(habitId) & s.date.equals(date)))
        .go();
  }

  Future<void> deleteShieldById(String id) {
    return (delete(habitShields)..where((s) => s.id.equals(id))).go();
  }
}
