package com.productivity.habits.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.productivity.habits.data.local.entity.AchievementEntity
import com.productivity.habits.data.local.entity.UserGamificationEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface GamificationDao {

    @Query("SELECT * FROM achievements")
    fun getAllAchievements(): Flow<List<AchievementEntity>>

    @Query("SELECT * FROM achievements")
    suspend fun getAllAchievementsOnce(): List<AchievementEntity>

    @Query("SELECT * FROM achievements WHERE id = :id LIMIT 1")
    suspend fun getAchievementById(id: String): AchievementEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAchievement(entity: AchievementEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAchievements(entities: List<AchievementEntity>)

    @Query("SELECT * FROM user_gamification WHERE id = 'user_gamification' LIMIT 1")
    fun getUserGamification(): Flow<UserGamificationEntity?>

    @Query("SELECT * FROM user_gamification WHERE id = 'user_gamification' LIMIT 1")
    suspend fun getUserGamificationOnce(): UserGamificationEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertUserGamification(entity: UserGamificationEntity)
}
