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

@Composable
fun HabitNavGraph(
    modifier: Modifier = Modifier,
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
            PlaceholderScreen(
                title = "Week Matrix",
                onBack = { navController.popBackStack() }
            )
        }

        composable(route = Screen.Analytics.route) {
            PlaceholderScreen(
                title = "Analytics",
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.Detail.route,
            arguments = Screen.Detail.arguments,
            deepLinks = Screen.Detail.deepLinks
        ) { backStackEntry ->
            val habitId = backStackEntry.arguments?.getString(Screen.Detail.HABIT_ID_ARG) ?: ""
            PlaceholderScreen(
                title = "Habit Detail ($habitId)",
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
