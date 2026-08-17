package com.productivity.habits.ui.navigation

import androidx.navigation.NamedNavArgument
import androidx.navigation.NavDeepLink
import androidx.navigation.NavType
import androidx.navigation.navArgument
import androidx.navigation.navDeepLink

sealed class Screen(val route: String) {
    data object Daily : Screen("daily")
    data object WeekMatrix : Screen("matrix")
    data object Analytics : Screen("analytics")
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
    data object AddHabit : Screen("add_habit")
    data object EditHabit : Screen("edit_habit/{habitId}") {
        const val HABIT_ID_ARG = "habitId"
        fun createRoute(habitId: String) = "edit_habit/$habitId"

        val arguments: List<NamedNavArgument> = listOf(
            navArgument(HABIT_ID_ARG) { type = NavType.StringType }
        )
    }
}
