package com.productivity.habits.data.local

import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import com.productivity.habits.data.local.dao.HabitCategoryDao
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.dao.HabitLogDao
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitTargetType
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.Instant
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

                categoryDao.insertDefaultCategories(DEFAULT_CATEGORIES)

                val existingHabits = habitDao.getActiveHabitsOnce()
                if (existingHabits.isEmpty()) {
                    val now = Instant.now()

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
                            createdAt = now,
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
                            createdAt = now,
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
                            createdAt = now,
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
                            createdAt = now,
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
                            createdAt = now,
                            updatedAt = now
                        )
                    )
                    habitDao.insertHabits(habits)
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
