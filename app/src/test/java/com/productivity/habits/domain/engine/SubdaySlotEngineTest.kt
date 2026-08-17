package com.productivity.habits.domain.engine

import com.google.common.truth.Truth.assertThat
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.data.local.entity.TimeWindow
import org.junit.Test
import java.time.Instant
import java.util.UUID

class SubdaySlotEngineTest {

    private fun createHabit(
        timeWindow: TimeWindow? = null,
        intervalHours: Int? = null,
        timesPerDay: Int? = null
    ): HabitEntity {
        val now = Instant.now()
        return HabitEntity(
            id = "slot-habit-1",
            title = "Hydration Slots",
            color = "#3b82f6",
            frequencyType = HabitFrequencyType.SUBDAY_INTERVAL,
            targetType = HabitTargetType.BOOLEAN,
            timeWindow = timeWindow,
            intervalHours = intervalHours,
            timesPerDay = timesPerDay,
            createdAt = now,
            updatedAt = now
        )
    }

    @Test
    fun generateSlots_withTimeWindowAndInterval_generatesExpectedSlots() {
        val habit = createHabit(
            timeWindow = TimeWindow(startTime = "08:00", endTime = "14:00"),
            intervalHours = 2
        )

        val slots = SubdaySlotEngine.generateSlots(habit)

        // 08:00, 10:00, 12:00, 14:00 -> 4 slots
        assertThat(slots).hasSize(4)
        assertThat(slots.map { it.timeLabel }).containsExactly("08:00", "10:00", "12:00", "14:00").inOrder()
        assertThat(slots.map { it.index }).containsExactly(0, 1, 2, 3).inOrder()
    }

    @Test
    fun generateSlots_withLogs_mapsCompletionStatusCorrectly() {
        val habit = createHabit(
            timeWindow = TimeWindow(startTime = "08:00", endTime = "12:00"),
            intervalHours = 2
        )
        val now = Instant.now()
        val logs = listOf(
            HabitLogEntity(
                id = UUID.randomUUID().toString(),
                habitId = habit.id,
                date = "2026-08-17",
                timestamp = now,
                completed = true,
                intervalIndex = 1, // 10:00 completed
                createdAt = now,
                updatedAt = now
            )
        )

        val slots = SubdaySlotEngine.generateSlots(habit, logs)

        // 08:00 (index 0 - false), 10:00 (index 1 - true), 12:00 (index 2 - false)
        assertThat(slots).hasSize(3)
        assertThat(slots[0].completed).isFalse()
        assertThat(slots[1].completed).isTrue()
        assertThat(slots[2].completed).isFalse()
    }

    @Test
    fun generateSlots_withoutTimeWindow_generatesNumberedSlots() {
        val habit = createHabit(timesPerDay = 3)

        val slots = SubdaySlotEngine.generateSlots(habit)

        assertThat(slots).hasSize(3)
        assertThat(slots.map { it.timeLabel }).containsExactly("#1", "#2", "#3").inOrder()
    }
}
