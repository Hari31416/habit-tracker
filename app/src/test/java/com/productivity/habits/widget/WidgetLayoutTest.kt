package com.productivity.habits.widget

import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import com.google.common.truth.Truth.assertThat
import com.productivity.habits.service.TimerStatus
import org.junit.Test

class WidgetLayoutTest {

    @Test
    fun resolveWidgetLayoutSize_returnsSmall_forCompactDimensions() {
        val size2x1 = DpSize(150.dp, 80.dp)
        val result = resolveWidgetLayoutSize(size2x1)
        assertThat(result).isEqualTo(WidgetLayoutSize.SMALL)

        val thinHeight = DpSize(300.dp, 90.dp)
        assertThat(resolveWidgetLayoutSize(thinHeight)).isEqualTo(WidgetLayoutSize.SMALL)
    }

    @Test
    fun resolveWidgetLayoutSize_returnsMedium_forSquareDimensions() {
        val size2x2 = DpSize(200.dp, 180.dp)
        val result = resolveWidgetLayoutSize(size2x2)
        assertThat(result).isEqualTo(WidgetLayoutSize.MEDIUM)
    }

    @Test
    fun resolveWidgetLayoutSize_returnsLarge_forExpandedDimensions() {
        val size4x2 = DpSize(320.dp, 180.dp)
        val result = resolveWidgetLayoutSize(size4x2)
        assertThat(result).isEqualTo(WidgetLayoutSize.LARGE)
    }

    @Test
    fun formatTimeMmSs_formatsMinutesAndSecondsCorrectly() {
        assertThat(formatTimeMmSs(0L)).isEqualTo("00:00")
        assertThat(formatTimeMmSs(65L)).isEqualTo("01:05")
        assertThat(formatTimeMmSs(1500L)).isEqualTo("25:00")
        assertThat(formatTimeMmSs(2700L)).isEqualTo("45:00")
    }

    @Test
    fun streakHabitItem_isAtRiskToday_evaluatedCorrectly() {
        val atRiskItem = StreakHabitItem(
            id = "habit-1",
            title = "Deep Work",
            categoryName = "Productivity",
            currentStreak = 7,
            bestStreak = 14,
            isScheduledToday = true,
            isCompletedToday = false
        )
        assertThat(atRiskItem.isAtRiskToday).isTrue()

        val securedItem = atRiskItem.copy(isCompletedToday = true)
        assertThat(securedItem.isAtRiskToday).isFalse()

        val unscheduledItem = atRiskItem.copy(isScheduledToday = false)
        assertThat(unscheduledItem.isAtRiskToday).isFalse()

        val zeroStreakItem = atRiskItem.copy(currentStreak = 0)
        assertThat(zeroStreakItem.isAtRiskToday).isFalse()
    }

    @Test
    fun focusTimerWidgetData_progressCalculation() {
        val timerData = FocusTimerWidgetData(
            habitId = "habit-1",
            habitTitle = "Deep Work",
            totalSeconds = 1800L,
            remainingSeconds = 900L,
            status = TimerStatus.RUNNING,
            targetMinutes = 30.0
        )
        assertThat(timerData.isRunning).isTrue()
        assertThat(timerData.isPaused).isFalse()
        assertThat(timerData.progress).isWithin(0.001f).of(0.5f)
    }
}
