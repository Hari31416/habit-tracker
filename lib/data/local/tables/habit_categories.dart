import 'package:drift/drift.dart';

@DataClassName('HabitCategoryRow')
class HabitCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
