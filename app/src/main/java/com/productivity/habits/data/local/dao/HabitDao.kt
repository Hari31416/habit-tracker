package com.productivity.habits.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import androidx.room.Upsert
import com.productivity.habits.data.local.entity.HabitEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface HabitDao {

    @Query("SELECT * FROM habits ORDER BY pinned DESC, createdAt ASC")
    fun getAllHabits(): Flow<List<HabitEntity>>

    @Query("SELECT * FROM habits WHERE archived = 0 ORDER BY pinned DESC, createdAt ASC")
    fun getActiveHabits(): Flow<List<HabitEntity>>

    @Query("SELECT * FROM habits WHERE archived = 0 ORDER BY pinned DESC, createdAt ASC")
    suspend fun getActiveHabitsOnce(): List<HabitEntity>

    @Query("SELECT * FROM habits WHERE archived = 1 ORDER BY updatedAt DESC")
    fun getArchivedHabits(): Flow<List<HabitEntity>>

    @Query("SELECT * FROM habits WHERE pinned = 1 AND archived = 0 ORDER BY createdAt ASC")
    fun getPinnedHabits(): Flow<List<HabitEntity>>

    @Query("SELECT * FROM habits WHERE id = :id")
    fun getHabitById(id: String): Flow<HabitEntity?>

    @Query("SELECT * FROM habits WHERE id = :id")
    suspend fun getHabitByIdOnce(id: String): HabitEntity?

    @Query("SELECT * FROM habits WHERE categoryId = :categoryId AND archived = 0 ORDER BY pinned DESC, createdAt ASC")
    fun getHabitsByCategory(categoryId: String): Flow<List<HabitEntity>>

    @Upsert
    suspend fun upsertHabit(habit: HabitEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertHabits(habits: List<HabitEntity>)

    @Update
    suspend fun updateHabit(habit: HabitEntity)

    @Delete
    suspend fun deleteHabit(habit: HabitEntity)

    @Query("DELETE FROM habits WHERE id = :id")
    suspend fun deleteHabitById(id: String)

    @Query("UPDATE habits SET pinned = :pinned, updatedAt = :updatedAt WHERE id = :id")
    suspend fun updatePinned(id: String, pinned: Boolean, updatedAt: java.time.Instant)

    @Query("UPDATE habits SET archived = :archived, updatedAt = :updatedAt WHERE id = :id")
    suspend fun updateArchived(id: String, archived: Boolean, updatedAt: java.time.Instant)
}
