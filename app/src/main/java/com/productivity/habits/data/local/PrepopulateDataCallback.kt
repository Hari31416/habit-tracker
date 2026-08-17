package com.productivity.habits.data.local

import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import com.productivity.habits.data.local.dao.HabitCategoryDao
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Provider

class PrepopulateDataCallback(
    private val categoryDaoProvider: Provider<HabitCategoryDao>
) : RoomDatabase.Callback() {

    override fun onCreate(db: SupportSQLiteDatabase) {
        super.onCreate(db)
        CoroutineScope(Dispatchers.IO).launch {
            val categoryDao = categoryDaoProvider.get()
            categoryDao.insertDefaultCategories(DEFAULT_CATEGORIES)
        }
    }

    companion object {
        val DEFAULT_CATEGORIES = listOf(
            HabitCategoryEntity(
                id = "cat_health_fitness",
                name = "Health and Fitness",
                color = "#10b981",
                icon = "activity"
            ),
            HabitCategoryEntity(
                id = "cat_mindfulness",
                name = "Mindfulness",
                color = "#8b5cf6",
                icon = "brain"
            ),
            HabitCategoryEntity(
                id = "cat_learning",
                name = "Learning",
                color = "#3b82f6",
                icon = "book-open"
            ),
            HabitCategoryEntity(
                id = "cat_productivity",
                name = "Productivity",
                color = "#f59e0b",
                icon = "zap"
            ),
            HabitCategoryEntity(
                id = "cat_personal",
                name = "Personal",
                color = "#ec4899",
                icon = "heart"
            ),
            HabitCategoryEntity(
                id = "cat_routine",
                name = "Routine",
                color = "#6366f1",
                icon = "clock"
            )
        )
    }
}
