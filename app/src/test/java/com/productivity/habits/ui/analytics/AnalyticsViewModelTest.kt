package com.productivity.habits.ui.analytics

import com.google.common.truth.Truth.assertThat
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.testutil.FakeHabitRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth

@OptIn(ExperimentalCoroutinesApi::class)
class AnalyticsViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeRepository: FakeHabitRepository
    private lateinit var viewModel: AnalyticsViewModel

    private val now = Instant.now()
    private val today = LocalDate.now()

    private val habit1 = HabitEntity(
        id = "analytics_habit_1",
        title = "Morning Meditation",
        color = "#8B5CF6",
        frequencyType = HabitFrequencyType.DAILY,
        targetType = HabitTargetType.BOOLEAN,
        createdAt = now,
        updatedAt = now
    )

    private val habit2 = HabitEntity(
        id = "analytics_habit_2",
        title = "Drink Water",
        color = "#06B6D4",
        frequencyType = HabitFrequencyType.DAILY,
        targetType = HabitTargetType.NUMERIC,
        targetValue = 2000.0,
        unit = "ml",
        createdAt = now,
        updatedAt = now
    )

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        fakeRepository = FakeHabitRepository()
        fakeRepository.setHabits(listOf(habit1, habit2))
        viewModel = AnalyticsViewModel(fakeRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state loads top KPIs and trend data points`() = runTest {
        advanceUntilIdle()
        val state = viewModel.uiState.first { !it.isLoading }

        assertThat(state.scheduledTodayCount).isEqualTo(2)
        assertThat(state.completedTodayCount).isEqualTo(0)
        assertThat(state.trendRange).isEqualTo(TrendRange.SEVEN_DAYS)
        assertThat(state.trendDataPoints).hasSize(7)
        assertThat(state.heatmapMonth).isEqualTo(YearMonth.now())
        assertThat(state.heatmapData).isNotEmpty()
    }

    @Test
    fun `switching trend range updates data points count`() = runTest {
        advanceUntilIdle()
        viewModel.setTrendRange(TrendRange.THIRTY_DAYS)
        advanceUntilIdle()

        val state = viewModel.uiState.first { it.trendRange == TrendRange.THIRTY_DAYS }
        assertThat(state.trendDataPoints).hasSize(30)
    }

    @Test
    fun `heatmap month navigation updates month state`() = runTest {
        val current = YearMonth.now()
        viewModel.previousHeatmapMonth()
        assertThat(viewModel.heatmapMonth.value).isEqualTo(current.minusMonths(1))

        viewModel.nextHeatmapMonth()
        assertThat(viewModel.heatmapMonth.value).isEqualTo(current)
    }

    @Test
    fun `completed habits on today updates completedTodayCount and consistency`() = runTest {
        fakeRepository.logCheckIn("analytics_habit_1", today, completed = true)
        advanceUntilIdle()

        val state = viewModel.uiState.first { it.completedTodayCount == 1 }
        assertThat(state.completedTodayCount).isEqualTo(1)
        assertThat(state.scheduledTodayCount).isEqualTo(2)
    }
}
