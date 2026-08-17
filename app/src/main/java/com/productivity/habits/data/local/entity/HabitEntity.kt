package com.productivity.habits.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.productivity.habits.data.local.converters.HabitConverters
import java.time.Instant

enum class HabitFrequencyType {
    DAILY,
    WEEKLY,
    CUSTOM_DAYS,
    SUBDAY_INTERVAL,
    TIMES_PER_DAY
}

enum class HabitTargetType {
    BOOLEAN,
    NUMERIC,
    TIMER
}

data class TimeWindow(
    val startTime: String, // HH:mm format (e.g., "08:00")
    val endTime: String    // HH:mm format (e.g., "20:00")
)

@Entity(tableName = "habits")
@TypeConverters(HabitConverters::class)
data class HabitEntity(
    @PrimaryKey val id: String,
    val title: String,
    val description: String? = null,
    val color: String, // Hex color code (e.g., "#0A7A64")
    val icon: String? = null, // Lucide icon identifier name
    val categoryId: String? = null,
    val frequencyType: HabitFrequencyType,
    val targetDaysOfWeek: List<Int>? = null, // 0 = Sunday, 1 = Monday, ... 6 = Saturday
    val targetCountPerWeek: Int? = null,
    val intervalHours: Int? = null,
    val timesPerDay: Int? = null,
    val timeWindow: TimeWindow? = null,
    val targetType: HabitTargetType,
    val targetValue: Double? = null, // Numeric goal (e.g., 8 glasses) or Timer target in minutes (e.g., 25 mins)
    val unit: String? = null, // e.g., "glasses", "steps", "pages", "ml", "mins"
    val pinned: Boolean = false,
    val reminderTimes: List<String> = emptyList(), // List of "HH:mm" strings
    val motivationNotes: String? = null,
    val archived: Boolean = false,
    val createdAt: Instant,
    val updatedAt: Instant
)
