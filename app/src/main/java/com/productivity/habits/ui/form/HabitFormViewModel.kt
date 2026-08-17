package com.productivity.habits.ui.form

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.data.local.entity.TimeWindow
import com.productivity.habits.domain.repository.HabitRepository
import com.productivity.habits.ui.theme.HABIT_PRESET_COLORS
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.Instant
import java.util.UUID
import javax.inject.Inject

data class HabitFormState(
    val habitId: String? = null,
    val isEditMode: Boolean = false,
    val title: String = "",
    val description: String = "",
    val motivationNotes: String = "",
    val categoryId: String? = null,
    val color: String = HABIT_PRESET_COLORS[0],
    val icon: String = "check",
    val targetType: HabitTargetType = HabitTargetType.BOOLEAN,
    val targetValue: String = "1",
    val unit: String = "",
    val frequencyType: HabitFrequencyType = HabitFrequencyType.DAILY,
    val targetDaysOfWeek: Set<Int> = setOf(0, 1, 2, 3, 4, 5, 6), // 0 = Sun, 1 = Mon ... 6 = Sat
    val targetCountPerWeek: Int = 3,
    val intervalHours: Int = 2,
    val timesPerDay: Int = 3,
    val timeWindowStart: String = "08:00",
    val timeWindowEnd: String = "20:00",
    val reminderTimes: List<String> = emptyList(),
    val pinned: Boolean = false,
    val titleError: String? = null,
    val targetValueError: String? = null,
    val isSaving: Boolean = false
)

