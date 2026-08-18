import 'package:drift/drift.dart';

@DataClassName('AchievementRow')
class Achievements extends Table {
  TextColumn get id => text()();
  DateTimeColumn get unlockedAt => dateTime()();
  IntColumn get progress => integer()();
  BoolColumn get notified => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
