package com.productivity.habits.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.productivity.habits.ui.daily.DailyTrackerScreen

import com.productivity.habits.data.local.preferences.ThemeMode

@Composable
fun HabitNavGraph(
    modifier: Modifier = Modifier,
    themeMode: ThemeMode = ThemeMode.SYSTEM,
    onThemeModeSelected: (ThemeMode) -> Unit = {},
    navController: NavHostController = rememberNavController(),
    startDestination: String = Screen.Daily.route
) {
    NavHost(
        navController = navController,
        startDestination = startDestination,
        modifier = modifier
    ) {
        composable(route = Screen.Daily.route) {
            DailyTrackerScreen(
                themeMode = themeMode,
                onThemeModeSelected = onThemeModeSelected,
                onNavigateToDetail = { habitId ->
                    navController.navigate(Screen.Detail.createRoute(habitId))
                },
                onNavigateToMatrix = {
                    navController.navigate(Screen.WeekMatrix.route)
                },
                onNavigateToAnalytics = {
                    navController.navigate(Screen.Analytics.route)
                }
            )
        }

        composable(route = Screen.WeekMatrix.route) {
            com.productivity.habits.ui.matrix.HabitWeekMatrixScreen(
                themeMode = themeMode,
                onThemeModeSelected = onThemeModeSelected,
                onNavigateToDaily = {
                    navController.navigate(Screen.Daily.route) {
                        popUpTo(Screen.Daily.route) { inclusive = true }
                    }
                },
                onNavigateToAnalytics = {
                    navController.navigate(Screen.Analytics.route) {
                        popUpTo(Screen.Daily.route)
                    }
                },
                onNavigateToDetail = { habitId ->
                    navController.navigate(Screen.Detail.createRoute(habitId))
                }
            )
        }

        composable(route = Screen.Analytics.route) {
            com.productivity.habits.ui.analytics.HabitAnalyticsScreen(
                themeMode = themeMode,
                onThemeModeSelected = onThemeModeSelected,
                onNavigateToDaily = {
                    navController.navigate(Screen.Daily.route) {
                        popUpTo(Screen.Daily.route) { inclusive = true }
                    }
                },
                onNavigateToMatrix = {
                    navController.navigate(Screen.WeekMatrix.route) {
                        popUpTo(Screen.Daily.route)
                    }
                },
                onNavigateToDetail = { habitId ->
                    navController.navigate(Screen.Detail.createRoute(habitId))
                }
            )
        }

        composable(
            route = Screen.Detail.route,
            arguments = Screen.Detail.arguments,
            deepLinks = Screen.Detail.deepLinks
        ) {
            com.productivity.habits.ui.detail.HabitDetailScreen(
                onBack = { navController.popBackStack() }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlaceholderScreen(
    title: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text(title) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "$title Screen (Phase 3/4)",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
