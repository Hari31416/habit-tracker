package com.productivity.habits.domain.gamification

enum class PlayerTitle(
    val displayName: String,
    val minLevel: Int,
    val description: String
) {
    NOVICE("Novice", 1, "Beginning the journey of habit mastery"),
    APPRENTICE("Apprentice", 5, "Building steady discipline and consistency"),
    PATHFINDER("Pathfinder", 10, "Navigating advanced routines and long streaks"),
    GRANDMASTER("Grandmaster", 20, "A true master of personal growth and unbreakable habits");

    companion object {
        fun fromLevel(level: Int): PlayerTitle {
            return entries.filter { it.minLevel <= level }
                .maxByOrNull { it.minLevel } ?: NOVICE
        }

        fun nextTitle(level: Int): PlayerTitle? {
            val current = fromLevel(level)
            val all = entries.sortedBy { it.minLevel }
            val currentIndex = all.indexOf(current)
            return if (currentIndex in 0 until all.size - 1) all[currentIndex + 1] else null
        }
    }
}
