package com.productivity.habits.ui.form

import app.cash.turbine.test
import com.google.common.truth.Truth.assertThat
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
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

@OptIn(ExperimentalCoroutinesApi::class)
class HabitFormViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeRepository: FakeHabitRepository
    private lateinit var viewModel: HabitFormViewModel

    private val sampleCategory = HabitCategoryEntity(
        id = "cat_fitness",
        name = "Fitness",
        color = "#10B981",
        icon = "activity"
    )

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        fakeRepository = FakeHabitRepository()
        fakeRepository.setCategories(listOf(sampleCategory))
        viewModel = HabitFormViewModel(fakeRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `save with empty title fails with validation error`() = runTest {
        viewModel.onTitleChange("")
        viewModel.saveHabit()
        advanceUntilIdle()

        val state = viewModel.formState.value
        assertThat(state.titleError).isNotNull()
        assertThat(fakeRepository.getAllHabits().first()).isEmpty()
    }

    @Test
    fun `save with invalid numeric target fails with validation error`() = runTest {
        viewModel.onTitleChange("Drink Water")
        viewModel.onTargetTypeChange(HabitTargetType.NUMERIC)
        viewModel.onTargetValueChange("-5")
        viewModel.saveHabit()
        advanceUntilIdle()

        val state = viewModel.formState.value
        assertThat(state.targetValueError).isNotNull()
        assertThat(fakeRepository.getAllHabits().first()).isEmpty()
    }

    @Test
    fun `save valid habit succeeds and emits saveSuccessEvent`() = runTest {
        viewModel.saveSuccessEvent.test {
            viewModel.onTitleChange("Morning Run")
            viewModel.onCategoryChange("cat_fitness")
            viewModel.onColorChange("#10B981")
            viewModel.onIconChange("run")
            viewModel.onTargetTypeChange(HabitTargetType.NUMERIC)
            viewModel.onTargetValueChange("5")
            viewModel.onUnitChange("km")
            viewModel.onFrequencyTypeChange(HabitFrequencyType.CUSTOM_DAYS)
            viewModel.addReminderTime("07:00")
            viewModel.saveHabit()

            advanceUntilIdle()

            assertThat(awaitItem()).isEqualTo(Unit)

            val habits = fakeRepository.getAllHabits().first()
            assertThat(habits).hasSize(1)
            val created = habits[0]
            assertThat(created.title).isEqualTo("Morning Run")
            assertThat(created.targetType).isEqualTo(HabitTargetType.NUMERIC)
            assertThat(created.targetValue).isEqualTo(5.0)
            assertThat(created.unit).isEqualTo("km")
            assertThat(created.frequencyType).isEqualTo(HabitFrequencyType.CUSTOM_DAYS)
            assertThat(created.reminderTimes).contains("07:00")
        }
    }

    @Test
    fun `load existing habit for edit populates state correctly`() = runTest {
        val now = Instant.now()
        val existingHabit = HabitEntity(
            id = "habit_edit_1",
            title = "Read Books",
            description = "Read before sleep",
            color = "#8B5CF6",
            icon = "book-open",
            categoryId = "cat_fitness",
            frequencyType = HabitFrequencyType.WEEKLY,
            targetCountPerWeek = 4,
            targetType = HabitTargetType.TIMER,
            targetValue = 30.0,
            unit = "mins",
            reminderTimes = listOf("21:00"),
            pinned = true,
            createdAt = now,
            updatedAt = now
        )
        fakeRepository.upsertHabit(existingHabit)

        viewModel.loadHabit("habit_edit_1")
        advanceUntilIdle()

        val state = viewModel.formState.value
        assertThat(state.isEditMode).isTrue()
        assertThat(state.habitId).isEqualTo("habit_edit_1")
        assertThat(state.title).isEqualTo("Read Books")
        assertThat(state.description).isEqualTo("Read before sleep")
        assertThat(state.targetType).isEqualTo(HabitTargetType.TIMER)
        assertThat(state.targetValue).isEqualTo("30")
        assertThat(state.frequencyType).isEqualTo(HabitFrequencyType.WEEKLY)
        assertThat(state.targetCountPerWeek).isEqualTo(4)
        assertThat(state.reminderTimes).containsExactly("21:00")
        assertThat(state.pinned).isTrue()
    }

    @Test
    fun `saving edited habit preserves id and creation timestamp`() = runTest {
        val initialCreated = Instant.ofEpochMilli(1000000L)
        val existingHabit = HabitEntity(
            id = "habit_edit_2",
            title = "Old Title",
            color = "#10B981",
            frequencyType = HabitFrequencyType.DAILY,
            targetType = HabitTargetType.BOOLEAN,
            createdAt = initialCreated,
            updatedAt = initialCreated
        )
        fakeRepository.upsertHabit(existingHabit)

        viewModel.loadHabit("habit_edit_2")
        advanceUntilIdle()

        viewModel.onTitleChange("Updated Title")
        viewModel.saveHabit()
        advanceUntilIdle()

        val updated = fakeRepository.getHabitByIdOnce("habit_edit_2")
        assertThat(updated).isNotNull()
        assertThat(updated?.title).isEqualTo("Updated Title")
        assertThat(updated?.createdAt).isEqualTo(initialCreated)
    }
}
