import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/achievements.dart';
import '../tables/user_gamification.dart';

part 'gamification_dao.g.dart';

@DriftAccessor(tables: [Achievements, UserGamification])
class GamificationDao extends DatabaseAccessor<AppDatabase> with _$GamificationDaoMixin {
  GamificationDao(super.db);

  Stream<List<AchievementRow>> watchAllAchievements() {
    return select(achievements).watch();
  }

  Future<List<AchievementRow>> getAllAchievementsOnce() {
    return select(achievements).get();
  }

  Future<AchievementRow?> getAchievementById(String id) {
    return (select(achievements)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertAchievement(AchievementsCompanion entity) {
    return into(achievements).insertOnConflictUpdate(entity);
  }

  Future<void> upsertAchievements(List<AchievementsCompanion> entities) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(achievements, entities);
    });
  }

  Stream<UserGamificationRow?> watchUserGamification() {
    return (select(userGamification)..where((u) => u.id.equals('user_gamification')))
        .watchSingleOrNull();
  }

  Future<UserGamificationRow?> getUserGamificationOnce() {
    return (select(userGamification)..where((u) => u.id.equals('user_gamification')))
        .getSingleOrNull();
  }

  Future<void> upsertUserGamification(UserGamificationCompanion entity) {
    return into(userGamification).insertOnConflictUpdate(entity);
  }
}
