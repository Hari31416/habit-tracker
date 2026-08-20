import 'package:drift/drift.dart';
import 'habits.dart';

@DataClassName('HabitLogRow')
@TableIndex(name: 'idx_habit_logs_habit_id', columns: {#habitId})
@TableIndex(name: 'idx_habit_logs_date', columns: {#date})
@TableIndex(name: 'idx_habit_logs_habit_id_date', columns: {#habitId, #date})
@TableIndex(name: 'idx_habit_logs_natural_key', columns: {#habitId, #date, #intervalIndex})
class HabitLogs extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text()(); // ISO Date format "yyyy-MM-dd"
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get intervalIndex => integer().nullable()();
  BoolColumn get completed => boolean()();
  RealColumn get value => real().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get energyLevel => integer().nullable()(); // 1 to 5 scale
  TextColumn get mood => text().nullable()(); // mood tag: energized, happy, calm, tired, stressed, focused
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
