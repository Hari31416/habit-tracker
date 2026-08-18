import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habit_categories.dart';

part 'habit_category_dao.g.dart';

@DriftAccessor(tables: [HabitCategories])
class HabitCategoryDao extends DatabaseAccessor<AppDatabase> with _$HabitCategoryDaoMixin {
  HabitCategoryDao(super.db);

  Stream<List<HabitCategoryRow>> watchAllCategories() {
    return (select(habitCategories)
          ..orderBy([(c) => OrderingTerm(expression: c.name, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<List<HabitCategoryRow>> getAllCategoriesOnce() {
    return (select(habitCategories)
          ..orderBy([(c) => OrderingTerm(expression: c.name, mode: OrderingMode.asc)]))
        .get();
  }

  Stream<HabitCategoryRow?> watchCategoryById(String id) {
    return (select(habitCategories)..where((c) => c.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<HabitCategoryRow?> getCategoryByIdOnce(String id) {
    return (select(habitCategories)..where((c) => c.id.equals(id)))
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
    return delete(habitCategories).delete(category);
  }

  Future<int> deleteCategoryById(String id) {
    return (delete(habitCategories)..where((c) => c.id.equals(id))).go();
  }
}
