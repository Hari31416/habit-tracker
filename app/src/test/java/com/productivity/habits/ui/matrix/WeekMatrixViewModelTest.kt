package com.productivity.habits.ui.matrix

import com.google.common.truth.Truth.assertThat
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.domain.engine.StreakCalculator
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

@OptIn(ExperimentalCoroutinesApi::class)
class WeekMatrixViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeRepository: FakeHabitRepository
    private lateinit var viewModel: WeekMatrixViewModel

    private val now = Instant.now()
    private val today = LocalDate.now()
    private val isoMonday = StreakCalculator.isoWeekStart(today)

    private val habit1 = HabitEntity(
        id = "matrix_habit_1",
        title = "Morning Workout",
        color = "#10B981",
        frequencyType = HabitFrequencyType.DAILY,
        targetType = HabitTargetType.BOOLEAN,
        createdAt = now,
        updatedAt = now
    )

    private val habit2 = HabitEntity(
        id = "matrix_habit_2",
        title = "Weekly Review",
        color = "#6366F1",
        frequencyType = HabitFrequencyType.WEEKLY,
        targetCountPerWeek = 2,
        targetType = HabitTargetType.BOOLEAN,
        createdAt = now,
        updatedAt = now
    )

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        fakeRepository = FakeHabitRepository()
        fakeRepository.setHabits(listOf(habit1, habit2))
        viewModel = WeekMatrixViewModel(fakeRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state loads ISO Monday to Sunday date range and habit rows`() = runTest {
        advanceUntilIdle()
        val state = viewModel.uiState.first { !it.isLoading && it.rows.isNotEmpty() }

        assertThat(state.weekStart).isEqualTo(isoMonday)
        assertThat(state.weekEnd).isEqualTo(isoMonday.plusDays(6))
        assertThat(state.isCurrentWeek).isTrue()
        assertThat(state.rows).hasSize(2)
        assertThat(state.rows[0].cells).hasSize(7)
    }

    @Test
    fun `week navigation steps backward and forward by weeks`() = runTest {
        viewModel.previousWeek()
        assertThat(viewModel.weekStart.value).isEqualTo(isoMonday.minusWeeks(1))

        viewModel.nextWeek()
        assertThat(viewModel.weekStart.value).isEqualTo(isoMonday)

        viewModel.previousWeek()
        viewModel.currentWeek()
        assertThat(viewModel.weekStart.value).isEqualTo(isoMonday)
    }

    @Test
    fun `toggleCell creates and removes completion log in repository`() = runTest {
        advanceUntilIdle()
        viewModel.toggleCell("matrix_habit_1", isoMonday)
        advanceUntilIdle()

        var logs = fakeRepository.getLogsForHabitOnce("matrix_habit_1")
        assertThat(logs).isNotEmpty()
        assertThat(logs.first().completed).isTrue()

        // Toggle again to un-complete
        viewModel.toggleCell("matrix_habit_1", isoMonday)
        advanceUntilIdle()

        logs = fakeRepository.getLogsForHabitOnce("matrix_habit_1")
        assertThat(logs).isEmpty()
    }
}
