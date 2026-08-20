import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habit_categories.dart';

part 'habit_category_dao.g.dart';

@DriftAccessor(tables: [HabitCategories])
class HabitCategoryDao extends DatabaseAccessor<AppDatabase> with _$HabitCategoryDaoMixin {
  HabitCategoryDao(super.db);

  Stream<List<HabitCategoryRow>> watchAllCategories() {
    return (select(habitCategories)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm(expression: c.name, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<List<HabitCategoryRow>> getAllCategoriesOnce() {
    return (select(habitCategories)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm(expression: c.name, mode: OrderingMode.asc)]))
        .get();
  }

  Future<List<HabitCategoryRow>> getAllCategoriesIncludingDeleted() {
    return select(habitCategories).get();
  }

  Stream<HabitCategoryRow?> watchCategoryById(String id) {
    return (select(habitCategories)
          ..where((c) => c.id.equals(id) & c.isDeleted.equals(false)))
        .watchSingleOrNull();
  }

  Future<HabitCategoryRow?> getCategoryByIdOnce(String id) {
    return (select(habitCategories)
          ..where((c) => c.id.equals(id) & c.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<void> upsertCategory(HabitCategoriesCompanion category) {
    return into(habitCategories).insertOnConflictUpdate(category);
  }

  Future<void> insertDefaultCategories(List<HabitCategoriesCompanion> categories) async {
    await batch((b) {
      b.insertAll(habitCategories, categories, mode: InsertMode.insertOrIgnore);
    });
  }

  Future<void> updateCategory(HabitCategoriesCompanion category) {
    return update(habitCategories).replace(category);
  }

  Future<int> deleteCategoryRow(HabitCategoryRow category) {
    return deleteCategoryById(category.id);
  }

  Future<int> deleteCategoryById(String id, [DateTime? updatedAt]) {
    final now = (updatedAt ?? DateTime.now()).toUtc();
    return (update(habitCategories)..where((c) => c.id.equals(id))).write(
      HabitCategoriesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }
}
