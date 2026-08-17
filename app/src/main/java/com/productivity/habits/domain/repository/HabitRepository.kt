package com.productivity.habits.domain.repository

import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitLogEntity
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

interface HabitRepository {

    // Habits
    fun getAllHabits(): Flow<List<HabitEntity>>
    fun getActiveHabits(): Flow<List<HabitEntity>>
    fun getArchivedHabits(): Flow<List<HabitEntity>>
    fun getPinnedHabits(): Flow<List<HabitEntity>>
    fun getHabitById(id: String): Flow<HabitEntity?>
    suspend fun getHabitByIdOnce(id: String): HabitEntity?
    fun getHabitsByCategory(categoryId: String): Flow<List<HabitEntity>>
    suspend fun upsertHabit(habit: HabitEntity)
    suspend fun deleteHabit(habit: HabitEntity)
    suspend fun setPinned(id: String, pinned: Boolean)
    suspend fun setArchived(id: String, archived: Boolean)

    // Logs
    fun getLogsForHabit(habitId: String): Flow<List<HabitLogEntity>>
    suspend fun getLogsForHabitOnce(habitId: String): List<HabitLogEntity>
    fun getLogsForDate(date: LocalDate): Flow<List<HabitLogEntity>>
    suspend fun getLogsForDateOnce(date: LocalDate): List<HabitLogEntity>
    fun getLogsForHabitAndDate(habitId: String, date: LocalDate): Flow<List<HabitLogEntity>>
    fun getLogsForDateRange(startDate: LocalDate, endDate: LocalDate): Flow<List<HabitLogEntity>>
    suspend fun getLogsForDateRangeOnce(startDate: LocalDate, endDate: LocalDate): List<HabitLogEntity>
    fun getAllLogs(): Flow<List<HabitLogEntity>>
    suspend fun getAllLogsOnce(): List<HabitLogEntity>
    suspend fun logCheckIn(
        habitId: String,
        date: LocalDate,
        completed: Boolean,
        value: Double? = null,
        durationSeconds: Long? = null,
        intervalIndex: Int? = null,
        note: String? = null
    )
    suspend fun toggleBooleanCheckIn(habitId: String, date: LocalDate)
    suspend fun updateNumericValue(habitId: String, date: LocalDate, value: Double)
    suspend fun addNumericDelta(habitId: String, date: LocalDate, delta: Double)
    suspend fun toggleSlotCheckIn(habitId: String, date: LocalDate, slotIndex: Int)
    suspend fun deleteLogsForHabitAndDate(habitId: String, date: LocalDate)

    // Categories
    fun getAllCategories(): Flow<List<HabitCategoryEntity>>
    suspend fun getAllCategoriesOnce(): List<HabitCategoryEntity>
    fun getCategoryById(id: String): Flow<HabitCategoryEntity?>
    suspend fun upsertCategory(category: HabitCategoryEntity)
    suspend fun deleteCategory(category: HabitCategoryEntity)
}
