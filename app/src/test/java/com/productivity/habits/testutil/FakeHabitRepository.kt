package com.productivity.habits.testutil

import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.domain.repository.HabitRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.UUID

class FakeHabitRepository : HabitRepository {

    private val habitsFlow = MutableStateFlow<List<HabitEntity>>(emptyList())
    private val logsFlow = MutableStateFlow<List<HabitLogEntity>>(emptyList())
    private val categoriesFlow = MutableStateFlow<List<HabitCategoryEntity>>(emptyList())

    private val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    fun setHabits(habits: List<HabitEntity>) {
        habitsFlow.value = habits
    }

    fun setLogs(logs: List<HabitLogEntity>) {
        logsFlow.value = logs
    }

    fun setCategories(categories: List<HabitCategoryEntity>) {
        categoriesFlow.value = categories
    }

    override fun getAllHabits(): Flow<List<HabitEntity>> = habitsFlow

    override fun getActiveHabits(): Flow<List<HabitEntity>> =
        habitsFlow.map { list -> list.filter { !it.archived } }

    override fun getArchivedHabits(): Flow<List<HabitEntity>> =
        habitsFlow.map { list -> list.filter { it.archived } }

    override fun getPinnedHabits(): Flow<List<HabitEntity>> =
        habitsFlow.map { list -> list.filter { it.pinned && !it.archived } }

    override fun getHabitById(id: String): Flow<HabitEntity?> =
        habitsFlow.map { list -> list.find { it.id == id } }

    override suspend fun getHabitByIdOnce(id: String): HabitEntity? =
        habitsFlow.value.find { it.id == id }

    override fun getHabitsByCategory(categoryId: String): Flow<List<HabitEntity>> =
        habitsFlow.map { list -> list.filter { it.categoryId == categoryId } }

    override suspend fun upsertHabit(habit: HabitEntity) {
        val current = habitsFlow.value.toMutableList()
        val index = current.indexOfFirst { it.id == habit.id }
        if (index >= 0) {
            current[index] = habit
        } else {
            current.add(habit)
        }
        habitsFlow.value = current
    }

    override suspend fun deleteHabit(habit: HabitEntity) {
        habitsFlow.value = habitsFlow.value.filter { it.id != habit.id }
        logsFlow.value = logsFlow.value.filter { it.habitId != habit.id }
    }

    override suspend fun setPinned(id: String, pinned: Boolean) {
        val current = habitsFlow.value.toMutableList()
        val index = current.indexOfFirst { it.id == id }
        if (index >= 0) {
            current[index] = current[index].copy(pinned = pinned, updatedAt = Instant.now())
            habitsFlow.value = current
        }
    }

    override suspend fun setArchived(id: String, archived: Boolean) {
        val current = habitsFlow.value.toMutableList()
        val index = current.indexOfFirst { it.id == id }
        if (index >= 0) {
            current[index] = current[index].copy(archived = archived, updatedAt = Instant.now())
            habitsFlow.value = current
        }
    }

    override fun getLogsForHabit(habitId: String): Flow<List<HabitLogEntity>> =
        logsFlow.map { list -> list.filter { it.habitId == habitId } }

    override suspend fun getLogsForHabitOnce(habitId: String): List<HabitLogEntity> =
        logsFlow.value.filter { it.habitId == habitId }

    override fun getLogsForDate(date: LocalDate): Flow<List<HabitLogEntity>> {
        val dateStr = date.format(dateFormatter)
        return logsFlow.map { list -> list.filter { it.date == dateStr } }
    }

    override suspend fun getLogsForDateOnce(date: LocalDate): List<HabitLogEntity> {
        val dateStr = date.format(dateFormatter)
        return logsFlow.value.filter { it.date == dateStr }
    }

    override fun getLogsForHabitAndDate(habitId: String, date: LocalDate): Flow<List<HabitLogEntity>> {
        val dateStr = date.format(dateFormatter)
        return logsFlow.map { list -> list.filter { it.habitId == habitId && it.date == dateStr } }
    }

    override fun getLogsForDateRange(startDate: LocalDate, endDate: LocalDate): Flow<List<HabitLogEntity>> =
        logsFlow.map { list ->
            list.filter { log ->
                val logDate = LocalDate.parse(log.date)
                !logDate.isBefore(startDate) && !logDate.isAfter(endDate)
            }
        }

    override suspend fun getLogsForDateRangeOnce(
        startDate: LocalDate,
        endDate: LocalDate
    ): List<HabitLogEntity> = logsFlow.value.filter { log ->
        val logDate = LocalDate.parse(log.date)
        !logDate.isBefore(startDate) && !logDate.isAfter(endDate)
    }

    override fun getAllLogs(): Flow<List<HabitLogEntity>> = logsFlow

    override suspend fun getAllLogsOnce(): List<HabitLogEntity> = logsFlow.value

