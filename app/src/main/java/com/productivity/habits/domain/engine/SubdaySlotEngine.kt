package com.productivity.habits.domain.engine

import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitLogEntity
import java.time.LocalTime
import java.time.format.DateTimeFormatter

data class SubdaySlot(
    val index: Int,
    val timeLabel: String,
    val time: LocalTime? = null,
    val completed: Boolean = false
)

object SubdaySlotEngine {

    private val TIME_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("HH:mm")

    fun generateSlots(habit: HabitEntity, logsForDate: List<HabitLogEntity> = emptyList()): List<SubdaySlot> {
        val completedIndices = logsForDate
            .filter { it.completed }
            .mapNotNull { it.intervalIndex }
            .toSet()

        val timeWindow = habit.timeWindow
        val intervalHours = habit.intervalHours
        val timesPerDay = habit.timesPerDay

        // Case 1: Time Window + Interval Hours (e.g. 08:00 to 20:00 every 2 hours)
        if (timeWindow != null && intervalHours != null && intervalHours > 0) {
            val startTime = parseTime(timeWindow.startTime) ?: LocalTime.of(8, 0)
            val endTime = parseTime(timeWindow.endTime) ?: LocalTime.of(20, 0)

            val slots = mutableListOf<SubdaySlot>()
            var current = startTime
            var index = 0

            while (!current.isAfter(endTime)) {
                slots.add(
                    SubdaySlot(
                        index = index,
                        timeLabel = current.format(TIME_FORMATTER),
                        time = current,
                        completed = completedIndices.contains(index)
                    )
                )
                index++
                val next = current.plusHours(intervalHours.toLong())
                if (next.isBefore(current) || next == current) break // Safety against overflow
                current = next
            }
            return slots
        }

        // Case 2: Time Window + Times Per Day (evenly spaced)
        if (timeWindow != null && timesPerDay != null && timesPerDay > 0) {
            val startTime = parseTime(timeWindow.startTime) ?: LocalTime.of(8, 0)
            val endTime = parseTime(timeWindow.endTime) ?: LocalTime.of(20, 0)

            if (timesPerDay == 1) {
                return listOf(
                    SubdaySlot(
                        index = 0,
                        timeLabel = startTime.format(TIME_FORMATTER),
                        time = startTime,
                        completed = completedIndices.contains(0)
                    )
                )
            }

            val startMinutes = startTime.toSecondOfDay() / 60
            val endMinutes = endTime.toSecondOfDay() / 60
            val totalMinutes = maxOf(0, endMinutes - startMinutes)
            val stepMinutes = totalMinutes / (timesPerDay - 1)

            return (0 until timesPerDay).map { index ->
                val slotMinutes = startMinutes + (index * stepMinutes)
                val slotTime = LocalTime.ofSecondOfDay((slotMinutes * 60).toLong().coerceIn(0, 86399))
                SubdaySlot(
                    index = index,
                    timeLabel = slotTime.format(TIME_FORMATTER),
                    time = slotTime,
                    completed = completedIndices.contains(index)
                )
            }
        }

        // Case 3: Fixed Times Per Day without explicit time window
        val count = timesPerDay ?: habit.targetValue?.toInt() ?: 3
        return (0 until count).map { index ->
            SubdaySlot(
                index = index,
                timeLabel = "#${index + 1}",
                time = null,
                completed = completedIndices.contains(index)
            )
        }
    }

    private fun parseTime(timeStr: String): LocalTime? {
        return try {
            LocalTime.parse(timeStr.trim(), TIME_FORMATTER)
        } catch (e: Exception) {
            null
        }
    }
}
