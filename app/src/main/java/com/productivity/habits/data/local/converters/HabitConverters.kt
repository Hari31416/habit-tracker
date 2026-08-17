package com.productivity.habits.data.local.converters

import androidx.room.TypeConverter
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.data.local.entity.TimeWindow
import java.time.Instant

class HabitConverters {

    @TypeConverter
    fun fromInstant(instant: Instant?): Long? = instant?.toEpochMilli()

    @TypeConverter
    fun toInstant(millis: Long?): Instant? = millis?.let { Instant.ofEpochMilli(it) }

    @TypeConverter
    fun fromIntList(list: List<Int>?): String? = list?.joinToString(",")

    @TypeConverter
    fun toIntList(data: String?): List<Int>? {
        if (data.isNullOrEmpty()) return null
        return data.split(",").mapNotNull { it.trim().toIntOrNull() }
    }

    @TypeConverter
    fun fromStringList(list: List<String>?): String? = list?.joinToString("||")

    @TypeConverter
    fun toStringList(data: String?): List<String> {
        if (data.isNullOrEmpty()) return emptyList()
        return data.split("||").filter { it.isNotEmpty() }
    }

    @TypeConverter
    fun fromTimeWindow(timeWindow: TimeWindow?): String? {
        if (timeWindow == null) return null
        return "${timeWindow.startTime},${timeWindow.endTime}"
    }

    @TypeConverter
    fun toTimeWindow(data: String?): TimeWindow? {
        if (data.isNullOrEmpty()) return null
        val parts = data.split(",")
        return if (parts.size >= 2) {
            TimeWindow(startTime = parts[0].trim(), endTime = parts[1].trim())
        } else null
    }

    @TypeConverter
    fun fromFrequencyType(type: HabitFrequencyType?): String? = type?.name

    @TypeConverter
    fun toFrequencyType(data: String?): HabitFrequencyType? {
        if (data.isNullOrEmpty()) return null
        return try {
            HabitFrequencyType.valueOf(data)
        } catch (e: IllegalArgumentException) {
            HabitFrequencyType.DAILY
        }
    }

    @TypeConverter
    fun fromTargetType(type: HabitTargetType?): String? = type?.name

    @TypeConverter
    fun toTargetType(data: String?): HabitTargetType? {
        if (data.isNullOrEmpty()) return null
        return try {
            HabitTargetType.valueOf(data)
        } catch (e: IllegalArgumentException) {
            HabitTargetType.BOOLEAN
        }
    }
}
