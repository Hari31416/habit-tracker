package com.productivity.habits.domain.gamification

object AchievementDefinitions {

    val ALL_ACHIEVEMENTS: List<AchievementDefinition> = listOf(
        // Streak Milestones
        AchievementDefinition(
            id = "streak_3",
            title = "Spark of Will",
            description = "Maintain an active streak of at least 3 days on any habit.",
            category = AchievementCategory.STREAK,
            tier = AchievementTier.BRONZE,
            iconName = "flame",
            xpReward = 50,
            targetValue = 3,
            unit = "days"
        ),
        AchievementDefinition(
            id = "streak_7",
            title = "Habit Builder",
            description = "Reach a 7-day streak and unlock the 1.25x streak XP multiplier.",
            category = AchievementCategory.STREAK,
            tier = AchievementTier.BRONZE,
            iconName = "flame",
            xpReward = 100,
            targetValue = 7,
            unit = "days"
        ),
        AchievementDefinition(
            id = "streak_14",
            title = "Fortitude",
            description = "Reach a 14-day streak and unlock the 1.5x streak XP multiplier.",
            category = AchievementCategory.STREAK,
            tier = AchievementTier.SILVER,
            iconName = "zap",
            xpReward = 200,
            targetValue = 14,
            unit = "days"
        ),
        AchievementDefinition(
            id = "streak_21",
            title = "Unstoppable Force",
            description = "Build a 21-day unbroken habit streak.",
            category = AchievementCategory.STREAK,
            tier = AchievementTier.SILVER,
            iconName = "shield",
            xpReward = 300,
            targetValue = 21,
            unit = "days"
        ),
        AchievementDefinition(
            id = "streak_30",
            title = "Iron Discipline",
            description = "Conquer a 30-day streak and unlock the 2.0x maximum streak XP multiplier.",
            category = AchievementCategory.STREAK,
            tier = AchievementTier.GOLD,
            iconName = "award",
            xpReward = 500,
            targetValue = 30,
            unit = "days"
        ),
        AchievementDefinition(
            id = "streak_100",
            title = "Centurion",
            description = "Achieve a legendary 100-day unbroken streak.",
            category = AchievementCategory.STREAK,
            tier = AchievementTier.PLATINUM,
            iconName = "crown",
            xpReward = 1500,
            targetValue = 100,
            unit = "days"
        ),

        // Volume & Habit Completions
        AchievementDefinition(
            id = "vol_1",
            title = "First Step",
            description = "Complete your very first habit check-in.",
            category = AchievementCategory.VOLUME,
            tier = AchievementTier.BRONZE,
            iconName = "check",
            xpReward = 25,
            targetValue = 1,
            unit = "completions"
        ),
        AchievementDefinition(
            id = "vol_10",
            title = "Tenacious",
            description = "Log 10 total habit completions across all habits.",
            category = AchievementCategory.VOLUME,
            tier = AchievementTier.BRONZE,
            iconName = "trending_up",
            xpReward = 75,
            targetValue = 10,
            unit = "completions"
        ),
        AchievementDefinition(
            id = "vol_50",
            title = "Half Century",
            description = "Reach 50 total habit completions.",
            category = AchievementCategory.VOLUME,
            tier = AchievementTier.SILVER,
            iconName = "star",
            xpReward = 200,
            targetValue = 50,
            unit = "completions"
        ),
        AchievementDefinition(
            id = "vol_100",
            title = "Century Club",
            description = "Reach 100 total habit completions.",
            category = AchievementCategory.VOLUME,
            tier = AchievementTier.GOLD,
            iconName = "medal",
            xpReward = 400,
            targetValue = 100,
            unit = "completions"
        ),
        AchievementDefinition(
            id = "vol_500",
            title = "Master of Routine",
            description = "Accumulate 500 total habit completions.",
            category = AchievementCategory.VOLUME,
            tier = AchievementTier.PLATINUM,
            iconName = "trophy",
            xpReward = 1000,
            targetValue = 500,
            unit = "completions"
        ),
        AchievementDefinition(
            id = "vol_1000",
            title = "Habit Legend",
            description = "Achieve 1,000 total habit completions.",
            category = AchievementCategory.VOLUME,
            tier = AchievementTier.PLATINUM,
            iconName = "crown",
            xpReward = 2500,
            targetValue = 1000,
            unit = "completions"
        ),

        // Category Diversity
        AchievementDefinition(
            id = "div_2_cats",
            title = "Balanced Life",
            description = "Complete habits across at least 2 different categories.",
            category = AchievementCategory.DIVERSITY,
            tier = AchievementTier.BRONZE,
            iconName = "layers",
            xpReward = 50,
            targetValue = 2,
            unit = "categories"
        ),
        AchievementDefinition(
            id = "div_3_cats",
            title = "Renaissance Soul",
            description = "Complete habits across at least 3 different categories.",
            category = AchievementCategory.DIVERSITY,
            tier = AchievementTier.SILVER,
            iconName = "compass",
            xpReward = 150,
            targetValue = 3,
            unit = "categories"
        ),
        AchievementDefinition(
            id = "div_5_cats",
            title = "Polymath",
            description = "Complete habits across 5 or more different categories.",
            category = AchievementCategory.DIVERSITY,
            tier = AchievementTier.GOLD,
            iconName = "sparkles",
            xpReward = 350,
            targetValue = 5,
            unit = "categories"
        ),
        AchievementDefinition(
            id = "div_health_20",
            title = "Health Champion",
            description = "Complete 20 health or fitness habits.",
            category = AchievementCategory.DIVERSITY,
            tier = AchievementTier.SILVER,
            iconName = "heart",
            xpReward = 200,
            targetValue = 20,
            unit = "completions"
        ),
        AchievementDefinition(
            id = "div_prod_20",
            title = "Focus Titan",
            description = "Complete 20 productivity or work habits.",
            category = AchievementCategory.DIVERSITY,
            tier = AchievementTier.SILVER,
            iconName = "briefcase",
            xpReward = 200,
            targetValue = 20,
            unit = "completions"
        ),
        AchievementDefinition(
            id = "div_mind_20",
            title = "Mindful Master",
            description = "Complete 20 mindfulness or mental wellbeing habits.",
            category = AchievementCategory.DIVERSITY,
            tier = AchievementTier.SILVER,
            iconName = "sun",
            xpReward = 200,
            targetValue = 20,
            unit = "completions"
        ),

        // Perfect Days
        AchievementDefinition(
            id = "perf_1",
            title = "Flawless Day",
            description = "Complete 100% of all scheduled habits in a single day.",
            category = AchievementCategory.PERFECT_DAYS,
            tier = AchievementTier.BRONZE,
            iconName = "check_circle",
            xpReward = 50,
            targetValue = 1,
            unit = "perfect days"
        ),
        AchievementDefinition(
            id = "perf_3",
            title = "Triad of Perfection",
            description = "Log 3 perfect days where every scheduled habit is completed.",
            category = AchievementCategory.PERFECT_DAYS,
            tier = AchievementTier.SILVER,
            iconName = "check_circle",
            xpReward = 150,
            targetValue = 3,
            unit = "perfect days"
        ),
        AchievementDefinition(
            id = "perf_7",
            title = "Golden Week",
            description = "Achieve 7 consecutive perfect days in a row.",
            category = AchievementCategory.PERFECT_DAYS,
            tier = AchievementTier.GOLD,
            iconName = "calendar",
            xpReward = 400,
            targetValue = 7,
            unit = "consecutive days"
        ),
        AchievementDefinition(
            id = "perf_30",
            title = "Perfectionist",
            description = "Accumulate 30 total perfect days.",
            category = AchievementCategory.PERFECT_DAYS,
            tier = AchievementTier.PLATINUM,
            iconName = "trophy",
            xpReward = 1000,
            targetValue = 30,
            unit = "perfect days"
        ),

        // Focus & Time Mastery
        AchievementDefinition(
            id = "focus_60",
            title = "Deep Work",
            description = "Accumulate 60 minutes in focus timer habits.",
            category = AchievementCategory.FOCUS,
            tier = AchievementTier.BRONZE,
            iconName = "clock",
            xpReward = 75,
            targetValue = 60,
            unit = "mins"
        ),
        AchievementDefinition(
            id = "focus_300",
            title = "Flow State",
            description = "Accumulate 300 minutes in focus timer habits.",
            category = AchievementCategory.FOCUS,
            tier = AchievementTier.SILVER,
            iconName = "zap",
            xpReward = 250,
            targetValue = 300,
            unit = "mins"
        ),
        AchievementDefinition(
            id = "focus_1000",
            title = "Zen Master",
            description = "Accumulate 1,000 minutes in focus timer habits.",
            category = AchievementCategory.FOCUS,
            tier = AchievementTier.GOLD,
            iconName = "sparkles",
            xpReward = 750,
            targetValue = 1000,
            unit = "mins"
        ),

        // Player Level Mastery
        AchievementDefinition(
            id = "mastery_lvl_5",
            title = "Apprentice Ascent",
            description = "Level up to Level 5 and earn the Apprentice mastery title.",
            category = AchievementCategory.MASTERY,
            tier = AchievementTier.SILVER,
            iconName = "star",
            xpReward = 200,
            targetValue = 5,
            unit = "level"
        ),
        AchievementDefinition(
            id = "mastery_lvl_10",
            title = "Pathfinder Journey",
            description = "Level up to Level 10 and earn the Pathfinder mastery title.",
            category = AchievementCategory.MASTERY,
            tier = AchievementTier.GOLD,
            iconName = "compass",
            xpReward = 500,
            targetValue = 10,
            unit = "level"
        ),
        AchievementDefinition(
            id = "mastery_lvl_20",
            title = "Grandmaster Summit",
            description = "Level up to Level 20 and achieve the Grandmaster mastery title.",
            category = AchievementCategory.MASTERY,
            tier = AchievementTier.PLATINUM,
            iconName = "crown",
            xpReward = 1500,
            targetValue = 20,
            unit = "level"
        )
    )

    fun getById(id: String): AchievementDefinition? = ALL_ACHIEVEMENTS.find { it.id == id }
}
