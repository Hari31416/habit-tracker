package com.productivity.habits.data.repository

import com.productivity.habits.data.local.dao.HabitCategoryDao
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.dao.HabitLogDao
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.domain.repository.HabitRepository
import com.productivity.habits.domain.scheduler.HabitReminderScheduler
import kotlinx.coroutines.flow.Flow
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class HabitRepositoryImpl @Inject constructor(
    private val habitDao: HabitDao,
    private val habitLogDao: HabitLogDao,
    private val habitCategoryDao: HabitCategoryDao,
    private val reminderScheduler: HabitReminderScheduler
) : HabitRepository {

    private val dateFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    override fun getAllHabits(): Flow<List<HabitEntity>> = habitDao.getAllHabits()

    override fun getActiveHabits(): Flow<List<HabitEntity>> = habitDao.getActiveHabits()

    override fun getArchivedHabits(): Flow<List<HabitEntity>> = habitDao.getArchivedHabits()

    override fun getPinnedHabits(): Flow<List<HabitEntity>> = habitDao.getPinnedHabits()

    override fun getHabitById(id: String): Flow<HabitEntity?> = habitDao.getHabitById(id)

    override suspend fun getHabitByIdOnce(id: String): HabitEntity? = habitDao.getHabitByIdOnce(id)

    override fun getHabitsByCategory(categoryId: String): Flow<List<HabitEntity>> =
        habitDao.getHabitsByCategory(categoryId)

    override suspend fun upsertHabit(habit: HabitEntity) {
        habitDao.upsertHabit(habit)
        reminderScheduler.schedule(habit)
    }

    override suspend fun deleteHabit(habit: HabitEntity) {
        habitDao.deleteHabit(habit)
        reminderScheduler.cancel(habit.id)
    }

    override suspend fun setPinned(id: String, pinned: Boolean) {
        habitDao.updatePinned(id, pinned, Instant.now())
    }

    override suspend fun setArchived(id: String, archived: Boolean) {
        habitDao.updateArchived(id, archived, Instant.now())
        if (archived) {
            reminderScheduler.cancel(id)
        } else {
            val habit = habitDao.getHabitByIdOnce(id)
            if (habit != null) {
                reminderScheduler.schedule(habit)
            }
        }
    }

    override fun getLogsForHabit(habitId: String): Flow<List<HabitLogEntity>> =
        habitLogDao.getLogsForHabit(habitId)

    override suspend fun getLogsForHabitOnce(habitId: String): List<HabitLogEntity> =
        habitLogDao.getLogsForHabitOnce(habitId)

    override fun getLogsForDate(date: LocalDate): Flow<List<HabitLogEntity>> =
        habitLogDao.getLogsForDate(date.format(dateFormatter))

    override suspend fun getLogsForDateOnce(date: LocalDate): List<HabitLogEntity> =
        habitLogDao.getLogsForDateOnce(date.format(dateFormatter))

    override fun getLogsForHabitAndDate(habitId: String, date: LocalDate): Flow<List<HabitLogEntity>> =
        habitLogDao.getLogsForHabitAndDate(habitId, date.format(dateFormatter))

    override fun getLogsForDateRange(startDate: LocalDate, endDate: LocalDate): Flow<List<HabitLogEntity>> =
        habitLogDao.getLogsForDateRange(startDate.format(dateFormatter), endDate.format(dateFormatter))

    override suspend fun getLogsForDateRangeOnce(
        startDate: LocalDate,
        endDate: LocalDate
    ): List<HabitLogEntity> =
        habitLogDao.getLogsForDateRangeOnce(startDate.format(dateFormatter), endDate.format(dateFormatter))

    override fun getAllLogs(): Flow<List<HabitLogEntity>> = habitLogDao.getAllLogs()

    override suspend fun getAllLogsOnce(): List<HabitLogEntity> = habitLogDao.getAllLogsOnce()

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
        habitLogDao.upsertLog(log)
    }

    override suspend fun toggleBooleanCheckIn(habitId: String, date: LocalDate) {
        val dateStr = date.format(dateFormatter)
        val habit = habitDao.getHabitByIdOnce(habitId)
        val existingLogs = habitLogDao.getLogsForHabitAndDateOnce(habitId, dateStr)
        val wasCompleted = if (habit != null) {
            StreakCalculator.isHabitCompletedOnDate(habit, existingLogs)
        } else {
            existingLogs.any { it.completed }
        }

        if (wasCompleted) {
            habitLogDao.deleteLogsForHabitAndDate(habitId, dateStr)
        } else {
            habitLogDao.deleteLogsForHabitAndDate(habitId, dateStr)
            val now = Instant.now()
            if (habit != null) {
                when (habit.targetType) {
                    HabitTargetType.BOOLEAN -> {
                        when (habit.frequencyType) {
                            HabitFrequencyType.TIMES_PER_DAY, HabitFrequencyType.SUBDAY_INTERVAL -> {
                                val slots = habit.timesPerDay ?: habit.targetValue?.toInt() ?: 1
                                for (i in 0 until slots) {
                                    val slotLog = HabitLogEntity(
                                        id = UUID.randomUUID().toString(),
                                        habitId = habitId,
                                        date = dateStr,
                                        timestamp = now,
                                        intervalIndex = i,
                                        completed = true,
                                        createdAt = now,
                                        updatedAt = now
                                    )
                                    habitLogDao.upsertLog(slotLog)
                                }
                            }
                            else -> {
                                val log = HabitLogEntity(
                                    id = UUID.randomUUID().toString(),
                                    habitId = habitId,
                                    date = dateStr,
                                    timestamp = now,
                                    completed = true,
                                    createdAt = now,
                                    updatedAt = now
                                )
                                habitLogDao.upsertLog(log)
                            }
                        }
                    }
                    HabitTargetType.NUMERIC -> {
                        val target = habit.targetValue ?: 1.0
                        val log = HabitLogEntity(
                            id = UUID.randomUUID().toString(),
                            habitId = habitId,
                            date = dateStr,
                            timestamp = now,
                            completed = true,
                            value = target,
                            createdAt = now,
                            updatedAt = now
                        )
                        habitLogDao.upsertLog(log)
                    }
                    HabitTargetType.TIMER -> {
                        val targetMin = habit.targetValue ?: 25.0
                        val totalSec = (targetMin * 60).toLong()
                        val log = HabitLogEntity(
                            id = UUID.randomUUID().toString(),
                            habitId = habitId,
                            date = dateStr,
                            timestamp = now,
                            completed = true,
                            value = targetMin,
                            durationSeconds = totalSec,
                            createdAt = now,
                            updatedAt = now
                        )
                        habitLogDao.upsertLog(log)
                    }
                }
            } else {
                val log = HabitLogEntity(
                    id = UUID.randomUUID().toString(),
                    habitId = habitId,
                    date = dateStr,
                    timestamp = now,
                    completed = true,
                    createdAt = now,
                    updatedAt = now
                )
                habitLogDao.upsertLog(log)
            }
        }
    }

    override suspend fun updateNumericValue(habitId: String, date: LocalDate, value: Double) {
        val dateStr = date.format(dateFormatter)
        val habit = habitDao.getHabitByIdOnce(habitId)
        val target = habit?.targetValue ?: 1.0
        val isComplete = value >= target
        val existingLogs = habitLogDao.getLogsForHabitAndDateOnce(habitId, dateStr)
        val now = Instant.now()
        val durationSec = if (habit?.targetType == HabitTargetType.TIMER) (value * 60).toLong() else null

        if (existingLogs.size > 1) {
            habitLogDao.deleteLogsForHabitAndDate(habitId, dateStr)
        }

        val log = HabitLogEntity(
            id = if (existingLogs.size == 1) existingLogs.first().id else UUID.randomUUID().toString(),
            habitId = habitId,
            date = dateStr,
            timestamp = now,
            completed = isComplete,
            value = value,
            durationSeconds = durationSec,
            createdAt = existingLogs.firstOrNull()?.createdAt ?: now,
            updatedAt = now
        )
        habitLogDao.upsertLog(log)
    }

    override suspend fun addNumericDelta(habitId: String, date: LocalDate, delta: Double) {
        val dateStr = date.format(dateFormatter)
        val habit = habitDao.getHabitByIdOnce(habitId)
        val target = habit?.targetValue ?: 1.0
        val existingLogs = habitLogDao.getLogsForHabitAndDateOnce(habitId, dateStr)
        val currentValue = existingLogs.sumOf {
            if (it.durationSeconds != null && it.durationSeconds > 0) {
                it.durationSeconds / 60.0
            } else {
                it.value ?: if (it.completed) target else 0.0
            }
        }
        val newValue = maxOf(0.0, currentValue + delta)
        updateNumericValue(habitId, date, newValue)
    }

    override suspend fun toggleSlotCheckIn(habitId: String, date: LocalDate, slotIndex: Int) {
        val dateStr = date.format(dateFormatter)
        val existingLogs = habitLogDao.getLogsForHabitAndDateOnce(habitId, dateStr)
        val slotLog = existingLogs.find { it.intervalIndex == slotIndex }

        if (slotLog != null && slotLog.completed) {
            habitLogDao.deleteSlotLog(habitId, dateStr, slotIndex)
        } else {
            val now = Instant.now()
            val log = HabitLogEntity(
                id = slotLog?.id ?: UUID.randomUUID().toString(),
                habitId = habitId,
                date = dateStr,
                timestamp = now,
                intervalIndex = slotIndex,
                completed = true,
                createdAt = slotLog?.createdAt ?: now,
                updatedAt = now
            )
            habitLogDao.upsertLog(log)
        }
    }

    override suspend fun deleteLogsForHabitAndDate(habitId: String, date: LocalDate) {
        habitLogDao.deleteLogsForHabitAndDate(habitId, date.format(dateFormatter))
    }

    override fun getAllCategories(): Flow<List<HabitCategoryEntity>> =
        habitCategoryDao.getAllCategories()

    override suspend fun getAllCategoriesOnce(): List<HabitCategoryEntity> =
        habitCategoryDao.getAllCategoriesOnce()

    override fun getCategoryById(id: String): Flow<HabitCategoryEntity?> =
        habitCategoryDao.getCategoryById(id)

    override suspend fun upsertCategory(category: HabitCategoryEntity) =
        habitCategoryDao.upsertCategory(category)

    override suspend fun deleteCategory(category: HabitCategoryEntity) =
        habitCategoryDao.deleteCategory(category)
}
