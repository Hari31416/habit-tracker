import 'package:drift/drift.dart';

@DataClassName('AchievementRow')
class Achievements extends Table {
  TextColumn get id => text()();
  DateTimeColumn get unlockedAt => dateTime()();
  IntColumn get progress => integer()();
  BoolColumn get notified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
