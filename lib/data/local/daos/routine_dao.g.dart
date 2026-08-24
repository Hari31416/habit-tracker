// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_dao.dart';

// ignore_for_file: type=lint
mixin _$RoutineDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitRoutinesTable get habitRoutines => attachedDatabase.habitRoutines;
  $RoutineLogsTable get routineLogs => attachedDatabase.routineLogs;
  RoutineDaoManager get managers => RoutineDaoManager(this);
}

class RoutineDaoManager {
  final _$RoutineDaoMixin _db;
  RoutineDaoManager(this._db);
  $$HabitRoutinesTableTableManager get habitRoutines =>
      $$HabitRoutinesTableTableManager(_db.attachedDatabase, _db.habitRoutines);
  $$RoutineLogsTableTableManager get routineLogs =>
      $$RoutineLogsTableTableManager(_db.attachedDatabase, _db.routineLogs);
}
