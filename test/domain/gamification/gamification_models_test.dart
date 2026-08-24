import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/gamification/gamification_models.dart';
import 'package:habit_tracker/domain/gamification/player_title.dart';

void main() {
  group('Gamification Models', () {
    test('AchievementCategory and AchievementTier properties', () {
      expect(AchievementCategory.streak.displayName, 'Streaks');
      expect(AchievementTier.bronze.displayName, 'Bronze');
      expect(AchievementTier.bronze.hexColor, '#CD7F32');
    });

    test('AchievementDefinition equality and hashing', () {
      const def1 = AchievementDefinition(
        id: 'streak_7',
        title: '7 Day Streak',
        description: 'Maintain 7 days',
        category: AchievementCategory.streak,
        tier: AchievementTier.bronze,
        iconName: 'flame',
        xpReward: 50,
        targetValue: 7,
        unit: 'days',
      );

      const def2 = AchievementDefinition(
        id: 'streak_7',
        title: '7 Day Streak',
        description: 'Maintain 7 days',
        category: AchievementCategory.streak,
        tier: AchievementTier.bronze,
        iconName: 'flame',
        xpReward: 50,
        targetValue: 7,
        unit: 'days',
      );

      expect(def1, equals(def2));
      expect(def1.hashCode, equals(def2.hashCode));
    });

    test('AchievementStatus equality and progress tracking', () {
      const def = AchievementDefinition(
        id: 'streak_7',
        title: '7 Day Streak',
        description: 'Maintain 7 days',
        category: AchievementCategory.streak,
        tier: AchievementTier.bronze,
        iconName: 'flame',
        xpReward: 50,
        targetValue: 7,
        unit: 'days',
      );

      final status1 = AchievementStatus(
        definition: def,
        isUnlocked: true,
        currentProgress: 7,
        progressFraction: 1.0,
        unlockedAt: DateTime.parse('2026-08-24T12:00:00Z'),
      );

      final status2 = AchievementStatus(
        definition: def,
        isUnlocked: true,
        currentProgress: 7,
        progressFraction: 1.0,
        unlockedAt: DateTime.parse('2026-08-24T12:00:00Z'),
      );

      expect(status1, equals(status2));
      expect(status1.hashCode, equals(status2.hashCode));
    });

    test('PlayerProgression default values and equality', () {
      const prog1 = PlayerProgression(
        totalXp: 150,
        level: 2,
        title: PlayerTitle.apprentice,
      );

      const prog2 = PlayerProgression(
        totalXp: 150,
        level: 2,
        title: PlayerTitle.apprentice,
      );

      expect(prog1, equals(prog2));
      expect(prog1.hashCode, equals(prog2.hashCode));
    });

    test('LevelUpCelebration equality', () {
      const celeb1 = LevelUpCelebration(
        newLevel: 3,
        previousLevel: 2,
        title: PlayerTitle.pathfinder,
        titleChanged: true,
      );

      const celeb2 = LevelUpCelebration(
        newLevel: 3,
        previousLevel: 2,
        title: PlayerTitle.pathfinder,
        titleChanged: true,
      );

      expect(celeb1, equals(celeb2));
      expect(celeb1.hashCode, equals(celeb2.hashCode));
    });
  });
}
