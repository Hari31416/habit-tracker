package com.productivity.habits.ui.theme

import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color

// Light Theme Tokens (Matches productivity index.css :root)
val PrimaryLight = Color(0xFF0A7A64)              // hsl(168.2 84.8% 25.9%)
val OnPrimaryLight = Color(0xFFFFFFFF)
val PrimaryContainerLight = Color(0xFFDDF7F0)     // hsl(164 62% 91.8%)
val OnPrimaryContainerLight = Color(0xFF065243)   // hsl(168.2 86.4% 17.3%)

val SecondaryLight = Color(0xFFF1F5F9)            // hsl(210 40% 96.1%)
val OnSecondaryLight = Color(0xFF334155)          // hsl(215 25% 27%)
val SecondaryContainerLight = Color(0xFFE2E8F0)   // hsl(214.3 31.8% 91.4%)
val OnSecondaryContainerLight = Color(0xFF1E293B)

val TertiaryLight = Color(0xFFF59E0B)             // Amber / Warning: hsl(38 92% 50%)
val OnTertiaryLight = Color(0xFFFFFFFF)
val TertiaryContainerLight = Color(0xFFFEF3C7)
val OnTertiaryContainerLight = Color(0xFF78350F)

val ErrorLight = Color(0xFFEF4444)                // Destructive: hsl(0 84% 60%)
val OnErrorLight = Color(0xFFFFFFFF)
val ErrorContainerLight = Color(0xFFFEE2E2)
val OnErrorContainerLight = Color(0xFF991B1B)

val BackgroundLight = Color(0xFFF8FAFC)           // hsl(210 40% 98%)
val OnBackgroundLight = Color(0xFF0F172A)         // hsl(222.2 47.4% 11.2%)
val SurfaceLight = Color(0xFFFFFFFF)              // hsl(0 0% 100%)
val OnSurfaceLight = Color(0xFF0F172A)            // hsl(222.2 47.4% 11.2%)
val SurfaceVariantLight = Color(0xFFF1F5F9)       // hsl(210 40% 96.1%)
val OnSurfaceVariantLight = Color(0xFF475569)     // hsl(215.3 19.3% 34.5%)
val OutlineLight = Color(0xFFE2E8F0)              // hsl(214.3 31.8% 91.4%)
val OutlineVariantLight = Color(0xFFCBD5E1)       // slate-300

// Dark Theme Tokens (Matches productivity index.css .dark)
val PrimaryDark = Color(0xFF14B8A6)               // hsl(173.4 80.4% 40%)
val OnPrimaryDark = Color(0xFF0B1211)             // hsl(171.4 24.1% 5.7%)
val PrimaryContainerDark = Color(0xFF112C26)      // hsl(168 45% 12%)
val OnPrimaryContainerDark = Color(0xFF66DBBF)

val SecondaryDark = Color(0xFF172522)             // hsl(167.1 23.3% 11.8%)
val OnSecondaryDark = Color(0xFFBED0CC)           // hsl(165.9 16% 78%)
val SecondaryContainerDark = Color(0xFF263936)     // hsl(170.5 20% 18.6%)
val OnSecondaryContainerDark = Color(0xFFF1F5F4)

val TertiaryDark = Color(0xFFF59E0B)              // Amber / Warning: hsl(38 92% 50%)
val OnTertiaryDark = Color(0xFF451A03)
val TertiaryContainerDark = Color(0xFF78350F)
val OnTertiaryContainerDark = Color(0xFFFDE68A)

val ErrorDark = Color(0xFFEF4444)                 // Destructive: hsl(0 84% 60%)
val OnErrorDark = Color(0xFF450A0A)
val ErrorContainerDark = Color(0xFF7F1D1D)
val OnErrorContainerDark = Color(0xFFFCA5A5)