    override suspend fun logCheckIn(
        habitId: String,
        date: LocalDate,
        completed: Boolean,
        value: Double?,
        durationSeconds: Long?,
        intervalIndex: Int?,
        note: String?
    ) {
        val now = Instant.now()
        val log = HabitLogEntity(
            id = UUID.randomUUID().toString(),
            habitId = habitId,
            date = date.format(dateFormatter),
            timestamp = now,
            intervalIndex = intervalIndex,
            completed = completed,
            value = value,
            durationSeconds = durationSeconds,
            note = note,
            createdAt = now,
            updatedAt = now
        )
        val current = logsFlow.value.toMutableList()
        current.add(log)
        logsFlow.value = current
    }

    override suspend fun toggleBooleanCheckIn(habitId: String, date: LocalDate) {
        val dateStr = date.format(dateFormatter)
        val current = logsFlow.value.toMutableList()
        val existing = current.filter { it.habitId == habitId && it.date == dateStr }
        if (existing.any { it.completed }) {
            current.removeAll { it.habitId == habitId && it.date == dateStr }
        } else {
            val now = Instant.now()
            current.add(
                HabitLogEntity(
                    id = UUID.randomUUID().toString(),
                    habitId = habitId,
                    date = dateStr,
                    timestamp = now,
                    completed = true,
                    createdAt = now,
                    updatedAt = now
                )
            )
        }
        logsFlow.value = current
    }

    override suspend fun updateNumericValue(habitId: String, date: LocalDate, value: Double) {
        val dateStr = date.format(dateFormatter)
        val habit = getHabitByIdOnce(habitId)
        val target = habit?.targetValue ?: 1.0
        val isComplete = value >= target
        val current = logsFlow.value.toMutableList()
        val existingIndex = current.indexOfFirst { it.habitId == habitId && it.date == dateStr }
        val now = Instant.now()
        val log = HabitLogEntity(
            id = if (existingIndex >= 0) current[existingIndex].id else UUID.randomUUID().toString(),
            habitId = habitId,
            date = dateStr,
            timestamp = now,
            completed = isComplete,
            value = value,
            createdAt = if (existingIndex >= 0) current[existingIndex].createdAt else now,
            updatedAt = now
        )
        if (existingIndex >= 0) {
            current[existingIndex] = log
        } else {
            current.add(log)
        }
        logsFlow.value = current
    }

    override suspend fun addNumericDelta(habitId: String, date: LocalDate, delta: Double) {
        val dateStr = date.format(dateFormatter)
        val habit = getHabitByIdOnce(habitId)
        val target = habit?.targetValue ?: 1.0
        val existing = logsFlow.value.filter { it.habitId == habitId && it.date == dateStr }
        val currentValue = existing.sumOf { it.value ?: if (it.completed) target else 0.0 }
        val newValue = maxOf(0.0, currentValue + delta)
        updateNumericValue(habitId, date, newValue)
    }

    override suspend fun toggleSlotCheckIn(habitId: String, date: LocalDate, slotIndex: Int) {
        val dateStr = date.format(dateFormatter)
        val current = logsFlow.value.toMutableList()
        val slotLogIndex = current.indexOfFirst { it.habitId == habitId && it.date == dateStr && it.intervalIndex == slotIndex }
        if (slotLogIndex >= 0 && current[slotLogIndex].completed) {
            current.removeAt(slotLogIndex)
        } else {
            val now = Instant.now()
            current.add(
                HabitLogEntity(
                    id = UUID.randomUUID().toString(),
                    habitId = habitId,
                    date = dateStr,
                    timestamp = now,
                    intervalIndex = slotIndex,
                    completed = true,
                    createdAt = now,
                    updatedAt = now
                )
            )
        }
        logsFlow.value = current
    }

    override suspend fun deleteLogsForHabitAndDate(habitId: String, date: LocalDate) {
        val dateStr = date.format(dateFormatter)
        logsFlow.value = logsFlow.value.filterNot { it.habitId == habitId && it.date == dateStr }
    }

    override fun getAllCategories(): Flow<List<HabitCategoryEntity>> = categoriesFlow

    override suspend fun getAllCategoriesOnce(): List<HabitCategoryEntity> = categoriesFlow.value

    override fun getCategoryById(id: String): Flow<HabitCategoryEntity?> =
        categoriesFlow.map { list -> list.find { it.id == id } }

    override suspend fun upsertCategory(category: HabitCategoryEntity) {
        val current = categoriesFlow.value.toMutableList()
        val index = current.indexOfFirst { it.id == category.id }
        if (index >= 0) current[index] = category else current.add(category)
        categoriesFlow.value = current
    }

    override suspend fun deleteCategory(category: HabitCategoryEntity) {
        categoriesFlow.value = categoriesFlow.value.filter { it.id != category.id }
    }
}
