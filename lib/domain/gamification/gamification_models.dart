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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementDefinition &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          category == other.category &&
          tier == other.tier &&
          iconName == other.iconName &&
          xpReward == other.xpReward &&
          targetValue == other.targetValue &&
          unit == other.unit;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      category.hashCode ^
      tier.hashCode ^
      iconName.hashCode ^
      xpReward.hashCode ^
      targetValue.hashCode ^
      unit.hashCode;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementStatus &&
          runtimeType == other.runtimeType &&
          definition == other.definition &&
          isUnlocked == other.isUnlocked &&
          currentProgress == other.currentProgress &&
          progressFraction == other.progressFraction &&
          unlockedAt == other.unlockedAt;

  @override
  int get hashCode =>
      definition.hashCode ^
      isUnlocked.hashCode ^
      currentProgress.hashCode ^
      progressFraction.hashCode ^
      unlockedAt.hashCode;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProgression &&
          runtimeType == other.runtimeType &&
          totalXp == other.totalXp &&
          level == other.level &&
          title == other.title &&
          currentLevelBaseXp == other.currentLevelBaseXp &&
          nextLevelTargetXp == other.nextLevelTargetXp &&
          progressFraction == other.progressFraction &&
          activeStreakMultiplier == other.activeStreakMultiplier &&
          longestActiveStreak == other.longestActiveStreak &&
          unlockedBadgesCount == other.unlockedBadgesCount &&
          totalBadgesCount == other.totalBadgesCount;

  @override
  int get hashCode =>
      totalXp.hashCode ^
      level.hashCode ^
      title.hashCode ^
      currentLevelBaseXp.hashCode ^
      nextLevelTargetXp.hashCode ^
      progressFraction.hashCode ^
      activeStreakMultiplier.hashCode ^
      longestActiveStreak.hashCode ^
      unlockedBadgesCount.hashCode ^
      totalBadgesCount.hashCode;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelUpCelebration &&
          runtimeType == other.runtimeType &&
          newLevel == other.newLevel &&
          previousLevel == other.previousLevel &&
          title == other.title &&
          titleChanged == other.titleChanged;

  @override
  int get hashCode =>
      newLevel.hashCode ^
      previousLevel.hashCode ^
      title.hashCode ^
      titleChanged.hashCode;
}
