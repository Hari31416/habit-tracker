package com.productivity.habits.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.time.Instant

@Entity(
    tableName = "habit_logs",
    foreignKeys = [
        ForeignKey(
            entity = HabitEntity::class,
            parentColumns = ["id"],
            childColumns = ["habitId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["habitId"]),
        Index(value = ["date"]),
        Index(value = ["habitId", "date"])
    ]
)
data class HabitLogEntity(
    @PrimaryKey val id: String,
    val habitId: String,
    val date: String, // ISO Date format "yyyy-MM-dd"
    val timestamp: Instant,
    val intervalIndex: Int? = null, // For subday interval or times-per-day slot index (0, 1, 2...)
    val completed: Boolean,
    val value: Double? = null, // Recorded numeric value or minutes
    val durationSeconds: Long? = null, // Elapsed duration in seconds for timer habits
    val note: String? = null,
    val createdAt: Instant,
    val updatedAt: Instant
)
