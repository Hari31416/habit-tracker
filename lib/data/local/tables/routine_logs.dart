import 'package:drift/drift.dart';
import '../converters/type_converters.dart';

@DataClassName('RoutineLogRow')
class RoutineLogs extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get completedHabitIds => text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
