package com.productivity.habits.domain.repository

import com.productivity.habits.domain.gamification.AchievementStatus
import com.productivity.habits.domain.gamification.LevelUpCelebration
import com.productivity.habits.domain.gamification.PlayerProgression
import kotlinx.coroutines.flow.Flow

interface GamificationRepository {
    fun getPlayerProgression(): Flow<PlayerProgression>
    fun getAchievements(): Flow<List<AchievementStatus>>
    fun getPendingCelebration(): Flow<LevelUpCelebration?>
    suspend fun dismissCelebration(level: Int)
}
