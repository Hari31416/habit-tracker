package com.productivity.habits.ui.detail

import androidx.lifecycle.SavedStateHandle
import app.cash.turbine.test
import com.google.common.truth.Truth.assertThat
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.testutil.FakeHabitRepository
import com.productivity.habits.ui.navigation.Screen
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
class HabitDetailViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeRepository: FakeHabitRepository
    private lateinit var viewModel: HabitDetailViewModel

    private val now = Instant.now()
    private val today = LocalDate.now()

    private val sampleCategory = HabitCategoryEntity(
        id = "cat_reading",
        name = "Reading",
        color = "#8B5CF6",
        icon = "book-open"
    )

    private val sampleHabit = HabitEntity(
        id = "habit_detail_1",
        title = "Daily Reading",
        description = "Read 30 mins every day",
        color = "#8B5CF6",
        icon = "book-open",
        categoryId = "cat_reading",
        frequencyType = HabitFrequencyType.DAILY,
        targetType = HabitTargetType.NUMERIC,
        targetValue = 30.0,
        unit = "pages",
        reminderTimes = listOf("20:00", "22:00"),
        pinned = false,
        createdAt = now,
        updatedAt = now
    )

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        fakeRepository = FakeHabitRepository()
        fakeRepository.setCategories(listOf(sampleCategory))
        fakeRepository.setHabits(listOf(sampleHabit))

        val savedStateHandle = SavedStateHandle(mapOf(Screen.Detail.HABIT_ID_ARG to "habit_detail_1"))
        viewModel = HabitDetailViewModel(savedStateHandle, fakeRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state loads habit and computed metrics`() = runTest {
        advanceUntilIdle()
        val state = viewModel.uiState.first { !it.isLoading && it.habit != null }

        assertThat(state.habit?.id).isEqualTo("habit_detail_1")
        assertThat(state.category?.name).isEqualTo("Reading")
        assertThat(state.selectedDate).isEqualTo(today)
        assertThat(state.currentMonth).isEqualTo(YearMonth.now())
        assertThat(state.isDeleted).isFalse()
    }

    @Test
    fun `month navigation steps backwards and forwards`() = runTest {
        val currentMonth = YearMonth.now()
        viewModel.previousMonth()
        assertThat(viewModel.currentMonth.value).isEqualTo(currentMonth.minusMonths(1))

        viewModel.nextMonth()
        assertThat(viewModel.currentMonth.value).isEqualTo(currentMonth)
    }

    @Test
    fun `set10DotProgress updates repository with calculated target value`() = runTest {
        advanceUntilIdle()
        viewModel.set10DotProgress(15.0)
        advanceUntilIdle()

        val logs = fakeRepository.getLogsForHabitOnce("habit_detail_1")
        assertThat(logs).isNotEmpty()
        assertThat(logs.first().value).isEqualTo(15.0)
        assertThat(logs.first().completed).isFalse()

        // Set to full target
        viewModel.set10DotProgress(30.0)
        advanceUntilIdle()

        val updatedLogs = fakeRepository.getLogsForHabitOnce("habit_detail_1")
        assertThat(updatedLogs.first().value).isEqualTo(30.0)
        assertThat(updatedLogs.first().completed).isTrue()
    }

    @Test
    fun `setPinned and setArchived updates habit flags in repository`() = runTest {
        advanceUntilIdle()
        viewModel.setPinned(true)
        advanceUntilIdle()

        var habit = fakeRepository.getHabitByIdOnce("habit_detail_1")
        assertThat(habit?.pinned).isTrue()

        viewModel.setArchived(true)
        advanceUntilIdle()

        habit = fakeRepository.getHabitByIdOnce("habit_detail_1")
        assertThat(habit?.archived).isTrue()
    }

    @Test
    fun `deleteHabit removes habit from repository and emits navigateBackEvent`() = runTest {
        viewModel.navigateBackEvent.test {
            viewModel.deleteHabit()
            advanceUntilIdle()

            assertThat(awaitItem()).isEqualTo(Unit)

            val habit = fakeRepository.getHabitByIdOnce("habit_detail_1")
            assertThat(habit).isNull()
        }
    }

    @Test
    fun `toggleReminder adds or removes reminder time`() = runTest {
        advanceUntilIdle()
        viewModel.toggleReminder("09:00") // add
        advanceUntilIdle()

        var habit = fakeRepository.getHabitByIdOnce("habit_detail_1")
        assertThat(habit?.reminderTimes).contains("09:00")

        viewModel.toggleReminder("20:00") // remove
        advanceUntilIdle()

        habit = fakeRepository.getHabitByIdOnce("habit_detail_1")
        assertThat(habit?.reminderTimes).doesNotContain("20:00")
    }
}
