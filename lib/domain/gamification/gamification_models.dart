import 'player_title.dart';

enum AchievementCategory {
  all('All'),
  streak('Streaks'),
  volume('Volume'),
  diversity('Diversity'),
  perfectDays('Perfect Days'),
  focus('Focus'),
  mastery('Mastery');

  final String displayName;
  const AchievementCategory(this.displayName);
}

enum AchievementTier {
  bronze('Bronze', '#CD7F32'),
  silver('Silver', '#A0AEC0'),
  gold('Gold', '#F59E0B'),
  platinum('Platinum', '#8B5CF6');

  final String displayName;
  final String hexColor;
  const AchievementTier(this.displayName, this.hexColor);
}

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final AchievementTier tier;
  final String iconName;
  final int xpReward;
  final int targetValue;
  final String unit;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tier,
    required this.iconName,
    required this.xpReward,
    required this.targetValue,
    required this.unit,
  });
}

class AchievementStatus {
  final AchievementDefinition definition;
  final bool isUnlocked;
  final int currentProgress;
  final double progressFraction;
  final DateTime? unlockedAt;

  const AchievementStatus({
    required this.definition,
    required this.isUnlocked,
    required this.currentProgress,
    required this.progressFraction,
    this.unlockedAt,
  });
}

class PlayerProgression {
  final int totalXp;
  final int level;
  final PlayerTitle title;
  final int currentLevelBaseXp;
  final int nextLevelTargetXp;
  final double progressFraction;
  final double activeStreakMultiplier;
  final int longestActiveStreak;
  final int unlockedBadgesCount;
  final int totalBadgesCount;

  const PlayerProgression({
    this.totalXp = 0,
    this.level = 1,
    this.title = PlayerTitle.novice,
    this.currentLevelBaseXp = 0,
    this.nextLevelTargetXp = 100,
    this.progressFraction = 0.0,
    this.activeStreakMultiplier = 1.0,
    this.longestActiveStreak = 0,
    this.unlockedBadgesCount = 0,
    this.totalBadgesCount = 0,
  });
}

class LevelUpCelebration {
  final int newLevel;
  final int previousLevel;
  final PlayerTitle title;
  final bool titleChanged;

  const LevelUpCelebration({
    required this.newLevel,
    required this.previousLevel,
    required this.title,
    required this.titleChanged,
  });
}
