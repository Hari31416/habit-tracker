package com.productivity.habits.service

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

enum class TimerStatus {
    IDLE,
    RUNNING,
    PAUSED,
    COMPLETED
}

data class TimerState(
    val habitId: String? = null,
    val habitTitle: String = "",
    val totalSeconds: Long = 25 * 60,
    val remainingSeconds: Long = 25 * 60,
    val status: TimerStatus = TimerStatus.IDLE
) {
    val isRunning: Boolean get() = status == TimerStatus.RUNNING
    val isPaused: Boolean get() = status == TimerStatus.PAUSED
    val isCompleted: Boolean get() = status == TimerStatus.COMPLETED
    val progress: Float get() = if (totalSeconds > 0) {
        ((totalSeconds - remainingSeconds).toFloat() / totalSeconds.toFloat()).coerceIn(0f, 1f)
    } else 0f
}

object TimerStateHolder {

    private val _timerState = MutableStateFlow(TimerState())
    val timerState: StateFlow<TimerState> = _timerState.asStateFlow()

    fun start(habitId: String, habitTitle: String, durationMinutes: Double) {
        val totalSec = (durationMinutes * 60).toLong().coerceAtLeast(60L)
        _timerState.value = TimerState(
            habitId = habitId,
            habitTitle = habitTitle,
            totalSeconds = totalSec,
            remainingSeconds = totalSec,
            status = TimerStatus.RUNNING
        )
    }

    fun resume() {
        _timerState.update { current ->
            if (current.isPaused) {
                current.copy(status = TimerStatus.RUNNING)
            } else current
        }
    }

    fun pause() {
        _timerState.update { current ->
            if (current.isRunning) {
                current.copy(status = TimerStatus.PAUSED)
            } else current
        }
    }

    fun reset() {
        _timerState.update { current ->
            current.copy(
                remainingSeconds = current.totalSeconds,
                status = TimerStatus.IDLE
            )
        }
    }

    fun stop() {
        _timerState.value = TimerState()
    }

    fun tick(remainingSec: Long) {
        _timerState.update { current ->
            if (remainingSec <= 0) {
                current.copy(remainingSeconds = 0, status = TimerStatus.COMPLETED)
            } else {
                current.copy(remainingSeconds = remainingSec)
            }
        }
    }

    fun adjustRemaining(deltaSeconds: Long) {
        _timerState.update { current ->
            val newRemaining = (current.remainingSeconds + deltaSeconds).coerceIn(0L, 24 * 3600L)
            val newTotal = maxOf(current.totalSeconds, newRemaining)
            current.copy(
                remainingSeconds = newRemaining,
                totalSeconds = newTotal,
                status = if (newRemaining <= 0) TimerStatus.COMPLETED else current.status
            )
        }
    }

    fun setRemainingMinutes(minutes: Long) {
        val sec = (minutes * 60).coerceAtLeast(60L)
        _timerState.update { current ->
            current.copy(
                remainingSeconds = sec,
                totalSeconds = sec,
                status = if (current.isRunning) TimerStatus.RUNNING else TimerStatus.IDLE
            )
        }
    }

    fun complete() {
        _timerState.update { current ->
            current.copy(remainingSeconds = 0, status = TimerStatus.COMPLETED)
        }
    }
}
