package com.productivity.habits.ui.theme

import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color

// Primary Brand Colors (Teal / Emerald palette)
val EmeraldPrimary = Color(0xFF0A7A64)
val EmeraldOnPrimary = Color(0xFFFFFFFF)
val EmeraldPrimaryContainer = Color(0xFFB4F2E1)
val EmeraldOnPrimaryContainer = Color(0xFF002019)

val EmeraldDarkPrimary = Color(0xFF66DBBF)
val EmeraldDarkOnPrimary = Color(0xFF00382E)
val EmeraldDarkPrimaryContainer = Color(0xFF005143)
val EmeraldDarkOnPrimaryContainer = Color(0xFFB4F2E1)

// Secondary Colors (Slate / Indigo)
val SlateSecondary = Color(0xFF4A635D)
val SlateOnSecondary = Color(0xFFFFFFFF)
val SlateSecondaryContainer = Color(0xFFCCE8DF)
val SlateOnSecondaryContainer = Color(0xFF06201B)

val SlateDarkSecondary = Color(0xFFB0CCC3)
val SlateDarkOnSecondary = Color(0xFF1B352F)
val SlateDarkSecondaryContainer = Color(0xFF324C45)
val SlateDarkOnSecondaryContainer = Color(0xFFCCE8DF)

// Tertiary Colors (Amber / Gold Accent)
val AmberTertiary = Color(0xFF705D00)
val AmberOnTertiary = Color(0xFFFFFFFF)
val AmberTertiaryContainer = Color(0xFFFFE16F)
val AmberOnTertiaryContainer = Color(0xFF221B00)

val AmberDarkTertiary = Color(0xFFE5C44B)
val AmberDarkOnTertiary = Color(0xFF3B3000)
val AmberDarkTertiaryContainer = Color(0xFF554600)
val AmberDarkOnTertiaryContainer = Color(0xFFFFE16F)

// Background & Surface - Light
val LightBackground = Color(0xFFF6FAF7)
val LightOnBackground = Color(0xFF171D1B)
val LightSurface = Color(0xFFFFFFFF)
val LightOnSurface = Color(0xFF171D1B)
val LightSurfaceVariant = Color(0xFFDBE5E0)
val LightOnSurfaceVariant = Color(0xFF3F4945)
val LightOutline = Color(0xFF6F7975)
val LightOutlineVariant = Color(0xFFBFC9C4)

// Background & Surface - Dark
val DarkBackground = Color(0xFF0E1513)
val DarkOnBackground = Color(0xFFDEE4E1)
val DarkSurface = Color(0xFF131B19)
val DarkOnSurface = Color(0xFFDEE4E1)
val DarkSurfaceVariant = Color(0xFF3F4945)
val DarkOnSurfaceVariant = Color(0xFFBFC9C4)
val DarkOutline = Color(0xFF89938F)
val DarkOutlineVariant = Color(0xFF3F4945)

// 8 Habit Preset Accent Colors
val HabitColorEmerald = Color(0xFF10B981)
val HabitColorTeal = Color(0xFF0D9488)
val HabitColorIndigo = Color(0xFF6366F1)
val HabitColorViolet = Color(0xFF8B5CF6)
val HabitColorAmber = Color(0xFFF59E0B)
val HabitColorRose = Color(0xFFF43F5E)
val HabitColorPink = Color(0xFFEC4899)
val HabitColorCyan = Color(0xFF06B6D4)

val HABIT_PRESET_COLORS = listOf(
    "#10B981", // Emerald
    "#0D9488", // Teal
    "#6366F1", // Indigo
    "#8B5CF6", // Violet
    "#F59E0B", // Amber
    "#F43F5E", // Rose
    "#EC4899", // Pink
    "#06B6D4"  // Cyan
)

val LightColorScheme = lightColorScheme(
    primary = EmeraldPrimary,
    onPrimary = EmeraldOnPrimary,
    primaryContainer = EmeraldPrimaryContainer,
    onPrimaryContainer = EmeraldOnPrimaryContainer,
    secondary = SlateSecondary,
    onSecondary = SlateOnSecondary,
    secondaryContainer = SlateSecondaryContainer,
    onSecondaryContainer = SlateOnSecondaryContainer,
    tertiary = AmberTertiary,
    onTertiary = AmberOnTertiary,
    tertiaryContainer = AmberTertiaryContainer,
    onTertiaryContainer = AmberOnTertiaryContainer,
    background = LightBackground,
    onBackground = LightOnBackground,
    surface = LightSurface,
    onSurface = LightOnSurface,
    surfaceVariant = LightSurfaceVariant,
    onSurfaceVariant = LightOnSurfaceVariant,
    outline = LightOutline,
    outlineVariant = LightOutlineVariant
)

val DarkColorScheme = darkColorScheme(
    primary = EmeraldDarkPrimary,
    onPrimary = EmeraldDarkOnPrimary,
    primaryContainer = EmeraldDarkPrimaryContainer,
    onPrimaryContainer = EmeraldDarkOnPrimaryContainer,
    secondary = SlateDarkSecondary,
    onSecondary = SlateDarkOnSecondary,
    secondaryContainer = SlateDarkSecondaryContainer,
    onSecondaryContainer = SlateDarkOnSecondaryContainer,
    tertiary = AmberDarkTertiary,
    onTertiary = AmberDarkOnTertiary,
    tertiaryContainer = AmberDarkTertiaryContainer,
    onTertiaryContainer = AmberDarkOnTertiaryContainer,
    background = DarkBackground,
    onBackground = DarkOnBackground,
    surface = DarkSurface,
    onSurface = DarkOnSurface,
    surfaceVariant = DarkSurfaceVariant,
    onSurfaceVariant = DarkOnSurfaceVariant,
    outline = DarkOutline,
    outlineVariant = DarkOutlineVariant
)
