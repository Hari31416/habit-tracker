package com.productivity.habits.ui.detail

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.domain.engine.StreakResult
import com.productivity.habits.domain.repository.HabitRepository
import com.productivity.habits.ui.navigation.Screen
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.YearMonth
import javax.inject.Inject

data class HabitDetailUiState(
    val habit: HabitEntity? = null,
    val category: HabitCategoryEntity? = null,
    val allLogs: List<HabitLogEntity> = emptyList(),
    val selectedDate: LocalDate = LocalDate.now(),
    val currentMonth: YearMonth = YearMonth.now(),
    val streak: StreakResult = StreakResult(0, 0, 0, 0),
    val isCompletedOnSelectedDate: Boolean = false,
    val currentValueOnSelectedDate: Double = 0.0,
    val isLoading: Boolean = true,
    val isDeleted: Boolean = false
)

@HiltViewModel
class HabitDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: HabitRepository
) : ViewModel() {

    val habitId: String = savedStateHandle.get<String>(Screen.Detail.HABIT_ID_ARG) ?: ""

    private val _selectedDate = MutableStateFlow(LocalDate.now())
    val selectedDate: StateFlow<LocalDate> = _selectedDate.asStateFlow()

    private val _currentMonth = MutableStateFlow(YearMonth.now())
    val currentMonth: StateFlow<YearMonth> = _currentMonth.asStateFlow()

    private val _navigateBackEvent = MutableSharedFlow<Unit>()
    val navigateBackEvent: SharedFlow<Unit> = _navigateBackEvent.asSharedFlow()

    val uiState: StateFlow<HabitDetailUiState> = combine(
        repository.getHabitById(habitId),
        repository.getLogsForHabit(habitId),
        repository.getAllCategories(),
        _selectedDate,
        _currentMonth
    ) { habit, logs, categories, date, month ->
        if (habit == null) {
            HabitDetailUiState(isLoading = false, isDeleted = true)
        } else {
            val category = categories.find { it.id == habit.categoryId }
            val dateStr = date.toString()
            val logsOnDate = logs.filter { it.date == dateStr }
            val isCompleted = StreakCalculator.isHabitCompletedOnDate(habit, logsOnDate)

            val currentValue = when (habit.targetType) {
                HabitTargetType.BOOLEAN -> if (isCompleted) 1.0 else 0.0
                HabitTargetType.NUMERIC -> logsOnDate.sumOf { it.value ?: if (it.completed) (habit.targetValue ?: 1.0) else 0.0 }
                HabitTargetType.TIMER -> logsOnDate.sumOf {
                    if (it.durationSeconds != null && it.durationSeconds > 0) {
                        it.durationSeconds / 60.0
                    } else {
                        it.value ?: if (it.completed) (habit.targetValue ?: 25.0) else 0.0
                    }
                }
            }

            val streak = StreakCalculator.calculateStreak(habit, logs, LocalDate.now())

            HabitDetailUiState(
                habit = habit,
                category = category,
                allLogs = logs,
                selectedDate = date,
                currentMonth = month,
                streak = streak,
                isCompletedOnSelectedDate = isCompleted,
                currentValueOnSelectedDate = currentValue,
                isLoading = false,
                isDeleted = false
            )
        }
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        HabitDetailUiState(isLoading = true)
    )

    fun selectDate(date: LocalDate) {
        _selectedDate.value = date
    }

    fun previousMonth() {
        _currentMonth.value = _currentMonth.value.minusMonths(1)
    }

    fun nextMonth() {
        _currentMonth.value = _currentMonth.value.plusMonths(1)
    }

    fun setPinned(pinned: Boolean) {
        viewModelScope.launch {
            repository.setPinned(habitId, pinned)
        }
    }

    fun setArchived(archived: Boolean) {
        viewModelScope.launch {
            repository.setArchived(habitId, archived)
        }
    }

    fun deleteHabit() {
        viewModelScope.launch {
            val habit = repository.getHabitByIdOnce(habitId)
            if (habit != null) {
                repository.deleteHabit(habit)
                _navigateBackEvent.emit(Unit)
            }
        }
    }

    fun set10DotProgress(targetValueForDot: Double) {
        viewModelScope.launch {
            repository.updateNumericValue(habitId, _selectedDate.value, targetValueForDot)
        }
    }

    fun toggleCheckInForDate(date: LocalDate) {
        viewModelScope.launch {
            repository.toggleBooleanCheckIn(habitId, date)
        }
    }

    fun toggleReminder(time: String) {
        viewModelScope.launch {
            val habit = repository.getHabitByIdOnce(habitId) ?: return@launch
            val updatedReminders = if (habit.reminderTimes.contains(time)) {
                habit.reminderTimes.filter { it != time }
            } else {
                (habit.reminderTimes + time).sorted()
            }
            repository.upsertHabit(habit.copy(reminderTimes = updatedReminders))
        }
    }
}
