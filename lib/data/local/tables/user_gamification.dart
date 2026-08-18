import 'package:drift/drift.dart';

@DataClassName('UserGamificationRow')
class UserGamification extends Table {
  TextColumn get id => text().withDefault(const Constant('user_gamification'))();
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get currentLevel => integer().withDefault(const Constant(1))();
  IntColumn get lastCelebratedLevel => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