val BackgroundDark = Color(0xFF0B1211)            // hsl(171.4 24.1% 5.7%)
val OnBackgroundDark = Color(0xFFF1F5F4)          // hsl(165 14.3% 95.3%)
val SurfaceDark = Color(0xFF111C1A)               // Card: hsl(169.1 24.4% 8.8%)
val OnSurfaceDark = Color(0xFFF1F5F4)             // Card foreground: hsl(165 14.3% 95.3%)
val SurfaceVariantDark = Color(0xFF172522)        // Elevated surface: hsl(167.1 23.3% 11.8%)
val OnSurfaceVariantDark = Color(0xFF96ABA6)      // Muted foreground: hsl(168 12% 64%)
val OutlineDark = Color(0xFF263936)               // Border: hsl(170.5 20% 18.6%)
val OutlineVariantDark = Color(0xFF172522)

// Semantic Accent & Preset Habit Colors
val HabitColorEmerald = Color(0xFF10B981)
val HabitColorTeal = Color(0xFF0D9488)
val HabitColorCyanTeal = Color(0xFF14B8A6)
val HabitColorIndigo = Color(0xFF6366F1)
val HabitColorViolet = Color(0xFF8B5CF6)
val HabitColorAmber = Color(0xFFF59E0B)
val HabitColorCoral = Color(0xFFEF4444)
val HabitColorPink = Color(0xFFEC4899)
val HabitColorCyan = Color(0xFF06B6D4)

val HABIT_PRESET_COLORS = listOf(
    "#10B981", // Emerald
    "#0D9488", // Teal
    "#14B8A6", // Cyan Teal
    "#6366F1", // Indigo
    "#8B5CF6", // Violet
    "#F59E0B", // Amber
    "#EF4444", // Coral
    "#EC4899"  // Pink
)

// Material 3 Color Schemes
val LightColorScheme = lightColorScheme(
    primary = PrimaryLight,
    onPrimary = OnPrimaryLight,
    primaryContainer = PrimaryContainerLight,
    onPrimaryContainer = OnPrimaryContainerLight,
    secondary = SecondaryLight,
    onSecondary = OnSecondaryLight,
    secondaryContainer = SecondaryContainerLight,
    onSecondaryContainer = OnSecondaryContainerLight,
    tertiary = TertiaryLight,
    onTertiary = OnTertiaryLight,
    tertiaryContainer = TertiaryContainerLight,
    onTertiaryContainer = OnTertiaryContainerLight,
    error = ErrorLight,
    onError = OnErrorLight,
    errorContainer = ErrorContainerLight,
    onErrorContainer = OnErrorContainerLight,
    background = BackgroundLight,
    onBackground = OnBackgroundLight,
    surface = SurfaceLight,
    onSurface = OnSurfaceLight,
    surfaceVariant = SurfaceVariantLight,
    onSurfaceVariant = OnSurfaceVariantLight,
    outline = OutlineLight,
    outlineVariant = OutlineVariantLight
)

val DarkColorScheme = darkColorScheme(
    primary = PrimaryDark,
    onPrimary = OnPrimaryDark,
    primaryContainer = PrimaryContainerDark,
    onPrimaryContainer = OnPrimaryContainerDark,
    secondary = SecondaryDark,
    onSecondary = OnSecondaryDark,
    secondaryContainer = SecondaryContainerDark,
    onSecondaryContainer = OnSecondaryContainerDark,
    tertiary = TertiaryDark,
    onTertiary = OnTertiaryDark,
    tertiaryContainer = TertiaryContainerDark,
    onTertiaryContainer = OnTertiaryContainerDark,
    error = ErrorDark,
    onError = OnErrorDark,
    errorContainer = ErrorContainerDark,
    onErrorContainer = OnErrorContainerDark,
    background = BackgroundDark,
    onBackground = OnBackgroundDark,
    surface = SurfaceDark,
    onSurface = OnSurfaceDark,
    surfaceVariant = SurfaceVariantDark,
    onSurfaceVariant = OnSurfaceVariantDark,
    outline = OutlineDark,
    outlineVariant = OutlineVariantDark
)
