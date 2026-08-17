package com.productivity.habits.ui.daily

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.automirrored.filled.Sort
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.productivity.habits.data.local.preferences.ThemeMode
import com.productivity.habits.ui.common.HapticsHelper
import com.productivity.habits.ui.common.ThemeToggleButton
import com.productivity.habits.ui.form.HabitFormBottomSheet
import com.productivity.habits.ui.form.HabitFormViewModel
import com.productivity.habits.ui.gamification.GamificationViewModel
import com.productivity.habits.ui.gamification.LevelUpCelebrationDialog
import com.productivity.habits.ui.gamification.PlayerLevelHeaderBadge

enum class DashboardTab(val label: String) {
    DAILY("Daily"),
    MATRIX("Week Matrix"),
    ANALYTICS("Analytics")
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DailyTrackerScreen(
    themeMode: ThemeMode = ThemeMode.SYSTEM,
    onThemeModeSelected: (ThemeMode) -> Unit = {},
    onNavigateToDetail: (String) -> Unit,
    onNavigateToMatrix: () -> Unit,
    onNavigateToAnalytics: () -> Unit,
    onNavigateToBadges: () -> Unit = {},
    viewModel: DailyTrackerViewModel = hiltViewModel(),
    gamificationViewModel: GamificationViewModel = hiltViewModel(),
    modifier: Modifier = Modifier
) {
    val haptic = LocalHapticFeedback.current
    val uiState by viewModel.uiState.collectAsState()
    val gamificationState by gamificationViewModel.uiState.collectAsState()

    var showAddForm by remember { mutableStateOf(false) }
    var habitIdToEdit by remember { mutableStateOf<String?>(null) }
    var isSearchExpanded by remember { mutableStateOf(false) }
    var isSortMenuExpanded by remember { mutableStateOf(false) }

    val formViewModel: HabitFormViewModel = hiltViewModel()

    // Level-up celebration dialog host
    gamificationState.pendingCelebration?.let { celebration ->
        LevelUpCelebrationDialog(
            celebration = celebration,
            onDismiss = {
                gamificationViewModel.dismissCelebration(celebration.newLevel)
            }
        )
    }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    HapticsHelper.performLightHaptic(haptic)
                    formViewModel.resetForm()
                    habitIdToEdit = null
                    showAddForm = true
                },
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                shape = CircleShape
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "Add Habit",
                    modifier = Modifier.size(24.dp)
                )
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Top App Bar & Segmented Navigation
            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.surface,
                tonalElevation = 1.dp
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "Habits",
                                style = MaterialTheme.typography.headlineMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }

                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            PlayerLevelHeaderBadge(
                                progression = gamificationState.progression,
                                onClick = onNavigateToBadges
                            )

                            ThemeToggleButton(
                                currentTheme = themeMode,
                                onThemeSelected = onThemeModeSelected
                            )

                            IconButton(
                                onClick = {
                                    HapticsHelper.performLightHaptic(haptic)
                                    isSearchExpanded = !isSearchExpanded
                                }
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Search,
                                    contentDescription = "Search Habits",
                                    tint = if (isSearchExpanded) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }

                            Box {
                                IconButton(
                                    onClick = {
                                        HapticsHelper.performLightHaptic(haptic)
                                        isSortMenuExpanded = true
                                    }
                                ) {
                                    Icon(
                                        imageVector = Icons.AutoMirrored.Filled.Sort,
                                        contentDescription = "Sort Habits",
                                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }

                                DropdownMenu(
                                    expanded = isSortMenuExpanded,
                                    onDismissRequest = { isSortMenuExpanded = false }
                                ) {
                                    HabitSortOption.entries.forEach { option ->
                                        DropdownMenuItem(
                                            text = {
                                                Text(
                                                    text = option.displayName,
                                                    fontWeight = if (uiState.sortOption == option) FontWeight.Bold else FontWeight.Normal,
                                                    color = if (uiState.sortOption == option) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                                                )
                                            },
                                            onClick = {
                                                viewModel.setSortOption(option)
                                                isSortMenuExpanded = false
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Dashboard Tabs
                    SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                        DashboardTab.entries.forEachIndexed { index, tab ->
                            SegmentedButton(
                                selected = tab == DashboardTab.DAILY,
                                onClick = {
                                    HapticsHelper.performLightHaptic(haptic)
                                    when (tab) {
                                        DashboardTab.DAILY -> Unit
                                        DashboardTab.MATRIX -> onNavigateToMatrix()
                                        DashboardTab.ANALYTICS -> onNavigateToAnalytics()
                                    }
                                },
                                shape = SegmentedButtonDefaults.itemShape(index = index, count = DashboardTab.entries.size)
                            ) {
                                Text(tab.label)
                            }
                        }
                    }
                }
            }

            // Search Bar (Expandable)
            AnimatedVisibility(visible = isSearchExpanded) {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    color = MaterialTheme.colorScheme.surface
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = uiState.searchQuery,
                            onValueChange = viewModel::setSearchQuery,
                            placeholder = { Text("Search by title or description...") },
                            singleLine = true,
                            leadingIcon = {
                                Icon(
                                    imageVector = Icons.Default.Search,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            },
                            trailingIcon = {
                                if (uiState.searchQuery.isNotEmpty()) {
                                    IconButton(onClick = { viewModel.setSearchQuery("") }) {
                                        Icon(
                                            imageVector = Icons.Default.Clear,
                                            contentDescription = "Clear",
                                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                            },
                            shape = RoundedCornerShape(12.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                unfocusedBorderColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                            ),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            }

            // Historical Date Banner
            HistoricalBanner(
                selectedDate = uiState.selectedDate,
                onReturnToToday = viewModel::selectToday
            )

            // Rolling Week Strip
            RollingWeekStrip(
                selectedDate = uiState.selectedDate,
                weekLogs = uiState.weekLogs,
                onDateSelected = viewModel::selectDate,
                onPreviousDay = viewModel::previousDay,
                onNextDay = viewModel::nextDay,
                onTodayClick = viewModel::selectToday
            )

            // Category Chips Row
            if (uiState.categories.isNotEmpty()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(MaterialTheme.colorScheme.surface)
                        .horizontalScroll(rememberScrollState())
                        .padding(horizontal = 16.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    FilterChip(
                        selected = uiState.selectedCategoryId == null,
                        onClick = {
                            HapticsHelper.performLightHaptic(haptic)
                            viewModel.selectCategory(null)
                        },
                        label = { Text("All (${uiState.totalScheduledForSelectedDate})") }
                    )

                    uiState.categories.forEach { cat ->
                        val isSelected = uiState.selectedCategoryId == cat.id
                        FilterChip(
                            selected = isSelected,
                            onClick = {
                                HapticsHelper.performLightHaptic(haptic)
                                viewModel.selectCategory(cat.id)
                            },
                            label = { Text(cat.name) }
                        )
                    }
                }
            }

            // Habits List
            if (uiState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
                }
            } else if (uiState.habits.isEmpty()) {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = if (uiState.searchQuery.isNotEmpty()) "No matching habits found" else "No habits scheduled for this day",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "Tap '+' to create a new habit",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.outline
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth(),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(
                        items = uiState.habits,
                        key = { it.habit.id }
                    ) { habitWithProgress ->
                        HabitCard(
                            habitWithProgress = habitWithProgress,
                            onHabitClick = { habitId ->
                                onNavigateToDetail(habitId)
                            },
                            onToggleCheckIn = {
                                viewModel.toggleCheckIn(habitWithProgress.habit)
                            },
                            onValueChange = { newValue ->
                                viewModel.updateNumericValue(habitWithProgress.habit.id, newValue)
                            },
                            onDeltaAdd = { delta ->
                                viewModel.addNumericDelta(habitWithProgress.habit.id, delta)
                            },
                            onToggleSlot = { slotIndex ->
                                viewModel.toggleSlot(habitWithProgress.habit.id, slotIndex)
                            },
                            onTogglePin = {
                                viewModel.togglePinned(habitWithProgress.habit)
                            },
                            onStartFocus = {
                                onNavigateToDetail(habitWithProgress.habit.id)
                            }
                        )
                    }
                }
            }

            // Inline Quick Add Bar
            QuickAddBar(
                onQuickAdd = { title ->
                    viewModel.quickAddHabit(title, uiState.selectedCategoryId)
                },
                onOpenFullForm = {
                    formViewModel.resetForm()
                    habitIdToEdit = null
                    showAddForm = true
                },
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )
        }
    }

    // Full Add / Edit Habit Modal Bottom Sheet
    if (showAddForm) {
        HabitFormBottomSheet(
            viewModel = formViewModel,
            onDismiss = {
                showAddForm = false
                habitIdToEdit = null
            }
        )
    }
}
