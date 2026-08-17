package com.productivity.habits.ui.matrix

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.domain.repository.HabitRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale
import javax.inject.Inject
import kotlin.math.roundToInt

enum class MatrixCellStatus {
    COMPLETED,
    SCHEDULED_INCOMPLETE,
    NOT_SCHEDULED
}

data class MatrixCell(
    val date: LocalDate,
    val status: MatrixCellStatus,
    val isToday: Boolean
)

data class MatrixRow(
    val habit: HabitEntity,
    val category: HabitCategoryEntity?,
    val cells: List<MatrixCell>,
    val completedCountThisWeek: Int,
    val targetCountThisWeek: Int
)

data class DailyCompletionStat(
    val date: LocalDate,
    val dayLabel: String,
    val completedCount: Int,
    val scheduledCount: Int
)

data class WeekMatrixUiState(
    val weekStart: LocalDate = StreakCalculator.isoWeekStart(LocalDate.now()),
    val weekEnd: LocalDate = StreakCalculator.isoWeekStart(LocalDate.now()).plusDays(6),
    val isCurrentWeek: Boolean = true,
    val rows: List<MatrixRow> = emptyList(),
    val dailyStats: List<DailyCompletionStat> = emptyList(),
    val totalCompleted: Int = 0,
    val totalScheduled: Int = 0,
    val adherencePercentage: Int = 0,
    val isLoading: Boolean = false
)

@HiltViewModel
class WeekMatrixViewModel @Inject constructor(
    private val repository: HabitRepository
) : ViewModel() {

    private val _weekStart = MutableStateFlow(StreakCalculator.isoWeekStart(LocalDate.now()))
    val weekStart: StateFlow<LocalDate> = _weekStart.asStateFlow()

    private val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    val uiState: StateFlow<WeekMatrixUiState> = combine(
        _weekStart,
        repository.getActiveHabits(),
        repository.getAllLogs(),
        repository.getAllCategories()
    ) { start, habits, logs, categories ->
        val weekEnd = start.plusDays(6)
        val today = LocalDate.now()
        val isCurrentWeek = start == StreakCalculator.isoWeekStart(today)
        val categoryMap = categories.associateBy { it.id }
        val logsByHabit = logs.groupBy { it.habitId }

        val weekDays = (0..6).map { start.plusDays(it.toLong()) }

        val rows = habits.map { habit ->
            val habitLogs = logsByHabit[habit.id] ?: emptyList()
            val logsByDate = habitLogs.groupBy { it.date }

            var completedDaysCount = 0
            val cells = weekDays.map { date ->
                val isToday = date == today
                val isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, date)
                val dayLogs = logsByDate[date.format(formatter)] ?: emptyList()
                val isCompleted = StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)

                if (isCompleted) completedDaysCount++

                val status = when {
                    isCompleted -> MatrixCellStatus.COMPLETED
                    isScheduled -> MatrixCellStatus.SCHEDULED_INCOMPLETE
                    else -> MatrixCellStatus.NOT_SCHEDULED
                }

                MatrixCell(date = date, status = status, isToday = isToday)
            }

            val targetCountThisWeek = when (habit.frequencyType) {
                HabitFrequencyType.DAILY -> 7
                HabitFrequencyType.WEEKLY -> habit.targetCountPerWeek ?: 1
                HabitFrequencyType.CUSTOM_DAYS -> habit.targetDaysOfWeek?.size ?: 7
                HabitFrequencyType.SUBDAY_INTERVAL, HabitFrequencyType.TIMES_PER_DAY -> 7
            }

            MatrixRow(
                habit = habit,
                category = habit.categoryId?.let { categoryMap[it] },
                cells = cells,
                completedCountThisWeek = completedDaysCount,
                targetCountThisWeek = targetCountThisWeek
            )
        }.sortedWith(
            compareByDescending<MatrixRow> { it.habit.pinned }
                .thenBy { it.habit.title.lowercase() }
        )

        // Daily completion stats for the bar chart
        val dailyStats = weekDays.map { date ->
            val dayStr = date.format(formatter)
            val dayLabel = date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.getDefault()).take(3)

            var scheduled = 0
            var completed = 0

            habits.forEach { habit ->
                val isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, date)
                if (isScheduled) {
                    scheduled++
                    val dayLogs = (logsByHabit[habit.id] ?: emptyList()).filter { it.date == dayStr }
                    if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
                        completed++
                    }
                }
            }

            DailyCompletionStat(
                date = date,
                dayLabel = dayLabel,
                completedCount = completed,
                scheduledCount = scheduled
            )
        }

        val totalScheduled = rows.sumOf { it.targetCountThisWeek }
        val totalCompleted = rows.sumOf { minOf(it.completedCountThisWeek, it.targetCountThisWeek) }
        val adherence = if (totalScheduled > 0) {
            ((totalCompleted.toDouble() / totalScheduled.toDouble()) * 100).roundToInt()
        } else 0

        WeekMatrixUiState(
            weekStart = start,
            weekEnd = weekEnd,
            isCurrentWeek = isCurrentWeek,
            rows = rows,
            dailyStats = dailyStats,
            totalCompleted = totalCompleted,
            totalScheduled = totalScheduled,
            adherencePercentage = adherence,
            isLoading = false
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        WeekMatrixUiState(isLoading = true)
    )

    fun previousWeek() {
        _weekStart.value = _weekStart.value.minusWeeks(1)
    }

    fun nextWeek() {
        _weekStart.value = _weekStart.value.plusWeeks(1)
    }

    fun currentWeek() {
        _weekStart.value = StreakCalculator.isoWeekStart(LocalDate.now())
    }

    fun toggleCell(habitId: String, date: LocalDate) {
        viewModelScope.launch {
            repository.toggleBooleanCheckIn(habitId, date)
        }
    }
}
