import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habits.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [Habits])
class HabitDao extends DatabaseAccessor<AppDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  Stream<List<HabitRow>> watchAllHabits() {
    return (select(habits)
          ..where((h) => h.isDeleted.equals(false))
          ..orderBy([
            (h) => OrderingTerm(expression: h.pinned, mode: OrderingMode.desc),
            (h) => OrderingTerm(expression: h.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Stream<List<HabitRow>> watchActiveHabits() {
    return (select(habits)
          ..where((h) => h.archived.equals(false) & h.isDeleted.equals(false))
          ..orderBy([
            (h) => OrderingTerm(expression: h.pinned, mode: OrderingMode.desc),
            (h) => OrderingTerm(expression: h.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<HabitRow>> getActiveHabitsOnce() {
    return (select(habits)
          ..where((h) => h.archived.equals(false) & h.isDeleted.equals(false))
          ..orderBy([
            (h) => OrderingTerm(expression: h.pinned, mode: OrderingMode.desc),
            (h) => OrderingTerm(expression: h.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<List<HabitRow>> getAllHabitsIncludingDeleted() {
    return select(habits).get();
  }

  Stream<List<HabitRow>> watchArchivedHabits() {
    return (select(habits)
          ..where((h) => h.archived.equals(true) & h.isDeleted.equals(false))
          ..orderBy([
            (h) => OrderingTerm(expression: h.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<HabitRow>> watchPinnedHabits() {
    return (select(habits)
          ..where((h) => h.pinned.equals(true) & h.archived.equals(false) & h.isDeleted.equals(false))
          ..orderBy([
            (h) => OrderingTerm(expression: h.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Stream<HabitRow?> watchHabitById(String id) {
    return (select(habits)..where((h) => h.id.equals(id) & h.isDeleted.equals(false)))
        .watchSingleOrNull();
  }

  Future<HabitRow?> getHabitByIdOnce(String id) {
    return (select(habits)..where((h) => h.id.equals(id) & h.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Stream<List<HabitRow>> watchHabitsByCategory(String categoryId) {
    return (select(habits)
          ..where((h) => h.categoryId.equals(categoryId) & h.archived.equals(false) & h.isDeleted.equals(false))
          ..orderBy([
            (h) => OrderingTerm(expression: h.pinned, mode: OrderingMode.desc),
            (h) => OrderingTerm(expression: h.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<void> upsertHabit(HabitsCompanion habit) {
    return into(habits).insertOnConflictUpdate(habit);
  }

  Future<void> insertHabits(List<HabitsCompanion> habitList) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(habits, habitList);
    });
  }

  Future<void> updateHabit(HabitsCompanion habit) {
    return update(habits).replace(habit);
  }

  Future<int> deleteHabitRow(HabitRow habit) {
    return deleteHabitById(habit.id);
  }

  Future<int> deleteHabitById(String id, [DateTime? updatedAt]) {
    final now = (updatedAt ?? DateTime.now()).toUtc();
    return (update(habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> updatePinned(String id, bool pinned, DateTime updatedAt) {
    return (update(habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        pinned: Value(pinned),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<int> updateArchived(String id, bool archived, DateTime updatedAt) {
    return (update(habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        archived: Value(archived),
        updatedAt: Value(updatedAt),
      ),
    );
  }
}
