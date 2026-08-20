import 'package:drift/drift.dart';
import 'habits.dart';

@DataClassName('HabitShieldRow')
@TableIndex(name: 'idx_habit_shields_habit_id', columns: {#habitId})
@TableIndex(name: 'idx_habit_shields_date', columns: {#date})
@TableIndex(name: 'idx_habit_shields_habit_id_date', columns: {#habitId, #date})
class HabitShields extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text()(); // ISO Date format "yyyy-MM-dd"
  BoolColumn get autoApplied => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
