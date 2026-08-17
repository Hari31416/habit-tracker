package com.productivity.habits.scheduler

import android.content.Context
import android.content.ContextWrapper
import com.google.common.truth.Truth.assertThat
import com.productivity.habits.data.local.dao.HabitDao
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitTargetType
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import org.junit.Before
import org.junit.Test
import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

class AlarmHabitReminderSchedulerTest {

    private lateinit var scheduler: AlarmHabitReminderScheduler
    private val now = Instant.now()

    private val fakeDao = object : HabitDao {
        override fun getAllHabits(): Flow<List<HabitEntity>> = emptyFlow()
        override fun getActiveHabits(): Flow<List<HabitEntity>> = emptyFlow()
        override suspend fun getActiveHabitsOnce(): List<HabitEntity> = emptyList()
        override fun getArchivedHabits(): Flow<List<HabitEntity>> = emptyFlow()
        override fun getPinnedHabits(): Flow<List<HabitEntity>> = emptyFlow()
        override fun getHabitById(id: String): Flow<HabitEntity?> = emptyFlow()
        override suspend fun getHabitByIdOnce(id: String): HabitEntity? = null
        override fun getHabitsByCategory(categoryId: String): Flow<List<HabitEntity>> = emptyFlow()
        override suspend fun upsertHabit(habit: HabitEntity) {}
        override suspend fun insertHabits(habits: List<HabitEntity>) {}
        override suspend fun updateHabit(habit: HabitEntity) {}
        override suspend fun deleteHabit(habit: HabitEntity) {}
        override suspend fun deleteHabitById(id: String) {}
        override suspend fun updatePinned(id: String, pinned: Boolean, updatedAt: Instant) {}
        override suspend fun updateArchived(id: String, archived: Boolean, updatedAt: Instant) {}
    }

    @Before
    fun setup() {
        val fakeContext = object : ContextWrapper(null) {
            override fun getSystemService(name: String): Any? = null
            override fun getApplicationContext(): Context = this
        }
        scheduler = AlarmHabitReminderScheduler(fakeContext, fakeDao)
    }

    @Test
    fun `calculateNextOccurrence returns today when reminder time is in future`() {
        val habit = HabitEntity(
            id = "habit_1",
            title = "Morning Workout",
            color = "#10B981",
            frequencyType = HabitFrequencyType.DAILY,
            targetType = HabitTargetType.BOOLEAN,
            createdAt = now,
            updatedAt = now
        )

        val referenceDateTime = LocalDateTime.of(2026, 8, 17, 8, 0)
        val reminderTime = LocalTime.of(10, 0)

        val nextOccurrence = scheduler.calculateNextOccurrence(habit, reminderTime, referenceDateTime)

        assertThat(nextOccurrence.toLocalDate()).isEqualTo(LocalDate.of(2026, 8, 17))
        assertThat(nextOccurrence.toLocalTime()).isEqualTo(LocalTime.of(10, 0))
    }

    @Test
    fun `calculateNextOccurrence returns tomorrow when reminder time is in past for daily habit`() {
        val habit = HabitEntity(
            id = "habit_1",
            title = "Morning Workout",
            color = "#10B981",
            frequencyType = HabitFrequencyType.DAILY,
            targetType = HabitTargetType.BOOLEAN,
            createdAt = now,
            updatedAt = now
        )

        val referenceDateTime = LocalDateTime.of(2026, 8, 17, 12, 0)
        val reminderTime = LocalTime.of(8, 0)

        val nextOccurrence = scheduler.calculateNextOccurrence(habit, reminderTime, referenceDateTime)

        assertThat(nextOccurrence.toLocalDate()).isEqualTo(LocalDate.of(2026, 8, 18))
        assertThat(nextOccurrence.toLocalTime()).isEqualTo(LocalTime.of(8, 0))
    }

    @Test
    fun `calculateNextOccurrence for custom days habit skips non-scheduled days`() {
        // Monday = 1, Wednesday = 3, Friday = 5
        val habit = HabitEntity(
            id = "habit_2",
            title = "Gym Session",
            color = "#6366F1",
            frequencyType = HabitFrequencyType.CUSTOM_DAYS,
            targetDaysOfWeek = listOf(1, 3, 5), // Mon, Wed, Fri
            targetType = HabitTargetType.BOOLEAN,
            createdAt = now,
            updatedAt = now
        )

        // Reference: Monday evening (past 08:00) -> next scheduled day is Wednesday
        val mondayEvening = LocalDateTime.of(2026, 8, 17, 20, 0) // Aug 17, 2026 is Monday
        val reminderTime = LocalTime.of(8, 0)

        val nextOccurrence = scheduler.calculateNextOccurrence(habit, reminderTime, mondayEvening)

        // Should be Wednesday Aug 19, 2026
        assertThat(nextOccurrence.toLocalDate()).isEqualTo(LocalDate.of(2026, 8, 19))
        assertThat(nextOccurrence.dayOfWeek).isEqualTo(DayOfWeek.WEDNESDAY)
        assertThat(nextOccurrence.toLocalTime()).isEqualTo(LocalTime.of(8, 0))
    }
}
