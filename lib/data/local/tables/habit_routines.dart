import 'package:drift/drift.dart';
import '../converters/type_converters.dart';

@DataClassName('HabitRoutineRow')
class HabitRoutines extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text()();
  TextColumn get targetTimeWindow => text().map(const TimeWindowConverter()).nullable()();
  TextColumn get habitIds => text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  IntColumn get bonusXp => integer().withDefault(const Constant(30))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
