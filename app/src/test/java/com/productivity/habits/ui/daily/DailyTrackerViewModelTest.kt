package com.productivity.habits.ui.daily

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

@OptIn(ExperimentalCoroutinesApi::class)
class DailyTrackerViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeRepository: FakeHabitRepository
    private lateinit var viewModel: DailyTrackerViewModel

    private val today = LocalDate.now()
    private val now = Instant.now()

    private val sampleCategory = HabitCategoryEntity(
        id = "cat_health",
        name = "Health",
        color = "#10B981",
        icon = "heart"
    )

    private val habit1 = HabitEntity(
        id = "habit_1",
        title = "Morning Meditation",
        description = "10 minutes mindful breathing",
        color = "#8B5CF6",
        icon = "brain",
        categoryId = "cat_health",
        frequencyType = HabitFrequencyType.DAILY,
        targetType = HabitTargetType.BOOLEAN,
        pinned = false,
        createdAt = now,
        updatedAt = now
    )

    private val habit2 = HabitEntity(
        id = "habit_2",
        title = "Drink Water",
        description = "Stay hydrated",
        color = "#06B6D4",
        icon = "droplet",
        categoryId = "cat_health",
        frequencyType = HabitFrequencyType.DAILY,
        targetType = HabitTargetType.NUMERIC,
        targetValue = 2000.0,
        unit = "ml",
        pinned = true,
        createdAt = now,
        updatedAt = now
    )

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        fakeRepository = FakeHabitRepository()
        fakeRepository.setCategories(listOf(sampleCategory))
        fakeRepository.setHabits(listOf(habit1, habit2))
        viewModel = DailyTrackerViewModel(fakeRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state loads habits with pinned sorted first`() = runTest {
        advanceUntilIdle()
        val state = viewModel.uiState.first { !it.isLoading && it.habits.isNotEmpty() }

        assertThat(state.selectedDate).isEqualTo(today)
        assertThat(state.isToday).isTrue()
        assertThat(state.habits).hasSize(2)
        // Pinned habit2 should be first
        assertThat(state.habits[0].habit.id).isEqualTo("habit_2")
        assertThat(state.habits[1].habit.id).isEqualTo("habit_1")
    }

    @Test
    fun `date navigation advances and steps backward correctly`() = runTest {
        viewModel.nextDay()
        assertThat(viewModel.selectedDate.value).isEqualTo(today.plusDays(1))

        viewModel.previousDay()
        assertThat(viewModel.selectedDate.value).isEqualTo(today)

        val pastDate = today.minusDays(5)
        viewModel.selectDate(pastDate)
        assertThat(viewModel.selectedDate.value).isEqualTo(pastDate)

        viewModel.selectToday()
        assertThat(viewModel.selectedDate.value).isEqualTo(today)
    }

    @Test
    fun `search query filters habits by title`() = runTest {
        advanceUntilIdle()
        viewModel.setSearchQuery("Meditation")
        advanceUntilIdle()

        val state = viewModel.uiState.first { it.searchQuery == "Meditation" }
        assertThat(state.habits).hasSize(1)
        assertThat(state.habits[0].habit.id).isEqualTo("habit_1")
    }

    @Test
    fun `category filter filters habits correctly`() = runTest {
        advanceUntilIdle()
        viewModel.selectCategory("cat_health")
        advanceUntilIdle()

        val state = viewModel.uiState.first { it.selectedCategoryId == "cat_health" }
        assertThat(state.habits).hasSize(2)

        viewModel.selectCategory("cat_non_existent")
        advanceUntilIdle()
        val emptyState = viewModel.uiState.first { it.selectedCategoryId == "cat_non_existent" }
        assertThat(emptyState.habits).isEmpty()
    }

    @Test
    fun `toggle boolean check in updates completion status`() = runTest {
        advanceUntilIdle()
        viewModel.toggleCheckIn(habit1)
        advanceUntilIdle()

        val logs = fakeRepository.getLogsForHabitOnce("habit_1")
        assertThat(logs).isNotEmpty()
        assertThat(logs.first().completed).isTrue()
    }

    @Test
    fun `update numeric value and add delta updates repository`() = runTest {
        advanceUntilIdle()
        viewModel.updateNumericValue("habit_2", 1000.0)
        advanceUntilIdle()

        var logs = fakeRepository.getLogsForHabitOnce("habit_2")
        assertThat(logs).isNotEmpty()
        assertThat(logs.first().value).isEqualTo(1000.0)
        assertThat(logs.first().completed).isFalse()

        viewModel.addNumericDelta("habit_2", 1000.0)
        advanceUntilIdle()

        logs = fakeRepository.getLogsForHabitOnce("habit_2")
        assertThat(logs.first().value).isEqualTo(2000.0)
        assertThat(logs.first().completed).isTrue()
    }

    @Test
    fun `toggle pinned toggles habit pin flag`() = runTest {
        advanceUntilIdle()
        viewModel.togglePinned(habit1)
        advanceUntilIdle()

        val updated = fakeRepository.getHabitByIdOnce("habit_1")
        assertThat(updated?.pinned).isTrue()
    }

    @Test
    fun `quick add habit creates new daily boolean habit`() = runTest {
        viewModel.quickAddHabit("Read 10 pages", "cat_health")
        advanceUntilIdle()

        val habits = fakeRepository.getAllHabits().first()
        val created = habits.find { it.title == "Read 10 pages" }
        assertThat(created).isNotNull()
        assertThat(created?.frequencyType).isEqualTo(HabitFrequencyType.DAILY)
        assertThat(created?.targetType).isEqualTo(HabitTargetType.BOOLEAN)
        assertThat(created?.categoryId).isEqualTo("cat_health")
    }
}
