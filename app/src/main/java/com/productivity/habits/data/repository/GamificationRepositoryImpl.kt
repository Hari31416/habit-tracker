package com.productivity.habits.data.repository

import com.productivity.habits.data.local.dao.GamificationDao
import com.productivity.habits.data.local.dao.HabitCategoryDao
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.dao.HabitLogDao
import com.productivity.habits.data.local.entity.AchievementEntity
import com.productivity.habits.data.local.entity.UserGamificationEntity
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.domain.gamification.AchievementDefinitions
import com.productivity.habits.domain.gamification.AchievementEvaluator
import com.productivity.habits.domain.gamification.AchievementStatus
import com.productivity.habits.domain.gamification.GamificationEngine
import com.productivity.habits.domain.gamification.LevelUpCelebration
import com.productivity.habits.domain.gamification.PlayerProgression
import com.productivity.habits.domain.gamification.PlayerTitle
import com.productivity.habits.domain.repository.GamificationRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class GamificationRepositoryImpl @Inject constructor(
    private val habitDao: HabitDao,
    private val habitLogDao: HabitLogDao,
    private val habitCategoryDao: HabitCategoryDao,
    private val gamificationDao: GamificationDao
) : GamificationRepository {

    private val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    private data class CombinedGamificationData(
        val progression: PlayerProgression,
        val achievements: List<AchievementStatus>,
        val celebration: LevelUpCelebration?
    )

    private val gamificationStream: Flow<CombinedGamificationData> = combine(
        habitDao.getAllHabits(),
        habitLogDao.getAllLogs(),
        habitCategoryDao.getAllCategories(),
        gamificationDao.getAllAchievements(),
        gamificationDao.getUserGamification()
    ) { habits, logs, categories, storedAchievements, userGamification ->
        val storedMap = storedAchievements.associate { it.id to it.unlockedAt }
        val habitsMap = habits.associateBy { it.id }
        val logsByHabit = logs.groupBy { it.habitId }
        val logsByDate = logs.groupBy { it.date }
        val today = LocalDate.now()

        // 1. Calculate streaks per habit to find multipliers
        val streaks = habits.map { habit ->
            val habitLogs = logsByHabit[habit.id] ?: emptyList()
            StreakCalculator.calculateStreak(habit, habitLogs, today)
        }
        val longestStreak = streaks.maxOfOrNull { maxOf(it.currentStreak, it.bestStreak) } ?: 0
        val activeStreakMultiplier = GamificationEngine.calculateStreakMultiplier(longestStreak)

        // 2. Calculate Base Habit Check-in XP
        var habitCheckInXp = 0L
        for (habit in habits) {
            val habitLogs = logsByHabit[habit.id] ?: emptyList()
            val habitLogsByDate = habitLogs.groupBy { it.date }
            val streak = StreakCalculator.calculateStreak(habit, habitLogs, today)
            val habitMultiplier = GamificationEngine.calculateStreakMultiplier(streak.currentStreak)

            for ((_, dayLogs) in habitLogsByDate) {
                val isCompleted = StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)
                val baseXp = GamificationEngine.calculateHabitDayBaseXp(habit, dayLogs, isCompleted)
                if (baseXp > 0) {
                    habitCheckInXp += GamificationEngine.applyMultiplier(baseXp, habitMultiplier)
                }
            }
        }

        // 3. Perfect Days XP Bonus
        var perfectDaysBonusXp = 0L
        val allDates = logsByDate.keys.mapNotNull {
            try { LocalDate.parse(it, dateFormatter) } catch (e: Exception) { null }
        }
        for (date in allDates) {
            val scheduled = habits.filter { !it.archived && StreakCalculator.isHabitScheduledOnDate(it, date) }
            if (scheduled.isNotEmpty()) {
                val dateStr = date.format(dateFormatter)
                val allCompleted = scheduled.all { h ->
                    val dayLogs = (logsByHabit[h.id] ?: emptyList()).filter { it.date == dateStr }
                    StreakCalculator.isHabitCompletedOnDate(h, dayLogs)
                }
                if (allCompleted) {
                    perfectDaysBonusXp += GamificationEngine.PERFECT_DAY_BONUS_XP
                }
            }
        }

        // 4. Achievement Evaluation (first pass for levels & progress)
        val initialTotalXp = habitCheckInXp + perfectDaysBonusXp
        val estimatedProgression = GamificationEngine.calculateProgression(initialTotalXp, longestStreak)

        val evaluationContext = AchievementEvaluator.EvaluationContext(
            habits = habits,
            allLogs = logs,
            categories = categories,
            currentLevel = estimatedProgression.level,
            storedUnlocks = storedMap,
            referenceDate = today
        )
        val evaluatedAchievements = AchievementEvaluator.evaluateAll(evaluationContext)

        // 5. XP from Unlocked Achievements
        val achievementsXp = evaluatedAchievements
            .filter { it.isUnlocked }
            .sumOf { it.definition.xpReward.toLong() }

        val finalTotalXp = habitCheckInXp + perfectDaysBonusXp + achievementsXp
        val unlockedCount = evaluatedAchievements.count { it.isUnlocked }
        val totalCount = evaluatedAchievements.size

        val finalProgression = GamificationEngine.calculateProgression(
            totalXp = finalTotalXp,
            longestActiveStreak = longestStreak,
            unlockedBadgesCount = unlockedCount,
            totalBadgesCount = totalCount
        )

        // 6. Level Up Celebration Check
        val lastCelebrated = userGamification?.lastCelebratedLevel ?: 1
        var celebration: LevelUpCelebration? = null
        if (finalProgression.level > lastCelebrated) {
            val prevTitle = PlayerTitle.fromLevel(lastCelebrated)
            celebration = LevelUpCelebration(
                newLevel = finalProgression.level,
                previousLevel = lastCelebrated,
                title = finalProgression.title,
                titleChanged = finalProgression.title != prevTitle
            )
        }

        // 7. Persist newly unlocked achievements if not saved
        val newlyUnlocked = evaluatedAchievements.filter { it.isUnlocked && !storedMap.containsKey(it.definition.id) }
        if (newlyUnlocked.isNotEmpty()) {
            val entities = newlyUnlocked.map {
                AchievementEntity(
                    id = it.definition.id,
                    unlockedAt = it.unlockedAt ?: Instant.now(),
                    progress = it.currentProgress,
                    notified = false
                )
            }
            gamificationDao.upsertAchievements(entities)
        }

        CombinedGamificationData(
            progression = finalProgression,
            achievements = evaluatedAchievements,
            celebration = celebration
        )
    }

    override fun getPlayerProgression(): Flow<PlayerProgression> =
        gamificationStream.map { it.progression }

    override fun getAchievements(): Flow<List<AchievementStatus>> =
        gamificationStream.map { it.achievements }

    override fun getPendingCelebration(): Flow<LevelUpCelebration?> =
        gamificationStream.map { it.celebration }

    override suspend fun dismissCelebration(level: Int) {
        val current = gamificationDao.getUserGamificationOnce()
        gamificationDao.upsertUserGamification(
            UserGamificationEntity(
                id = "user_gamification",
                totalXp = current?.totalXp ?: 0L,
                currentLevel = maxOf(level, current?.currentLevel ?: 1),
                lastCelebratedLevel = maxOf(level, current?.lastCelebratedLevel ?: 1),
                updatedAt = Instant.now()
            )
        )
    }
}
