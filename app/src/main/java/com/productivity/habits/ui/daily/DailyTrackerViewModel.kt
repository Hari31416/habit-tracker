package com.productivity.habits.ui.daily

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.productivity.habits.data.local.entity.HabitCategoryEntity
import com.productivity.habits.data.local.entity.HabitEntity
import com.productivity.habits.data.local.entity.HabitFrequencyType
import com.productivity.habits.data.local.entity.HabitLogEntity
import com.productivity.habits.data.local.entity.HabitTargetType
import com.productivity.habits.domain.engine.StreakCalculator
import com.productivity.habits.domain.model.HabitWithProgress
import com.productivity.habits.domain.repository.HabitRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import javax.inject.Inject

enum class HabitSortOption(val displayName: String) {
    PINNED_FIRST("Pinned First"),
    STREAK_DESC("Longest Streak"),
    ALPHABETICAL("Alphabetical"),
    CATEGORY("Category")
}

private data class FilterState(
    val date: LocalDate,
    val search: String,
    val categoryId: String?,
    val sort: HabitSortOption,
    val showArchived: Boolean
)

data class DailyTrackerUiState(
    val selectedDate: LocalDate = LocalDate.now(),
    val isToday: Boolean = true,
    val searchQuery: String = "",
    val selectedCategoryId: String? = null,
    val sortOption: HabitSortOption = HabitSortOption.PINNED_FIRST,
    val showArchived: Boolean = false,
    val categories: List<HabitCategoryEntity> = emptyList(),
    val habits: List<HabitWithProgress> = emptyList(),
    val weekLogs: Map<LocalDate, Int> = emptyMap(),
    val totalScheduledForSelectedDate: Int = 0,
    val totalCompletedForSelectedDate: Int = 0,
    val isLoading: Boolean = false
)

