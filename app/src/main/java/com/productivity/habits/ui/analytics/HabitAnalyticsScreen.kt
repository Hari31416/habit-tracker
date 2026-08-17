package com.productivity.habits.ui.analytics

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.TrendingDown
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.productivity.habits.data.local.preferences.ThemeMode
import com.productivity.habits.ui.common.ColorUtils
import com.productivity.habits.ui.common.HabitIconRegistry
import com.productivity.habits.ui.common.HapticsHelper
import com.productivity.habits.ui.common.ThemeToggleButton
import com.productivity.habits.ui.form.HabitFormBottomSheet
import com.productivity.habits.ui.form.HabitFormViewModel
import com.productivity.habits.ui.gamification.GamificationViewModel
import com.productivity.habits.ui.navigation.HabitBottomNavigation
import com.productivity.habits.ui.navigation.Screen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HabitAnalyticsScreen(
    themeMode: ThemeMode = ThemeMode.SYSTEM,
    onThemeModeSelected: (ThemeMode) -> Unit = {},
    onNavigateToDaily: () -> Unit,
    onNavigateToMatrix: () -> Unit,
    onNavigateToDetail: (String) -> Unit,
    onNavigateToBadges: () -> Unit = {},
    viewModel: AnalyticsViewModel = hiltViewModel(),
    gamificationViewModel: GamificationViewModel = hiltViewModel(),
    modifier: Modifier = Modifier
) {
    val haptic = LocalHapticFeedback.current
    val uiState by viewModel.uiState.collectAsState()

    var showAddForm by remember { mutableStateOf(false) }
    val formViewModel: HabitFormViewModel = hiltViewModel()

    Scaffold(
        modifier = modifier.fillMaxSize(),
        bottomBar = {
            HabitBottomNavigation(
                currentRoute = Screen.Analytics.route,
                onNavigate = { route ->
                    when (route) {
                        Screen.Daily.route -> onNavigateToDaily()
                        Screen.WeekMatrix.route -> onNavigateToMatrix()
                        Screen.Analytics.route -> Unit
                        Screen.Badges.route -> onNavigateToBadges()
                    }
                },
                onAddHabitClick = {
                    formViewModel.resetForm()
                    showAddForm = true
                }
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
        ) {
            // Top App Bar
            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.surface,
                tonalElevation = 1.dp
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Analytics",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    ThemeToggleButton(
                        currentTheme = themeMode,
                        onThemeSelected = onThemeModeSelected
                    )
                }
            }

            if (uiState.isLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(300.dp),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
                }
            } else {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    // 1. Hero Consistency Card
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(18.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(18.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "Your Consistency",
                                    style = MaterialTheme.typography.titleSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = "${uiState.consistency30Days}%",
                                    style = MaterialTheme.typography.headlineLarge,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                
                                val delta = uiState.consistencyDelta30Days
                                val isPositiveOrZero = delta >= 0
                                val deltaColor = if (isPositiveOrZero) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.error
                                val deltaIcon = if (isPositiveOrZero) Icons.AutoMirrored.Filled.TrendingUp else Icons.AutoMirrored.Filled.TrendingDown
                                val deltaText = if (isPositiveOrZero) "+$delta% vs last 30 days" else "$delta% vs last 30 days"

                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        imageVector = deltaIcon,
                                        contentDescription = null,
                                        tint = deltaColor,
                                        modifier = Modifier.size(14.dp)
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = deltaText,
                                        style = MaterialTheme.typography.labelSmall,
                                        fontWeight = FontWeight.SemiBold,
                                        color = deltaColor
                                    )
                                }
                            }

                            // Circular Progress Indicator Ring
                            val consistencyFraction = (uiState.consistency30Days.toFloat() / 100f).coerceIn(0f, 1f)
                            val animatedProgress by animateFloatAsState(
                                targetValue = consistencyFraction,
                                animationSpec = tween(durationMillis = 600),
                                label = "consistency_ring"
                            )

                            Box(
                                modifier = Modifier.size(80.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                val trackColor = MaterialTheme.colorScheme.surfaceVariant
                                val primaryColor = MaterialTheme.colorScheme.primary

                                Canvas(modifier = Modifier.size(76.dp)) {
                                    val strokeWidth = 8.dp.toPx()
                                    drawCircle(
                                        color = trackColor,
                                        style = Stroke(width = strokeWidth)
                                    )
                                    drawArc(
                                        color = primaryColor,
                                        startAngle = -90f,
                                        sweepAngle = animatedProgress * 360f,
                                        useCenter = false,
                                        style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                                    )
                                }
                            }
                        }
                    }

                    // 2. Secondary Metrics Row: Best Streak, Completed, Focus Time
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        MetricCardItem(
                            icon = Icons.Default.LocalFireDepartment,
                            iconTint = MaterialTheme.colorScheme.tertiary,
                            value = "${uiState.bestStreakRecord}",
                            label = "Best Streak",
                            modifier = Modifier.weight(1f)
                        )
                        MetricCardItem(
                            icon = Icons.Default.Check,
                            iconTint = MaterialTheme.colorScheme.primary,
                            value = "${uiState.completedTodayCount}",
                            label = "Completed",
                            modifier = Modifier.weight(1f)
                        )
                        MetricCardItem(
                            icon = Icons.Default.Schedule,
                            iconTint = MaterialTheme.colorScheme.tertiary,
                            value = "18h 25m",
                            label = "Focus Time",
                            modifier = Modifier.weight(1f)
                        )
                    }

                    // 3. Top Habits (Ranked Performance)
                    if (uiState.leaderboard.isNotEmpty()) {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
                            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f))
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                verticalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                Text(
                                    text = "Top Habits (30 Days)",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )

                                uiState.leaderboard.forEachIndexed { index, item ->
                                    val habitColor = ColorUtils.parseHexColor(item.habit.color)
                                    val icon = HabitIconRegistry.getIcon(item.habit.icon)
                                    val progressFraction = if (item.bestStreak > 0) {
                                        (item.currentStreak.toFloat() / item.bestStreak.toFloat()).coerceIn(0.1f, 1f)
                                    } else 0.5f

                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clip(RoundedCornerShape(10.dp))
                                            .clickable { onNavigateToDetail(item.habit.id) }
                                            .padding(vertical = 4.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            text = "${index + 1}",
                                            style = MaterialTheme.typography.labelLarge,
                                            fontWeight = FontWeight.Bold,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                                            modifier = Modifier.width(20.dp)
                                        )

                                        Surface(
                                            modifier = Modifier.size(36.dp),
                                            shape = RoundedCornerShape(8.dp),
                                            color = habitColor.copy(alpha = 0.15f)
                                        ) {
                                            Box(contentAlignment = Alignment.Center) {
                                                Icon(
                                                    imageVector = icon,
                                                    contentDescription = null,
                                                    tint = habitColor,
                                                    modifier = Modifier.size(18.dp)
                                                )
                                            }
                                        }

                                        Spacer(modifier = Modifier.width(10.dp))

                                        Column(modifier = Modifier.weight(1f)) {
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.SpaceBetween
                                            ) {
                                                Text(
                                                    text = item.habit.title,
                                                    style = MaterialTheme.typography.bodyMedium,
                                                    fontWeight = FontWeight.SemiBold,
                                                    maxLines = 1,
                                                    overflow = TextOverflow.Ellipsis
                                                )
                                                Text(
                                                    text = "${item.currentStreak} ${item.unitLabel}",
                                                    style = MaterialTheme.typography.labelSmall,
                                                    fontWeight = FontWeight.Bold,
                                                    color = MaterialTheme.colorScheme.primary
                                                )
                                            }

                                            Spacer(modifier = Modifier.height(4.dp))

                                            LinearProgressIndicator(
                                                progress = { progressFraction },
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .height(4.dp)
                                                    .clip(RoundedCornerShape(2.dp)),
                                                color = habitColor,
                                                trackColor = MaterialTheme.colorScheme.surfaceVariant
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 4. Adherence Trend Section
                    AdherenceAreaChart(
                        dataPoints = uiState.trendDataPoints,
                        selectedRange = uiState.trendRange,
                        onRangeSelected = viewModel::setTrendRange,
                        modifier = Modifier.fillMaxWidth()
                    )

                    // 5. Monthly Activity Heatmap
                    MonthlyHeatmapGrid(
                        month = uiState.heatmapMonth,
                        dayDataMap = uiState.heatmapData,
                        onPreviousMonth = {
                            HapticsHelper.performLightHaptic(haptic)
                            viewModel.previousHeatmapMonth()
                        },
                        onNextMonth = {
                            HapticsHelper.performLightHaptic(haptic)
                            viewModel.nextHeatmapMonth()
                        }
                    )

                    Spacer(modifier = Modifier.height(16.dp))
                }
            }
        }
    }

    if (showAddForm) {
        HabitFormBottomSheet(
            viewModel = formViewModel,
            onDismiss = { showAddForm = false }
        )
    }
}

@Composable
private fun MetricCardItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    iconTint: Color,
    value: String,
    label: String,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f))
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
        ) {
            Surface(
                modifier = Modifier.size(32.dp),
                shape = CircleShape,
                color = iconTint.copy(alpha = 0.15f)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = iconTint,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = value,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
