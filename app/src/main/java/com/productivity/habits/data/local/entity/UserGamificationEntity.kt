package com.productivity.habits.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.Instant

@Entity(tableName = "user_gamification")
data class UserGamificationEntity(
    @PrimaryKey val id: String = "user_gamification",
    val totalXp: Long = 0L,
    val currentLevel: Int = 1,
    val lastCelebratedLevel: Int = 1,
    val updatedAt: Instant = Instant.now()
)
