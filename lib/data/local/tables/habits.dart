import 'package:drift/drift.dart';
import '../converters/type_converters.dart';

@DataClassName('HabitRow')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get color => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get frequencyType => text().map(const HabitFrequencyTypeConverter())();
  TextColumn get targetDaysOfWeek => text().map(const IntListConverter()).nullable()();
  IntColumn get targetCountPerWeek => integer().nullable()();
  IntColumn get intervalHours => integer().nullable()();
  IntColumn get timesPerDay => integer().nullable()();
  TextColumn get timeWindow => text().map(const TimeWindowConverter()).nullable()();
  TextColumn get targetType => text().map(const HabitTargetTypeConverter())();
  RealColumn get targetValue => real().nullable()();
  TextColumn get unit => text().nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  TextColumn get reminderTimes => text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get motivationNotes => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
