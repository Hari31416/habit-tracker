import '../gamification/gamification_models.dart';

abstract class GamificationRepository {
  Stream<PlayerProgression> getPlayerProgression();
  Stream<List<AchievementStatus>> getAchievements();
  Stream<LevelUpCelebration?> getPendingCelebration();
  Future<void> dismissCelebration(int level);
}
