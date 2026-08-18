package com.productivity.habits.ui.navigation

import androidx.navigation.NamedNavArgument
import androidx.navigation.NavDeepLink
import androidx.navigation.NavType
import androidx.navigation.navArgument
import androidx.navigation.navDeepLink

sealed class Screen(val route: String) {
    data object Daily : Screen("daily") {
        val deepLinks: List<NavDeepLink> = listOf(
            navDeepLink { uriPattern = "app://habits/daily" }
        )
    }

    data object WeekMatrix : Screen("matrix") {
        val deepLinks: List<NavDeepLink> = listOf(
            navDeepLink { uriPattern = "app://habits/matrix" }
        )
    }

    data object Analytics : Screen("analytics") {
        val deepLinks: List<NavDeepLink> = listOf(
            navDeepLink { uriPattern = "app://habits/analytics" }
        )
    }

    data object Detail : Screen("detail/{habitId}") {
        const val HABIT_ID_ARG = "habitId"
        val routeWithArgs = "detail/{$HABIT_ID_ARG}"
        fun createRoute(habitId: String) = "detail/$habitId"

        val arguments: List<NamedNavArgument> = listOf(
            navArgument(HABIT_ID_ARG) { type = NavType.StringType }
        )

        val deepLinks: List<NavDeepLink> = listOf(
            navDeepLink { uriPattern = "app://habits/detail/{$HABIT_ID_ARG}" }
        )
    }

    data object Badges : Screen("badges") {
        val deepLinks: List<NavDeepLink> = listOf(
            navDeepLink { uriPattern = "app://habits/badges" }
        )
    }

    data object FocusTimer : Screen("focus_timer/{habitId}") {
        const val HABIT_ID_ARG = "habitId"
        fun createRoute(habitId: String) = "focus_timer/$habitId"

        val arguments: List<NamedNavArgument> = listOf(
            navArgument(HABIT_ID_ARG) { type = NavType.StringType }
        )
    }

    data object AddHabit : Screen("add_habit")

    data object EditHabit : Screen("edit_habit/{habitId}") {
        const val HABIT_ID_ARG = "habitId"
        fun createRoute(habitId: String) = "edit_habit/$habitId"

        val arguments: List<NamedNavArgument> = listOf(
            navArgument(HABIT_ID_ARG) { type = NavType.StringType }
        )
    }
}
