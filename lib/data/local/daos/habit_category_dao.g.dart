// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_category_dao.dart';

// ignore_for_file: type=lint
mixin _$HabitCategoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitCategoriesTable get habitCategories => attachedDatabase.habitCategories;
  HabitCategoryDaoManager get managers => HabitCategoryDaoManager(this);
}

class HabitCategoryDaoManager {
  final _$HabitCategoryDaoMixin _db;
  HabitCategoryDaoManager(this._db);
  $$HabitCategoriesTableTableManager get habitCategories =>
      $$HabitCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.habitCategories,
      );
}
