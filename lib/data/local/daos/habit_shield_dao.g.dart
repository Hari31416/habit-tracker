// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_shield_dao.dart';

// ignore_for_file: type=lint
mixin _$HabitShieldDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitsTable get habits => attachedDatabase.habits;
  $HabitShieldsTable get habitShields => attachedDatabase.habitShields;
  HabitShieldDaoManager get managers => HabitShieldDaoManager(this);
}

class HabitShieldDaoManager {
  final _$HabitShieldDaoMixin _db;
  HabitShieldDaoManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db.attachedDatabase, _db.habits);
  $$HabitShieldsTableTableManager get habitShields =>
      $$HabitShieldsTableTableManager(_db.attachedDatabase, _db.habitShields);
}
