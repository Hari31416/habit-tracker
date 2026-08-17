package com.productivity.habits.ui.gamification

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.productivity.habits.domain.gamification.AchievementCategory
import com.productivity.habits.domain.gamification.AchievementStatus
import com.productivity.habits.domain.gamification.LevelUpCelebration
import com.productivity.habits.domain.gamification.PlayerProgression
import com.productivity.habits.domain.repository.GamificationRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class GamificationUiState(
    val progression: PlayerProgression = PlayerProgression(),
    val selectedCategory: AchievementCategory = AchievementCategory.ALL,
    val allAchievements: List<AchievementStatus> = emptyList(),
    val filteredAchievements: List<AchievementStatus> = emptyList(),
    val pendingCelebration: LevelUpCelebration? = null,
    val isLoading: Boolean = false
)

@HiltViewModel
class GamificationViewModel @Inject constructor(
    private val repository: GamificationRepository
) : ViewModel() {

    private val _selectedCategory = MutableStateFlow(AchievementCategory.ALL)
    val selectedCategory: StateFlow<AchievementCategory> = _selectedCategory.asStateFlow()

    val uiState: StateFlow<GamificationUiState> = combine(
        repository.getPlayerProgression(),
        repository.getAchievements(),
        repository.getPendingCelebration(),
        _selectedCategory
    ) { progression, achievements, celebration, category ->
        val filtered = if (category == AchievementCategory.ALL) {
            achievements
        } else {
            achievements.filter { it.definition.category == category }
        }

        GamificationUiState(
            progression = progression,
            selectedCategory = category,
            allAchievements = achievements,
            filteredAchievements = filtered,
            pendingCelebration = celebration,
            isLoading = false
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        GamificationUiState(isLoading = true)
    )

    fun selectCategory(category: AchievementCategory) {
        _selectedCategory.value = category
    }

    fun dismissCelebration(level: Int) {
        viewModelScope.launch {
            repository.dismissCelebration(level)
        }
    }
}