@HiltViewModel
class DailyTrackerViewModel @Inject constructor(
    private val repository: HabitRepository
) : ViewModel() {

    private val _selectedDate = MutableStateFlow(LocalDate.now())
    val selectedDate: StateFlow<LocalDate> = _selectedDate.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _selectedCategoryId = MutableStateFlow<String?>(null)
    val selectedCategoryId: StateFlow<String?> = _selectedCategoryId.asStateFlow()

    private val _sortOption = MutableStateFlow(HabitSortOption.PINNED_FIRST)
    val sortOption: StateFlow<HabitSortOption> = _sortOption.asStateFlow()

    private val _showArchived = MutableStateFlow(false)
    val showArchived: StateFlow<Boolean> = _showArchived.asStateFlow()

    val categories: StateFlow<List<HabitCategoryEntity>> = repository.getAllCategories()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val filterStateFlow = combine(
        _selectedDate,
        _searchQuery,
        _selectedCategoryId,
        _sortOption,
        _showArchived
    ) { date, search, categoryId, sort, showArch ->
        FilterState(date, search, categoryId, sort, showArch)
    }

    val uiState: StateFlow<DailyTrackerUiState> = combine(
        filterStateFlow,
        repository.getAllHabits(),
        repository.getAllLogs(),
        categories
    ) { filter, allHabits, allLogs, categoryList ->
        val date = filter.date
        val isToday = date == LocalDate.now()
        val categoryMap = categoryList.associateBy { it.id }

        val logsByHabit = allLogs.groupBy { it.habitId }
        val dateStr = date.toString()

        val filteredHabits = allHabits.filter { habit ->
            val matchArchived = if (filter.showArchived) true else !habit.archived
            val matchCategory = filter.categoryId == null || habit.categoryId == filter.categoryId
            val matchSearch = filter.search.isBlank() ||
                habit.title.contains(filter.search, ignoreCase = true) ||
                (habit.description?.contains(filter.search, ignoreCase = true) == true)
            val matchScheduled = StreakCalculator.isHabitScheduledOnDate(habit, date)

            matchArchived && matchCategory && matchSearch && matchScheduled
        }

        val habitsWithProgress = filteredHabits.map { habit ->
            val habitLogs = logsByHabit[habit.id] ?: emptyList()
            val logsOnDate = habitLogs.filter { it.date == dateStr }
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

            val currentDurationSeconds = logsOnDate.sumOf {
                it.durationSeconds ?: ((it.value ?: 0.0) * 60).toLong()
            }

            val streak = StreakCalculator.calculateStreak(habit, habitLogs, date)

            HabitWithProgress(
                habit = habit,
                category = habit.categoryId?.let { categoryMap[it] },
                logsForDate = logsOnDate,
                isCompletedOnDate = isCompleted,
                currentValueOnDate = currentValue,
                currentDurationSecondsOnDate = currentDurationSeconds,
                streak = streak
            )
        }

        val sortedHabits = when (filter.sort) {
            HabitSortOption.PINNED_FIRST -> habitsWithProgress.sortedWith(
                compareByDescending<HabitWithProgress> { it.habit.pinned }
                    .thenBy { it.isCompletedOnDate }
                    .thenBy { it.habit.title.lowercase() }
            )
            HabitSortOption.STREAK_DESC -> habitsWithProgress.sortedWith(
                compareByDescending<HabitWithProgress> { it.habit.pinned }
                    .thenByDescending { it.streak.currentStreak }
                    .thenBy { it.habit.title.lowercase() }
            )
            HabitSortOption.ALPHABETICAL -> habitsWithProgress.sortedWith(
                compareByDescending<HabitWithProgress> { it.habit.pinned }
                    .thenBy { it.habit.title.lowercase() }
            )
            HabitSortOption.CATEGORY -> habitsWithProgress.sortedWith(
                compareByDescending<HabitWithProgress> { it.habit.pinned }
                    .thenBy { it.category?.name ?: "ZZZ" }
                    .thenBy { it.habit.title.lowercase() }
            )
        }

        val weekLogsMap = mutableMapOf<LocalDate, Int>()
        for (offset in -3..3) {
            val d = date.plusDays(offset.toLong())
            val dStr = d.toString()
            val completedCount = allHabits.count { h ->
                !h.archived &&
                    StreakCalculator.isHabitScheduledOnDate(h, d) &&
                    StreakCalculator.isHabitCompletedOnDate(h, (logsByHabit[h.id] ?: emptyList()).filter { it.date == dStr })
            }
            weekLogsMap[d] = completedCount
        }

        val totalScheduled = sortedHabits.size
        val totalCompleted = sortedHabits.count { it.isCompletedOnDate }

        DailyTrackerUiState(
            selectedDate = date,
            isToday = isToday,
            searchQuery = filter.search,
            selectedCategoryId = filter.categoryId,
            sortOption = filter.sort,
            showArchived = filter.showArchived,
            categories = categoryList,
            habits = sortedHabits,
            weekLogs = weekLogsMap,
            totalScheduledForSelectedDate = totalScheduled,
            totalCompletedForSelectedDate = totalCompleted,
            isLoading = false
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        DailyTrackerUiState(isLoading = true)
    )

    fun selectDate(date: LocalDate) {
        _selectedDate.value = date
    }

    fun nextDay() {
        _selectedDate.value = _selectedDate.value.plusDays(1)
    }

    fun previousDay() {
        _selectedDate.value = _selectedDate.value.minusDays(1)
    }

    fun selectToday() {
        _selectedDate.value = LocalDate.now()
    }

    fun setSearchQuery(query: String) {
        _searchQuery.value = query
    }

    fun selectCategory(categoryId: String?) {
        _selectedCategoryId.value = if (_selectedCategoryId.value == categoryId) null else categoryId
    }

    fun setSortOption(option: HabitSortOption) {
        _sortOption.value = option
    }

    fun setShowArchived(show: Boolean) {
        _showArchived.value = show
    }

    fun toggleCheckIn(habit: HabitEntity) {
        viewModelScope.launch {
            repository.toggleBooleanCheckIn(habit.id, _selectedDate.value)
        }
    }

    fun updateNumericValue(habitId: String, value: Double) {
        viewModelScope.launch {
            repository.updateNumericValue(habitId, _selectedDate.value, value)
        }
    }

    fun addNumericDelta(habitId: String, delta: Double) {
        viewModelScope.launch {
            repository.addNumericDelta(habitId, _selectedDate.value, delta)
        }
    }

    fun toggleSlot(habitId: String, slotIndex: Int) {
        viewModelScope.launch {
            repository.toggleSlotCheckIn(habitId, _selectedDate.value, slotIndex)
        }
    }

    fun togglePinned(habit: HabitEntity) {
        viewModelScope.launch {
            repository.setPinned(habit.id, !habit.pinned)
        }
    }

    fun quickAddHabit(title: String, categoryId: String?) {
        if (title.isBlank()) return
        viewModelScope.launch {
            val now = Instant.now()
            val habit = HabitEntity(
                id = UUID.randomUUID().toString(),
                title = title.trim(),
                description = null,
                color = "#10B981",
                icon = "check",
                categoryId = categoryId,
                frequencyType = HabitFrequencyType.DAILY,
                targetType = HabitTargetType.BOOLEAN,
                createdAt = now,
                updatedAt = now
            )
            repository.upsertHabit(habit)
        }
    }
}
