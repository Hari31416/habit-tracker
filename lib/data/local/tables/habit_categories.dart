import 'package:drift/drift.dart';

@DataClassName('HabitCategoryRow')
class HabitCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  TextColumn get icon => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
