package com.productivity.habits.service

import com.google.common.truth.Truth.assertThat
import org.junit.Before
import org.junit.Test

class TimerStateHolderTest {

    @Before
    fun setup() {
        TimerStateHolder.stop()
    }

    @Test
    fun `start initializes timer state with running status`() {
        TimerStateHolder.start("habit_1", "Focus Work", 25.0)

        val state = TimerStateHolder.timerState.value
        assertThat(state.habitId).isEqualTo("habit_1")
        assertThat(state.habitTitle).isEqualTo("Focus Work")
        assertThat(state.totalSeconds).isEqualTo(25 * 60L)
        assertThat(state.remainingSeconds).isEqualTo(25 * 60L)
        assertThat(state.status).isEqualTo(TimerStatus.RUNNING)
        assertThat(state.isRunning).isTrue()
    }

    @Test
    fun `pause and resume toggle status appropriately`() {
        TimerStateHolder.start("habit_1", "Focus Work", 25.0)
        TimerStateHolder.pause()

        assertThat(TimerStateHolder.timerState.value.status).isEqualTo(TimerStatus.PAUSED)
        assertThat(TimerStateHolder.timerState.value.isPaused).isTrue()

        TimerStateHolder.resume()
        assertThat(TimerStateHolder.timerState.value.status).isEqualTo(TimerStatus.RUNNING)
    }

    @Test
    fun `adjustRemaining adds and subtracts delta seconds`() {
        TimerStateHolder.start("habit_1", "Focus Work", 25.0)
        TimerStateHolder.adjustRemaining(300L) // +5m

        assertThat(TimerStateHolder.timerState.value.remainingSeconds).isEqualTo(30 * 60L)

        TimerStateHolder.adjustRemaining(-600L) // -10m
        assertThat(TimerStateHolder.timerState.value.remainingSeconds).isEqualTo(20 * 60L)
    }

    @Test
    fun `tick updates remaining seconds and completes when zero`() {
        TimerStateHolder.start("habit_1", "Focus Work", 10.0)
        TimerStateHolder.tick(50L)

        assertThat(TimerStateHolder.timerState.value.remainingSeconds).isEqualTo(50L)
        assertThat(TimerStateHolder.timerState.value.status).isEqualTo(TimerStatus.RUNNING)

        TimerStateHolder.tick(0L)
        assertThat(TimerStateHolder.timerState.value.remainingSeconds).isEqualTo(0L)
        assertThat(TimerStateHolder.timerState.value.status).isEqualTo(TimerStatus.COMPLETED)
        assertThat(TimerStateHolder.timerState.value.isCompleted).isTrue()
    }

    @Test
    fun `reset restores remaining seconds to total seconds and sets status to IDLE`() {
        TimerStateHolder.start("habit_1", "Focus Work", 25.0)
        TimerStateHolder.tick(60L)
        TimerStateHolder.reset()

        val state = TimerStateHolder.timerState.value
        assertThat(state.remainingSeconds).isEqualTo(25 * 60L)
        assertThat(state.status).isEqualTo(TimerStatus.IDLE)
    }
}
