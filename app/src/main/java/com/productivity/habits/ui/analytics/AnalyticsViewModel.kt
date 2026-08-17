package com.productivity.habits.ui.analytics

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
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.util.Locale
import javax.inject.Inject
import kotlin.math.roundToInt

data class LeaderboardItem(
    val habit: HabitEntity,
    val category: HabitCategoryEntity?,
    val currentStreak: Int,
    val bestStreak: Int,
    val unitLabel: String
)

data class AnalyticsUiState(
    val consistency30Days: Int = 0,
    val bestStreakRecord: Int = 0,
    val bestStreakHabitTitle: String = "None",
    val bestStreakUnit: String = "days",
    val completedTodayCount: Int = 0,
    val scheduledTodayCount: Int = 0,
    val leaderboard: List<LeaderboardItem> = emptyList(),
    val trendRange: TrendRange = TrendRange.SEVEN_DAYS,
    val trendDataPoints: List<AdherenceDataPoint> = emptyList(),
    val heatmapMonth: YearMonth = YearMonth.now(),
    val heatmapData: Map<LocalDate, HeatmapDayData> = emptyMap(),
    val isLoading: Boolean = false
)

@HiltViewModel
class AnalyticsViewModel @Inject constructor(
    private val repository: HabitRepository
) : ViewModel() {

    private val _trendRange = MutableStateFlow(TrendRange.SEVEN_DAYS)
    val trendRange: StateFlow<TrendRange> = _trendRange.asStateFlow()

    private val _heatmapMonth = MutableStateFlow(YearMonth.now())
    val heatmapMonth: StateFlow<YearMonth> = _heatmapMonth.asStateFlow()

    private val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    val uiState: StateFlow<AnalyticsUiState> = combine(
        repository.getActiveHabits(),
        repository.getAllLogs(),
        repository.getAllCategories(),
        _trendRange,
        _heatmapMonth
    ) { habits, logs, categories, range, hMonth ->
        val categoryMap = categories.associateBy { it.id }
        val logsByHabit = logs.groupBy { it.habitId }
        val today = LocalDate.now()
        val todayStr = today.format(formatter)

        // 1. Top KPIs: 30-Day consistency & Completed Today
        var totalScheduled30d = 0
        var totalCompleted30d = 0

        var scheduledToday = 0
        var completedToday = 0

        for (i in 0 until 30) {
            val checkDate = today.minusDays(i.toLong())
            val dateStr = checkDate.format(formatter)

            habits.forEach { habit ->
                if (StreakCalculator.isHabitScheduledOnDate(habit, checkDate)) {
                    totalScheduled30d++
                    val dayLogs = (logsByHabit[habit.id] ?: emptyList()).filter { it.date == dateStr }
                    if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
                        totalCompleted30d++
                    }
                }
            }
        }

        habits.forEach { habit ->
            if (StreakCalculator.isHabitScheduledOnDate(habit, today)) {
                scheduledToday++
                val dayLogs = (logsByHabit[habit.id] ?: emptyList()).filter { it.date == todayStr }
                if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
                    completedToday++
                }
            }
        }

        val consistency30 = if (totalScheduled30d > 0) {
            ((totalCompleted30d.toDouble() / totalScheduled30d.toDouble()) * 100).roundToInt()
        } else 0

        // 2. Streaks Leaderboard & Best Overall Record
        val habitStreaks = habits.map { habit ->
            val habitLogs = logsByHabit[habit.id] ?: emptyList()
            val streak = StreakCalculator.calculateStreak(habit, habitLogs, today)
            val unit = if (habit.frequencyType == HabitFrequencyType.WEEKLY) "weeks" else "days"
            LeaderboardItem(
                habit = habit,
                category = habit.categoryId?.let { categoryMap[it] },
                currentStreak = streak.currentStreak,
                bestStreak = streak.bestStreak,
                unitLabel = unit
            )
        }

        val leaderboard = habitStreaks
            .sortedByDescending { it.currentStreak }
            .take(5)

        val bestOverall = habitStreaks.maxByOrNull { it.bestStreak }

        // 3. Trend Data Points (7 or 30 days)
        val trendPoints = (0 until range.days).reversed().map { offset ->
            val date = today.minusDays(offset.toLong())
            val dateStr = date.format(formatter)

            var dayScheduled = 0
            var dayCompleted = 0

            habits.forEach { habit ->
                if (StreakCalculator.isHabitScheduledOnDate(habit, date)) {
                    dayScheduled++
                    val dayLogs = (logsByHabit[habit.id] ?: emptyList()).filter { it.date == dateStr }
                    if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
                        dayCompleted++
                    }
                }
            }

            val adherence = if (dayScheduled > 0) {
                ((dayCompleted.toDouble() / dayScheduled.toDouble()) * 100).roundToInt()
            } else 0

            val label = if (range == TrendRange.SEVEN_DAYS) {
                date.format(DateTimeFormatter.ofPattern("EEE", Locale.getDefault()))
            } else {
                date.format(DateTimeFormatter.ofPattern("d MMM", Locale.getDefault()))
            }

            AdherenceDataPoint(date = date, label = label, adherencePercent = adherence)
        }

        // 4. Heatmap Month Data
        val daysInMonth = hMonth.lengthOfMonth()
        val heatmapData = mutableMapOf<LocalDate, HeatmapDayData>()

        for (d in 1..daysInMonth) {
            val date = hMonth.atDay(d)
            val dateStr = date.format(formatter)

            var dayScheduled = 0
            var dayCompleted = 0

            habits.forEach { habit ->
                if (StreakCalculator.isHabitScheduledOnDate(habit, date)) {
                    dayScheduled++
                    val dayLogs = (logsByHabit[habit.id] ?: emptyList()).filter { it.date == dateStr }
                    if (StreakCalculator.isHabitCompletedOnDate(habit, dayLogs)) {
                        dayCompleted++
                    }
                }
            }

            val rate = if (dayScheduled > 0) {
                ((dayCompleted.toDouble() / dayScheduled.toDouble()) * 100).roundToInt()
            } else 0

            heatmapData[date] = HeatmapDayData(
                date = date,
                completedCount = dayCompleted,
                scheduledCount = dayScheduled,
                ratePercent = rate
            )
        }

        AnalyticsUiState(
            consistency30Days = consistency30,
            bestStreakRecord = bestOverall?.bestStreak ?: 0,
            bestStreakHabitTitle = bestOverall?.habit?.title ?: "None",
            bestStreakUnit = bestOverall?.unitLabel ?: "days",
            completedTodayCount = completedToday,
            scheduledTodayCount = scheduledToday,
            leaderboard = leaderboard,
            trendRange = range,
            trendDataPoints = trendPoints,
            heatmapMonth = hMonth,
            heatmapData = heatmapData,
            isLoading = false
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        AnalyticsUiState(isLoading = true)
    )

    fun setTrendRange(range: TrendRange) {
        _trendRange.value = range
    }

    fun previousHeatmapMonth() {
        _heatmapMonth.value = _heatmapMonth.value.minusMonths(1)
    }

    fun nextHeatmapMonth() {
        _heatmapMonth.value = _heatmapMonth.value.plusMonths(1)
    }
}
