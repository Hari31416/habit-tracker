package com.productivity.habits.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Upsert
import com.productivity.habits.data.local.entity.HabitLogEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface HabitLogDao {

    @Query("SELECT * FROM habit_logs WHERE habitId = :habitId ORDER BY date DESC, timestamp DESC")
    fun getLogsForHabit(habitId: String): Flow<List<HabitLogEntity>>

    @Query("SELECT * FROM habit_logs WHERE habitId = :habitId ORDER BY date DESC, timestamp DESC")
    suspend fun getLogsForHabitOnce(habitId: String): List<HabitLogEntity>

    @Query("SELECT * FROM habit_logs WHERE date = :date")
    fun getLogsForDate(date: String): Flow<List<HabitLogEntity>>

    @Query("SELECT * FROM habit_logs WHERE date = :date")
    suspend fun getLogsForDateOnce(date: String): List<HabitLogEntity>

    @Query("SELECT * FROM habit_logs WHERE habitId = :habitId AND date = :date")
    fun getLogsForHabitAndDate(habitId: String, date: String): Flow<List<HabitLogEntity>>

    @Query("SELECT * FROM habit_logs WHERE habitId = :habitId AND date = :date")
    suspend fun getLogsForHabitAndDateOnce(habitId: String, date: String): List<HabitLogEntity>

    @Query("SELECT * FROM habit_logs WHERE date >= :startDate AND date <= :endDate ORDER BY date ASC")
    fun getLogsForDateRange(startDate: String, endDate: String): Flow<List<HabitLogEntity>>

    @Query("SELECT * FROM habit_logs WHERE date >= :startDate AND date <= :endDate ORDER BY date ASC")
    suspend fun getLogsForDateRangeOnce(startDate: String, endDate: String): List<HabitLogEntity>

    @Query("SELECT * FROM habit_logs WHERE habitId = :habitId AND date >= :startDate AND date <= :endDate ORDER BY date ASC")
    fun getLogsForHabitAndDateRange(habitId: String, startDate: String, endDate: String): Flow<List<HabitLogEntity>>

    @Query("SELECT * FROM habit_logs ORDER BY date DESC, timestamp DESC")
    fun getAllLogs(): Flow<List<HabitLogEntity>>

    @Query("SELECT * FROM habit_logs ORDER BY date DESC, timestamp DESC")
    suspend fun getAllLogsOnce(): List<HabitLogEntity>

    @Upsert
    suspend fun upsertLog(log: HabitLogEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLogs(logs: List<HabitLogEntity>)

    @Update
    suspend fun updateLog(log: HabitLogEntity)

    @Delete
    suspend fun deleteLog(log: HabitLogEntity)

    @Query("DELETE FROM habit_logs WHERE id = :id")
    suspend fun deleteLogById(id: String)

    @Query("DELETE FROM habit_logs WHERE habitId = :habitId AND date = :date")
    suspend fun deleteLogsForHabitAndDate(habitId: String, date: String)

    @Query("DELETE FROM habit_logs WHERE habitId = :habitId AND date = :date AND intervalIndex = :intervalIndex")
    suspend fun deleteSlotLog(habitId: String, date: String, intervalIndex: Int)
}
