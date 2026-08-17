package com.productivity.habits.ui.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.InsertChart
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.EmojiEvents
import androidx.compose.material.icons.outlined.InsertChart
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.productivity.habits.ui.common.HapticsHelper

enum class BottomNavDestination(
    val route: String,
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
) {
    TODAY(Screen.Daily.route, "Today", Icons.Filled.CheckCircle, Icons.Outlined.CheckCircle),
    WEEK(Screen.WeekMatrix.route, "Week", Icons.Filled.CalendarMonth, Icons.Outlined.CalendarMonth),
    ANALYTICS(Screen.Analytics.route, "Analytics", Icons.Filled.InsertChart, Icons.Outlined.InsertChart),
    MASTERY(Screen.Badges.route, "Mastery", Icons.Filled.EmojiEvents, Icons.Outlined.EmojiEvents)
}

@Composable
fun HabitBottomNavigation(
    currentRoute: String?,
    onNavigate: (String) -> Unit,
    onAddHabitClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val haptic = LocalHapticFeedback.current

    Surface(
        modifier = modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 4.dp,
        shadowElevation = 8.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(64.dp)
                .padding(horizontal = 8.dp),
            horizontalArrangement = Arrangement.SpaceAround,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // 1. Today
            NavIconItem(
                destination = BottomNavDestination.TODAY,
                isSelected = currentRoute == BottomNavDestination.TODAY.route,
                onClick = {
                    HapticsHelper.performLightHaptic(haptic)
                    onNavigate(BottomNavDestination.TODAY.route)
                },
                modifier = Modifier.weight(1f)
            )

            // 2. Week Matrix
            NavIconItem(
                destination = BottomNavDestination.WEEK,
                isSelected = currentRoute == BottomNavDestination.WEEK.route,
                onClick = {
                    HapticsHelper.performLightHaptic(haptic)
                    onNavigate(BottomNavDestination.WEEK.route)
                },
                modifier = Modifier.weight(1f)
            )

            // 3. Center Elevated Plus (+) Button
            Box(
                modifier = Modifier
                    .weight(1.2f)
                    .height(64.dp),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary)
                        .clickable {
                            HapticsHelper.performLightHaptic(haptic)
                            onAddHabitClick()
                        },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Add Habit",
                        tint = MaterialTheme.colorScheme.onPrimary,
                        modifier = Modifier.size(26.dp)
                    )
                }
            }

            // 4. Analytics
            NavIconItem(
                destination = BottomNavDestination.ANALYTICS,
                isSelected = currentRoute == BottomNavDestination.ANALYTICS.route,
                onClick = {
                    HapticsHelper.performLightHaptic(haptic)
                    onNavigate(BottomNavDestination.ANALYTICS.route)
                },
                modifier = Modifier.weight(1f)
            )

            // 5. Mastery & Badges
            NavIconItem(
                destination = BottomNavDestination.MASTERY,
                isSelected = currentRoute == BottomNavDestination.MASTERY.route,
                onClick = {
                    HapticsHelper.performLightHaptic(haptic)
                    onNavigate(BottomNavDestination.MASTERY.route)
                },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun NavIconItem(
    destination: BottomNavDestination,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(vertical = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = if (isSelected) destination.selectedIcon else destination.unselectedIcon,
            contentDescription = destination.label,
            tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
            modifier = Modifier.size(22.dp)
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = destination.label,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
        )
    }
}
