package com.productivity.habits.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.productivity.habits.data.local.preferences.ThemeMode
import com.productivity.habits.data.local.preferences.ThemePreferences
import com.productivity.habits.ui.analytics.HabitAnalyticsScreen
import com.productivity.habits.ui.daily.DailyTrackerScreen
import com.productivity.habits.ui.detail.FocusTimerScreen
import com.productivity.habits.ui.detail.HabitDetailScreen
import com.productivity.habits.ui.gamification.BadgesShowcaseScreen
import com.productivity.habits.ui.matrix.HabitWeekMatrixScreen

@Composable
fun HabitNavGraph(
    modifier: Modifier = Modifier,
    themeMode: ThemeMode = ThemeMode.SYSTEM,
    onThemeModeSelected: (ThemeMode) -> Unit = {},
    themePreferences: ThemePreferences? = null,
    navController: NavHostController = rememberNavController(),
    startDestination: String = Screen.Daily.route
) {
    fun navigateToTab(route: String) {
        navController.navigate(route) {
            popUpTo(navController.graph.findStartDestination().id) {
                saveState = true
            }
            launchSingleTop = true
            restoreState = true
        }
    }

    NavHost(
        navController = navController,
        startDestination = startDestination,
        modifier = modifier
    ) {
        composable(
            route = Screen.Daily.route,
            deepLinks = Screen.Daily.deepLinks
        ) {
            DailyTrackerScreen(
                themeMode = themeMode,
                onThemeModeSelected = onThemeModeSelected,
                themePreferences = themePreferences,
                onNavigateToDetail = { habitId ->
                    navController.navigate(Screen.Detail.createRoute(habitId))
                },
                onNavigateToMatrix = {
                    navigateToTab(Screen.WeekMatrix.route)
                },
                onNavigateToAnalytics = {
                    navigateToTab(Screen.Analytics.route)
                },
                onNavigateToBadges = {
                    navigateToTab(Screen.Badges.route)
                }
            )
        }

        composable(
            route = Screen.WeekMatrix.route,
            deepLinks = Screen.WeekMatrix.deepLinks
        ) {
            HabitWeekMatrixScreen(
                themeMode = themeMode,
                onThemeModeSelected = onThemeModeSelected,
                onNavigateToDaily = {
                    navigateToTab(Screen.Daily.route)
                },
                onNavigateToAnalytics = {
                    navigateToTab(Screen.Analytics.route)
                },
                onNavigateToDetail = { habitId ->
                    navController.navigate(Screen.Detail.createRoute(habitId))
                },
                onNavigateToBadges = {
                    navigateToTab(Screen.Badges.route)
                }
            )
        }

        composable(
            route = Screen.Analytics.route,
            deepLinks = Screen.Analytics.deepLinks
        ) {
            HabitAnalyticsScreen(
                themeMode = themeMode,
                onThemeModeSelected = onThemeModeSelected,
                onNavigateToDaily = {
                    navigateToTab(Screen.Daily.route)
                },
                onNavigateToMatrix = {
                    navigateToTab(Screen.WeekMatrix.route)
                },
                onNavigateToDetail = { habitId ->
                    navController.navigate(Screen.Detail.createRoute(habitId))
                },
                onNavigateToBadges = {
                    navigateToTab(Screen.Badges.route)
                }
            )
        }

        composable(
            route = Screen.Badges.route,
            deepLinks = Screen.Badges.deepLinks
        ) {
            BadgesShowcaseScreen(
                themeMode = themeMode,
                onThemeModeSelected = onThemeModeSelected,
                onNavigateToDaily = {
                    navigateToTab(Screen.Daily.route)
                },
                onNavigateToMatrix = {
                    navigateToTab(Screen.WeekMatrix.route)
                },
                onNavigateToAnalytics = {
                    navigateToTab(Screen.Analytics.route)
                }
            )
        }

        composable(
            route = Screen.Detail.route,
            arguments = Screen.Detail.arguments,
            deepLinks = Screen.Detail.deepLinks
        ) {
            HabitDetailScreen(
                onBack = { navController.popBackStack() },
                onNavigateToFocusScreen = { habitId ->
                    navController.navigate(Screen.FocusTimer.createRoute(habitId))
                },
                themePreferences = themePreferences ?: return@composable
            )
        }

        composable(
            route = Screen.FocusTimer.route,
            arguments = Screen.FocusTimer.arguments
        ) { backStackEntry ->
            val habitId = backStackEntry.arguments?.getString(Screen.FocusTimer.HABIT_ID_ARG) ?: return@composable
            FocusTimerScreen(
                habitId = habitId,
                themePreferences = themePreferences ?: return@composable,
                onBack = { navController.popBackStack() }
            )
        }
    }
}
