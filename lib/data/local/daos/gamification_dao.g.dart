// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_dao.dart';

// ignore_for_file: type=lint
mixin _$GamificationDaoMixin on DatabaseAccessor<AppDatabase> {
  $AchievementsTable get achievements => attachedDatabase.achievements;
  $UserGamificationTable get userGamification =>
      attachedDatabase.userGamification;
  GamificationDaoManager get managers => GamificationDaoManager(this);
}

class GamificationDaoManager {
  final _$GamificationDaoMixin _db;
  GamificationDaoManager(this._db);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db.attachedDatabase, _db.achievements);
  $$UserGamificationTableTableManager get userGamification =>
      $$UserGamificationTableTableManager(
        _db.attachedDatabase,
        _db.userGamification,
      );
}
