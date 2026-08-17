package com.productivity.habits.data.local

import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import com.productivity.habits.data.local.dao.HabitCategoryDao
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.dao.HabitLogDao
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.UUID
import javax.inject.Provider

class PrepopulateDataCallback(
    private val categoryDaoProvider: Provider<HabitCategoryDao>,
    private val habitDaoProvider: Provider<HabitDao>,
    private val habitLogDaoProvider: Provider<HabitLogDao>
) : RoomDatabase.Callback() {

    override fun onCreate(db: SupportSQLiteDatabase) {
        super.onCreate(db)
        seedIfEmpty()
    }

    override fun onOpen(db: SupportSQLiteDatabase) {
        super.onOpen(db)
        seedIfEmpty()
    }

    private fun seedIfEmpty() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val categoryDao = categoryDaoProvider.get()
                val habitDao = habitDaoProvider.get()
                val habitLogDao = habitLogDaoProvider.get()

                categoryDao.insertDefaultCategories(DEFAULT_CATEGORIES)

                val existingHabits = habitDao.getActiveHabitsOnce()
                if (existingHabits.isEmpty()) {
                    val now = Instant.now()
                    val today = LocalDate.now()
                    val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

                    val habits = listOf(
                        HabitEntity(
                            id = "seed_habit_deep_work",
                            title = "Deep Work Session",
                            description = "Focus on high-leverage engineering tasks without distractions",
                            color = "#3B82F6",
                            icon = "zap",
                            categoryId = "cat_productivity",
                            frequencyType = HabitFrequencyType.DAILY,
                            targetType = HabitTargetType.TIMER,
                            targetValue = 45.0,
                            unit = "mins",
                            pinned = true,
                            createdAt = now.minusSeconds(14 * 86400L),
                            updatedAt = now
                        ),
                        HabitEntity(
                            id = "seed_habit_meditation",
                            title = "Morning Meditation",
                            description = "10 minutes of mindfulness and breath awareness",
                            color = "#8B5CF6",
                            icon = "brain",
                            categoryId = "cat_mindfulness",
                            frequencyType = HabitFrequencyType.DAILY,
                            targetType = HabitTargetType.BOOLEAN,
                            pinned = true,
                            createdAt = now.minusSeconds(10 * 86400L),
                            updatedAt = now
                        ),
                        HabitEntity(
                            id = "seed_habit_read",
                            title = "Read 20 Pages",
                            description = "Non-fiction, books, or technical papers",
                            color = "#10B981",
                            icon = "book-open",
                            categoryId = "cat_learning",
                            frequencyType = HabitFrequencyType.DAILY,
                            targetType = HabitTargetType.NUMERIC,
                            targetValue = 20.0,
                            unit = "pages",
                            createdAt = now.minusSeconds(8 * 86400L),
                            updatedAt = now
                        ),
                        HabitEntity(
                            id = "seed_habit_water",
                            title = "Hydration Intake",
                            description = "Drink 8 glasses of water throughout the day",
                            color = "#0EA5E9",
                            icon = "droplet",
                            categoryId = "cat_health_fitness",
                            frequencyType = HabitFrequencyType.TIMES_PER_DAY,
                            timesPerDay = 4,
                            targetType = HabitTargetType.BOOLEAN,
                            createdAt = now.minusSeconds(6 * 86400L),
                            updatedAt = now
                        ),
                        HabitEntity(
                            id = "seed_habit_evening_review",
                            title = "Evening Reflection",
                            description = "Review daily wins and plan next day priorities",
                            color = "#F59E0B",
                            icon = "sun",
                            categoryId = "cat_personal",
                            frequencyType = HabitFrequencyType.DAILY,
                            targetType = HabitTargetType.BOOLEAN,
                            createdAt = now.minusSeconds(7 * 86400L),
                            updatedAt = now
                        )
                    )
                    habitDao.insertHabits(habits)

                    val logs = mutableListOf<HabitLogEntity>()

                    // 1. Deep work: 14 days consecutive streak (45 mins per day) -> unlocks Fortitude & 1.5x multiplier
                    for (i in 0 until 14) {
                        val d = today.minusDays(i.toLong()).format(formatter)
                        logs.add(
                            HabitLogEntity(
                                id = UUID.randomUUID().toString(),
                                habitId = "seed_habit_deep_work",
                                date = d,
                                timestamp = now.minusSeconds(i * 86400L),
                                completed = true,
                                value = 45.0,
                                durationSeconds = 2700L,
                                createdAt = now,
                                updatedAt = now
                            )
                        )
                    }

                    // 2. Meditation: 8 days consecutive streak
                    for (i in 0 until 8) {
                        val d = today.minusDays(i.toLong()).format(formatter)
                        logs.add(
                            HabitLogEntity(
                                id = UUID.randomUUID().toString(),
                                habitId = "seed_habit_meditation",
                                date = d,
                                timestamp = now.minusSeconds(i * 86400L),
                                completed = true,
                                createdAt = now,
                                updatedAt = now
                            )
                        )
                    }

                    // 3. Reading: 5 days streak
                    for (i in 1..5) {
                        val d = today.minusDays(i.toLong()).format(formatter)
                        logs.add(
                            HabitLogEntity(
                                id = UUID.randomUUID().toString(),
                                habitId = "seed_habit_read",
                                date = d,
                                timestamp = now.minusSeconds(i * 86400L),
                                completed = true,
                                value = 20.0,
                                createdAt = now,
                                updatedAt = now
                            )
                        )
                    }

                    // 4. Hydration: 3 slots completed today
                    for (slot in 0 until 3) {
                        logs.add(
                            HabitLogEntity(
                                id = UUID.randomUUID().toString(),
                                habitId = "seed_habit_water",
                                date = today.format(formatter),
                                timestamp = now,
                                intervalIndex = slot,
                                completed = true,
                                createdAt = now,
                                updatedAt = now
                            )
                        )
                    }

                    habitLogDao.insertLogs(logs)
                }
            } catch (e: Exception) {
                // Log or ignore on pre-existing data
            }
        }
    }

    companion object {
        val DEFAULT_CATEGORIES = listOf(
            HabitCategoryEntity(
                id = "cat_health_fitness",
                name = "Health & Fitness",
                color = "#10B981",
                icon = "activity"
            ),
            HabitCategoryEntity(
                id = "cat_mindfulness",
                name = "Mindfulness",
                color = "#8B5CF6",
                icon = "brain"
            ),
            HabitCategoryEntity(
                id = "cat_learning",
                name = "Learning",
                color = "#3B82F6",
                icon = "book-open"
            ),
            HabitCategoryEntity(
                id = "cat_productivity",
                name = "Productivity",
                color = "#F59E0B",
                icon = "zap"
            ),
            HabitCategoryEntity(
                id = "cat_personal",
                name = "Personal",
                color = "#EC4899",
                icon = "heart"
            ),
            HabitCategoryEntity(
                id = "cat_routine",
                name = "Routine",
                color = "#6366F1",
                icon = "clock"
            )
        )
    }
}
