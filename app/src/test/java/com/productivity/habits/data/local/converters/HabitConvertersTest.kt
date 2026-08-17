package com.productivity.habits.data.local.converters

import com.google.common.truth.Truth.assertThat
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.data.local.entity.TimeWindow
import org.junit.Test
import java.time.Instant

class HabitConvertersTest {

    private val converters = HabitConverters()

    @Test
    fun instantConverter_roundTripsCorrectly() {
        val instant = Instant.ofEpochMilli(1723886400000L)
        val millis = converters.fromInstant(instant)
        val result = converters.toInstant(millis)
        assertThat(result).isEqualTo(instant)
    }

    @Test
    fun intListConverter_roundTripsCorrectly() {
        val list = listOf(1, 3, 5)
        val str = converters.fromIntList(list)
        val result = converters.toIntList(str)
        assertThat(result).containsExactly(1, 3, 5).inOrder()
    }

    @Test
    fun stringListConverter_roundTripsCorrectly() {
        val list = listOf("08:00", "12:30", "18:00")
        val str = converters.fromStringList(list)
        val result = converters.toStringList(str)
        assertThat(result).containsExactly("08:00", "12:30", "18:00").inOrder()
    }

    @Test
    fun timeWindowConverter_roundTripsCorrectly() {
        val window = TimeWindow(startTime = "08:00", endTime = "20:00")
        val str = converters.fromTimeWindow(window)
        val result = converters.toTimeWindow(str)
        assertThat(result).isEqualTo(window)
    }

    @Test
    fun frequencyTypeConverter_roundTripsCorrectly() {
        HabitFrequencyType.values().forEach { type ->
            val str = converters.fromFrequencyType(type)
            val result = converters.toFrequencyType(str)
            assertThat(result).isEqualTo(type)
        }
    }

    @Test
    fun targetTypeConverter_roundTripsCorrectly() {
        HabitTargetType.values().forEach { type ->
            val str = converters.fromTargetType(type)
            val result = converters.toTargetType(str)
            assertThat(result).isEqualTo(type)
        }
    }
}