@HiltViewModel
class HabitFormViewModel @Inject constructor(
    private val repository: HabitRepository
) : ViewModel() {

    private val _formState = MutableStateFlow(HabitFormState())
    val formState: StateFlow<HabitFormState> = _formState.asStateFlow()

    private val _saveSuccessEvent = MutableSharedFlow<Unit>()
    val saveSuccessEvent: SharedFlow<Unit> = _saveSuccessEvent.asSharedFlow()

    val categories: StateFlow<List<HabitCategoryEntity>> = repository.getAllCategories()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun loadHabit(habitId: String) {
        viewModelScope.launch {
            val habit = repository.getHabitByIdOnce(habitId) ?: return@launch
            _formState.value = HabitFormState(
                habitId = habit.id,
                isEditMode = true,
                title = habit.title,
                description = habit.description ?: "",
                motivationNotes = habit.motivationNotes ?: "",
                categoryId = habit.categoryId,
                color = habit.color,
                icon = habit.icon ?: "check",
                targetType = habit.targetType,
                targetValue = habit.targetValue?.let {
                    if (it % 1.0 == 0.0) it.toInt().toString() else it.toString()
                } ?: "1",
                unit = habit.unit ?: "",
                frequencyType = habit.frequencyType,
                targetDaysOfWeek = habit.targetDaysOfWeek?.toSet() ?: setOf(0, 1, 2, 3, 4, 5, 6),
                targetCountPerWeek = habit.targetCountPerWeek ?: 3,
                intervalHours = habit.intervalHours ?: 2,
                timesPerDay = habit.timesPerDay ?: 3,
                timeWindowStart = habit.timeWindow?.startTime ?: "08:00",
                timeWindowEnd = habit.timeWindow?.endTime ?: "20:00",
                reminderTimes = habit.reminderTimes,
                pinned = habit.pinned
            )
        }
    }

    fun resetForm() {
        _formState.value = HabitFormState()
    }

    fun onTitleChange(title: String) {
        _formState.update { it.copy(title = title, titleError = null) }
    }

    fun onDescriptionChange(desc: String) {
        _formState.update { it.copy(description = desc) }
    }

    fun onMotivationChange(notes: String) {
        _formState.update { it.copy(motivationNotes = notes) }
    }

    fun onCategoryChange(categoryId: String?) {
        _formState.update { it.copy(categoryId = categoryId) }
    }

    fun onColorChange(colorHex: String) {
        _formState.update { it.copy(color = colorHex) }
    }

    fun onIconChange(iconKey: String) {
        _formState.update { it.copy(icon = iconKey) }
    }

    fun onTargetTypeChange(type: HabitTargetType) {
        _formState.update {
            val defaultTarget = when (type) {
                HabitTargetType.BOOLEAN -> "1"
                HabitTargetType.NUMERIC -> "8"
                HabitTargetType.TIMER -> "25"
            }
            val defaultUnit = when (type) {
                HabitTargetType.BOOLEAN -> ""
                HabitTargetType.NUMERIC -> "glasses"
                HabitTargetType.TIMER -> "mins"
            }
            it.copy(targetType = type, targetValue = defaultTarget, unit = defaultUnit, targetValueError = null)
        }
    }

    fun onTargetValueChange(value: String) {
        _formState.update { it.copy(targetValue = value, targetValueError = null) }
    }

    fun onUnitChange(unit: String) {
        _formState.update { it.copy(unit = unit) }
    }

    fun onFrequencyTypeChange(type: HabitFrequencyType) {
        _formState.update { it.copy(frequencyType = type) }
    }

    fun toggleDayOfWeek(dayIndex: Int) {
        _formState.update { current ->
            val updatedDays = current.targetDaysOfWeek.toMutableSet()
            if (updatedDays.contains(dayIndex)) {
                if (updatedDays.size > 1) { // keep at least one day
                    updatedDays.remove(dayIndex)
                }
            } else {
                updatedDays.add(dayIndex)
            }
            current.copy(targetDaysOfWeek = updatedDays)
        }
    }

    fun onTargetCountPerWeekChange(count: Int) {
        _formState.update { it.copy(targetCountPerWeek = count.coerceIn(1, 6)) }
    }

    fun onIntervalHoursChange(hours: Int) {
        _formState.update { it.copy(intervalHours = hours.coerceIn(1, 12)) }
    }

    fun onTimesPerDayChange(count: Int) {
        _formState.update { it.copy(timesPerDay = count.coerceIn(1, 12)) }
    }

    fun onTimeWindowChange(start: String, end: String) {
        _formState.update { it.copy(timeWindowStart = start, timeWindowEnd = end) }
    }

    fun addReminderTime(time: String) {
        _formState.update { current ->
            if (!current.reminderTimes.contains(time)) {
                current.copy(reminderTimes = (current.reminderTimes + time).sorted())
            } else current
        }
    }

    fun removeReminderTime(time: String) {
        _formState.update { current ->
            current.copy(reminderTimes = current.reminderTimes.filter { it != time })
        }
    }

    fun onTogglePinned() {
        _formState.update { it.copy(pinned = !it.pinned) }
    }

    fun saveHabit() {
        val state = _formState.value
        if (state.title.isBlank()) {
            _formState.update { it.copy(titleError = "Title is required") }
            return
        }

        val targetValParsed = state.targetValue.toDoubleOrNull()
        if (state.targetType != HabitTargetType.BOOLEAN && (targetValParsed == null || targetValParsed <= 0)) {
            _formState.update { it.copy(targetValueError = "Enter a valid positive number") }
            return
        }

        viewModelScope.launch {
            _formState.update { it.copy(isSaving = true) }
            val now = Instant.now()
            val existingHabit = state.habitId?.let { repository.getHabitByIdOnce(it) }

            val habit = HabitEntity(
                id = state.habitId ?: UUID.randomUUID().toString(),
                title = state.title.trim(),
                description = state.description.trim().ifEmpty { null },
                color = state.color,
                icon = state.icon,
                categoryId = state.categoryId,
                frequencyType = state.frequencyType,
                targetDaysOfWeek = if (state.frequencyType == HabitFrequencyType.CUSTOM_DAYS) {
                    state.targetDaysOfWeek.toList().sorted()
                } else null,
                targetCountPerWeek = if (state.frequencyType == HabitFrequencyType.WEEKLY) {
                    state.targetCountPerWeek
                } else null,
                intervalHours = if (state.frequencyType == HabitFrequencyType.SUBDAY_INTERVAL) {
                    state.intervalHours
                } else null,
                timesPerDay = if (state.frequencyType == HabitFrequencyType.TIMES_PER_DAY) {
                    state.timesPerDay
                } else null,
                timeWindow = if (state.frequencyType == HabitFrequencyType.SUBDAY_INTERVAL || state.frequencyType == HabitFrequencyType.TIMES_PER_DAY) {
                    TimeWindow(state.timeWindowStart, state.timeWindowEnd)
                } else null,
                targetType = state.targetType,
                targetValue = if (state.targetType == HabitTargetType.BOOLEAN) 1.0 else (targetValParsed ?: 1.0),
                unit = if (state.targetType == HabitTargetType.BOOLEAN) null else state.unit.trim().ifEmpty { null },
                pinned = state.pinned,
                reminderTimes = state.reminderTimes,
                motivationNotes = state.motivationNotes.trim().ifEmpty { null },
                archived = existingHabit?.archived ?: false,
                createdAt = existingHabit?.createdAt ?: now,
                updatedAt = now
            )

            repository.upsertHabit(habit)
            _formState.update { it.copy(isSaving = false) }
            _saveSuccessEvent.emit(Unit)
        }
    }
}
