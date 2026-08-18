// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_log_dao.dart';

// ignore_for_file: type=lint
mixin _$HabitLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitsTable get habits => attachedDatabase.habits;
  $HabitLogsTable get habitLogs => attachedDatabase.habitLogs;
  HabitLogDaoManager get managers => HabitLogDaoManager(this);
}

class HabitLogDaoManager {
  final _$HabitLogDaoMixin _db;
  HabitLogDaoManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db.attachedDatabase, _db.habits);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db.attachedDatabase, _db.habitLogs);
}
