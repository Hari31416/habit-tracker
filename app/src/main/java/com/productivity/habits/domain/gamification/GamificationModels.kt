package com.productivity.habits.domain.gamification

import java.time.Instant

enum class AchievementCategory(val displayName: String) {
    ALL("All"),
    STREAK("Streaks"),
    VOLUME("Volume"),
    DIVERSITY("Diversity"),
    PERFECT_DAYS("Perfect Days"),
    FOCUS("Focus"),
    MASTERY("Mastery")
}

enum class AchievementTier(val displayName: String, val hexColor: String) {
    BRONZE("Bronze", "#CD7F32"),
    SILVER("Silver", "#A0AEC0"),
    GOLD("Gold", "#F59E0B"),
    PLATINUM("Platinum", "#8B5CF6")
}

data class AchievementDefinition(
    val id: String,
    val title: String,
    val description: String,
    val category: AchievementCategory,
    val tier: AchievementTier,
    val iconName: String,
    val xpReward: Int,
    val targetValue: Int,
    val unit: String
)

data class AchievementStatus(
    val definition: AchievementDefinition,
    val isUnlocked: Boolean,
    val currentProgress: Int,
    val progressFraction: Float,
    val unlockedAt: Instant? = null
)

data class PlayerProgression(
    val totalXp: Long = 0L,
    val level: Int = 1,
    val title: PlayerTitle = PlayerTitle.NOVICE,
    val currentLevelBaseXp: Long = 0L,
    val nextLevelTargetXp: Long = 100L,
    val progressFraction: Float = 0.0f,
    val activeStreakMultiplier: Double = 1.0,
    val longestActiveStreak: Int = 0,
    val unlockedBadgesCount: Int = 0,
    val totalBadgesCount: Int = 0
)

data class LevelUpCelebration(
    val newLevel: Int,
    val previousLevel: Int,
    val title: PlayerTitle,
    val titleChanged: Boolean
)
