package com.productivity.habits.ui.common

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsRun
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material.icons.filled.LocalCafe
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.SentimentSatisfied
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.Work
import androidx.compose.ui.graphics.vector.ImageVector

data class HabitIconItem(
    val key: String,
    val label: String,
    val icon: ImageVector
)

object HabitIconRegistry {

    private val ICONS_MAP: Map<String, ImageVector> = mapOf(
        // Default category icons
        "activity" to Icons.AutoMirrored.Filled.DirectionsRun,
        "brain" to Icons.Default.Psychology,
        "book-open" to Icons.AutoMirrored.Filled.MenuBook,
        "book" to Icons.Default.Book,
        "zap" to Icons.Default.FlashOn,
        "heart" to Icons.Default.Favorite,
        "clock" to Icons.Default.Schedule,

        // Common habit icons
        "check" to Icons.Default.CheckCircle,
        "star" to Icons.Default.Star,
        "target" to Icons.Default.TrackChanges,
        "droplet" to Icons.Default.WaterDrop,
        "water" to Icons.Default.WaterDrop,
        "footprints" to Icons.AutoMirrored.Filled.DirectionsWalk,
        "walk" to Icons.AutoMirrored.Filled.DirectionsWalk,
        "run" to Icons.AutoMirrored.Filled.DirectionsRun,
        "dumbbell" to Icons.Default.FitnessCenter,
        "fitness" to Icons.Default.FitnessCenter,
        "moon" to Icons.Default.Bedtime,
        "sun" to Icons.Default.WbSunny,
        "coffee" to Icons.Default.LocalCafe,
        "code" to Icons.Default.Code,
        "sparkles" to Icons.Default.AutoAwesome,
        "smile" to Icons.Default.SentimentSatisfied,
        "music" to Icons.Default.MusicNote,
        "edit" to Icons.Default.Edit,
        "work" to Icons.Default.Work
    )

    val AVAILABLE_ICONS: List<HabitIconItem> = listOf(
        HabitIconItem("activity", "Activity", Icons.AutoMirrored.Filled.DirectionsRun),
        HabitIconItem("brain", "Mindfulness", Icons.Default.Psychology),
        HabitIconItem("book-open", "Reading", Icons.AutoMirrored.Filled.MenuBook),
        HabitIconItem("zap", "Productivity", Icons.Default.FlashOn),
        HabitIconItem("heart", "Health / Heart", Icons.Default.Favorite),
        HabitIconItem("clock", "Routine / Time", Icons.Default.Schedule),
        HabitIconItem("droplet", "Hydration", Icons.Default.WaterDrop),
        HabitIconItem("dumbbell", "Fitness", Icons.Default.FitnessCenter),
        HabitIconItem("footprints", "Walking / Steps", Icons.AutoMirrored.Filled.DirectionsWalk),
        HabitIconItem("moon", "Sleep / Night", Icons.Default.Bedtime),
        HabitIconItem("sun", "Morning", Icons.Default.WbSunny),
        HabitIconItem("coffee", "Break / Focus", Icons.Default.LocalCafe),
        HabitIconItem("code", "Coding / Tech", Icons.Default.Code),
        HabitIconItem("target", "Target / Goals", Icons.Default.TrackChanges),
        HabitIconItem("sparkles", "Motivation", Icons.Default.AutoAwesome),
        HabitIconItem("star", "Star / Priority", Icons.Default.Star),
        HabitIconItem("music", "Music / Art", Icons.Default.MusicNote),
        HabitIconItem("smile", "Mood / Well-being", Icons.Default.SentimentSatisfied),
        HabitIconItem("edit", "Writing / Journal", Icons.Default.Edit),
        HabitIconItem("work", "Work / Projects", Icons.Default.Work)
    )

    fun getIcon(key: String?): ImageVector {
        if (key.isNullOrBlank()) return Icons.Default.CheckCircle
        val normalized = key.lowercase().trim()
        return ICONS_MAP[normalized] ?: Icons.Default.CheckCircle
    }
}
