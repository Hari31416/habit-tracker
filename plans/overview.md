# Standalone Native Android Habit Tracker Specification

## Executive Summary

This document specifies the technical architecture, UI/UX flows, data models, business logic algorithms, and native Android capabilities required to build a dedicated, standalone native Android Habit Tracker application.

The goal is to translate and expand upon all habit tracking capabilities from the existing TypeScript/React productivity suite into a modern, native Android architecture using Kotlin, Jetpack Compose, Material 3, Room, Kotlin Coroutines/Flow, WorkManager, and Jetpack Glance.

## Architecture and Technology Stack

The native Android application follows the official Android Clean Architecture guidelines with reactive unidirectional data flow (MVI / MVVM).

### Core Stack Components

- **Language:** Kotlin
- **UI Toolkit:** Jetpack Compose with Material 3 Design System
- **State Management:** Jetpack ViewModel with `StateFlow` and `SharedFlow`
- **Dependency Injection:** Hilt / Dagger
- **Local Persistence:** Room Database with Kotlin Coroutines and Flow streaming
- **Date and Time:** `java.time` (ThreeTenABP / Java 8+ API desugaring)
- **Background Tasks and Scheduling:** `AlarmManager` for precise reminder alarms; `WorkManager` for midnight day-rollover, inexact reminder fallback, and notification/widget maintenance
- **Home Screen Widgets:** Jetpack Glance (AppWidget)
- **Charts and Visualizations:** Vico (Compose) — locked choice; do not use MPAndroidChart
- **Celebratory Effects:** System haptics only (no Konfetti / particle libraries)
- **Icons:** String keys stored on habits (Lucide-style names) resolved at runtime via `HabitIconRegistry` to Material Icons / app drawables

## Data Models and Room Schema

### Habit Entity

Represents the core configuration of a user habit.

```kotlin
package com.productivity.habits.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.productivity.habits.data.local.converters.HabitConverters
import java.time.Instant

enum class HabitFrequencyType {
    DAILY,
    WEEKLY,
    CUSTOM_DAYS,
    SUBDAY_INTERVAL,
    TIMES_PER_DAY
}

enum class HabitTargetType {
    BOOLEAN,
    NUMERIC,
    TIMER
}

data class TimeWindow(
    val startTime: String, // HH:mm format (e.g., "08:00")
    val endTime: String    // HH:mm format (e.g., "20:00")
)

@Entity(tableName = "habits")
@TypeConverters(HabitConverters::class)
data class HabitEntity(
    @PrimaryKey val id: String,
    val title: String,
    val description: String? = null,
    val color: String, // Hex color code (e.g., "#0A7A64")
    val icon: String? = null, // Lucide icon identifier name
    val categoryId: String? = null,
    val frequencyType: HabitFrequencyType,
    val targetDaysOfWeek: List<Int>? = null, // 0 = Sunday, 1 = Monday, ... 6 = Saturday
    val targetCountPerWeek: Int? = null,
    val intervalHours: Int? = null,
    val timesPerDay: Int? = null,
    val timeWindow: TimeWindow? = null,
    val targetType: HabitTargetType,
    val targetValue: Double? = null, // Numeric goal (e.g., 8 glasses) or Timer target in minutes (e.g., 25 mins)
    val unit: String? = null, // e.g., "glasses", "steps", "pages", "ml", "mins"
    val pinned: Boolean = false,
    val reminderTimes: List<String> = emptyList(), // List of "HH:mm" strings
    val motivationNotes: String? = null,
    val archived: Boolean = false,
    val createdAt: Instant,
    val updatedAt: Instant
)
```

### Habit Log Entity

Records an individual execution, check-in, or session for a habit on a specific date.

```kotlin
package com.productivity.habits.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.time.Instant

@Entity(
    tableName = "habit_logs",
    foreignKeys = [
        ForeignKey(
            entity = HabitEntity::class,
            parentColumns = ["id"],
            childColumns = ["habitId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["habitId"]),
        Index(value = ["date"]),
        Index(value = ["habitId", "date"])
    ]
)
data class HabitLogEntity(
    @PrimaryKey val id: String,
    val habitId: String,
    val date: String, // ISO Date format "yyyy-MM-dd"
    val timestamp: Instant,
    val intervalIndex: Int? = null, // For subday interval or times-per-day slot index (0, 1, 2...)
    val completed: Boolean,
    val value: Double? = null, // Recorded numeric value or minutes
    val durationSeconds: Long? = null, // Elapsed duration in seconds for timer habits
    val note: String? = null,
    val createdAt: Instant,
    val updatedAt: Instant
)
```

### Habit Category Entity

Categorization metadata with distinct theme colors and icons.

```kotlin
package com.productivity.habits.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "habit_categories")
data class HabitCategoryEntity(
    @PrimaryKey val id: String,
    val name: String,
    val color: String,
    val icon: String? = null
)
```

### Default Preset Categories

- **Health and Fitness:** `#10b981` (Activity icon)
- **Mindfulness:** `#8b5cf6` (Brain icon)
- **Learning:** `#3b82f6` (BookOpen icon)
- **Productivity:** `#f59e0b` (Zap icon)
- **Personal:** `#ec4899` (Heart icon)
- **Routine:** `#6366f1` (Clock icon)

## Core Business Logic and Algorithms

### Streak and Adherence Calculation

The streak engine calculates current consecutive streaks, best streaks, and rolling 30-day consistency rates while accounting for custom day scheduling and weekly targets.

#### WEEKLY frequency rules (canonical)

- Calendar week is **ISO Monday–Sunday**.
- A week is **met** when the number of **distinct completed days** in that week is `>= targetCountPerWeek` (default 1 if null).
- Users may log on **any day** of the week (`isHabitScheduledOnDate` returns `true` every day for `WEEKLY`).
- **Streak unit is weeks**, not days: `currentStreak` / `bestStreak` count consecutive met ISO weeks.
- **In-progress week preservation:** if the reference week is not yet over and the weekly target is not met, streak evaluation starts from the previous ISO week (same idea as “today still pending” for daily habits).
- **30-day adherence for WEEKLY:** among ISO weeks that intersect the last 30 days, `metWeeks / intersectingWeeks`.

```kotlin
data class StreakResult(
    val currentStreak: Int,
    val bestStreak: Int,
    val completionRate30Days: Int,
    val totalCompletions: Int // day-level completions; for WEEKLY also expose week meets via UI copy ("X weeks")
)

fun isoWeekStart(date: LocalDate): LocalDate =
    date.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))

fun isHabitScheduledOnDate(habit: HabitEntity, date: LocalDate): Boolean {
    return when (habit.frequencyType) {
        HabitFrequencyType.DAILY -> true
        HabitFrequencyType.CUSTOM_DAYS -> {
            val dayOfWeek = if (date.dayOfWeek.value == 7) 0 else date.dayOfWeek.value
            habit.targetDaysOfWeek?.contains(dayOfWeek) == true
        }
        HabitFrequencyType.WEEKLY -> true // loggable any day; week success uses targetCountPerWeek
        HabitFrequencyType.SUBDAY_INTERVAL, HabitFrequencyType.TIMES_PER_DAY -> true
    }
}

fun isHabitCompletedOnDate(habit: HabitEntity, logs: List<HabitLogEntity>): Boolean {
    if (logs.isEmpty()) return false

    return when (habit.targetType) {
        HabitTargetType.BOOLEAN -> {
            when (habit.frequencyType) {
                HabitFrequencyType.SUBDAY_INTERVAL, HabitFrequencyType.TIMES_PER_DAY -> {
                    val requiredSlots = habit.timesPerDay ?: habit.targetValue?.toInt() ?: 1
                    val completedSlots = logs.filter { it.completed }.mapNotNull { it.intervalIndex }.toSet().size
                    completedSlots >= requiredSlots
                }
                else -> logs.any { it.completed }
            }
        }
        HabitTargetType.NUMERIC -> {
            val target = habit.targetValue ?: 1.0
            val totalValue = logs.sumOf { log ->
                log.value ?: if (log.completed) target else 0.0
            }
            totalValue >= target
        }
        HabitTargetType.TIMER -> {
            val targetMinutes = habit.targetValue ?: 25.0
            val totalMinutes = logs.sumOf { log ->
                if (log.durationSeconds != null && log.durationSeconds > 0) {
                    (log.durationSeconds / 60.0)
                } else {
                    log.value ?: if (log.completed) targetMinutes else 0.0
                }
            }
            totalMinutes >= targetMinutes
        }
    }
}

fun isWeeklyTargetMet(
    habit: HabitEntity,
    logsByDate: Map<String, List<HabitLogEntity>>,
    weekStart: LocalDate,
    formatter: DateTimeFormatter
): Boolean {
    val required = habit.targetCountPerWeek ?: 1
    var completedDays = 0
    for (offset in 0 until 7) {
        val date = weekStart.plusDays(offset.toLong())
        val dayLogs = logsByDate[date.format(formatter)] ?: emptyList()
        if (isHabitCompletedOnDate(habit, dayLogs)) completedDays++
    }
    return completedDays >= required
}

fun calculateStreak(
    habit: HabitEntity,
    allLogs: List<HabitLogEntity>,
    referenceDate: LocalDate = LocalDate.now()
): StreakResult {
    val logsByDate = allLogs.filter { it.habitId == habit.id }.groupBy { it.date }
    val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    if (habit.frequencyType == HabitFrequencyType.WEEKLY) {
        return calculateWeeklyStreak(habit, logsByDate, referenceDate, formatter)
    }

    var currentStreak = 0
    var bestStreak = 0
    var tempStreak = 0
    var totalCompletions = 0

    var scheduledDaysIn30 = 0
    var completedDaysIn30 = 0

    for (i in 0 until 30) {
        val checkDate = referenceDate.minusDays(i.toLong())
        val dateStr = checkDate.format(formatter)
        val isScheduled = isHabitScheduledOnDate(habit, checkDate)

        if (isScheduled) {
            scheduledDaysIn30++
            val dayLogs = logsByDate[dateStr] ?: emptyList()
            if (isHabitCompletedOnDate(habit, dayLogs)) {
                completedDaysIn30++
            }
        }
    }

    val completionRate30Days = if (scheduledDaysIn30 > 0) {
        ((completedDaysIn30.toDouble() / scheduledDaysIn30.toDouble()) * 100).roundToInt()
    } else 0

    var checkDate = referenceDate
    var isCurrentStreakChain = true

    val refDateStr = referenceDate.format(formatter)
    val refLogs = logsByDate[refDateStr] ?: emptyList()
    val refCompleted = isHabitCompletedOnDate(habit, refLogs)

    if (!refCompleted && isHabitScheduledOnDate(habit, referenceDate)) {
        checkDate = referenceDate.minusDays(1)
    }

    for (i in 0 until 365) {
        val dateStr = checkDate.format(formatter)
        val isScheduled = isHabitScheduledOnDate(habit, checkDate)

        if (isScheduled) {
            val dayLogs = logsByDate[dateStr] ?: emptyList()
            val completed = isHabitCompletedOnDate(habit, dayLogs)

            if (completed) {
                totalCompletions++
                tempStreak++
                if (isCurrentStreakChain) {
                    currentStreak++
                }
                if (tempStreak > bestStreak) {
                    bestStreak = tempStreak
                }
            } else {
                isCurrentStreakChain = false
                tempStreak = 0
            }
        }
        checkDate = checkDate.minusDays(1)
    }

    return StreakResult(
        currentStreak = currentStreak,
        bestStreak = maxOf(bestStreak, currentStreak),
        completionRate30Days = completionRate30Days,
        totalCompletions = totalCompletions
    )
}

fun calculateWeeklyStreak(
    habit: HabitEntity,
    logsByDate: Map<String, List<HabitLogEntity>>,
    referenceDate: LocalDate,
    formatter: DateTimeFormatter
): StreakResult {
    var currentStreak = 0
    var bestStreak = 0
    var tempStreak = 0
    var totalCompletions = 0

    val windowStart = referenceDate.minusDays(29)
    val weeksInWindow = linkedSetOf<LocalDate>()
    var cursor = windowStart
    while (!cursor.isAfter(referenceDate)) {
        weeksInWindow.add(isoWeekStart(cursor))
        cursor = cursor.plusDays(1)
    }
    val metWeeksInWindow = weeksInWindow.count { isWeeklyTargetMet(habit, logsByDate, it, formatter) }
    val completionRate30Days = if (weeksInWindow.isNotEmpty()) {
        ((metWeeksInWindow.toDouble() / weeksInWindow.size.toDouble()) * 100).roundToInt()
    } else 0

    var weekStart = isoWeekStart(referenceDate)
    var isCurrentStreakChain = true
    val currentWeekMet = isWeeklyTargetMet(habit, logsByDate, weekStart, formatter)
    if (!currentWeekMet) {
        // In-progress week: do not break streak until the week ends unmet
        weekStart = weekStart.minusWeeks(1)
    }

    for (i in 0 until 52) {
        val met = isWeeklyTargetMet(habit, logsByDate, weekStart, formatter)
        // Count day-level completions inside the week for totalCompletions
        for (offset in 0 until 7) {
            val dayLogs = logsByDate[weekStart.plusDays(offset.toLong()).format(formatter)] ?: emptyList()
            if (isHabitCompletedOnDate(habit, dayLogs)) totalCompletions++
        }
        if (met) {
            tempStreak++
            if (isCurrentStreakChain) currentStreak++
            if (tempStreak > bestStreak) bestStreak = tempStreak
        } else {
            isCurrentStreakChain = false
            tempStreak = 0
        }
        weekStart = weekStart.minusWeeks(1)
    }

    return StreakResult(
        currentStreak = currentStreak,
        bestStreak = maxOf(bestStreak, currentStreak),
        completionRate30Days = completionRate30Days,
        totalCompletions = totalCompletions
    )
}
```

### Dynamic Stepper Engine

Calculates intelligent step sizes and quick-add chips based on unit type and target scale.

```kotlin
data class DynamicStepConfig(
    val primaryStep: Double,
    val quickAddValues: List<Double>
)

fun getDynamicStepConfig(targetValue: Double = 1.0, unit: String? = null): DynamicStepConfig {
    val normalizedUnit = (unit ?: "").lowercase().trim()
    val target = maxOf(1.0, targetValue)

    // Specialized unit rules
    if (normalizedUnit in listOf("ml", "milliliters", "l", "liters")) {
        return when {
            target >= 1000.0 -> DynamicStepConfig(primaryStep = 250.0, quickAddValues = listOf(250.0, 500.0, 1000.0))
            target >= 200.0 -> DynamicStepConfig(primaryStep = 50.0, quickAddValues = listOf(100.0, 250.0))
            else -> DynamicStepConfig(primaryStep = 10.0, quickAddValues = listOf(25.0, 50.0))
        }
    }

    if (normalizedUnit in listOf("steps", "step")) {
        return when {
            target >= 5000.0 -> DynamicStepConfig(primaryStep = 500.0, quickAddValues = listOf(1000.0, 2500.0, 5000.0))
            target >= 1000.0 -> DynamicStepConfig(primaryStep = 200.0, quickAddValues = listOf(500.0, 1000.0))
            else -> DynamicStepConfig(primaryStep = 50.0, quickAddValues = listOf(100.0, 250.0))
        }
    }

    if (normalizedUnit in listOf("cal", "kcal", "calories")) {
        return if (target >= 1000.0) {
            DynamicStepConfig(primaryStep = 100.0, quickAddValues = listOf(250.0, 500.0))
        } else {
            DynamicStepConfig(primaryStep = 50.0, quickAddValues = listOf(100.0, 200.0))
        }
    }

    // General numeric scaling rules
    return when {
        target <= 5.0 -> DynamicStepConfig(primaryStep = 1.0, quickAddValues = listOf(1.0, 2.0))
        target <= 15.0 -> DynamicStepConfig(primaryStep = 1.0, quickAddValues = listOf(2.0, 5.0))
        target <= 50.0 -> DynamicStepConfig(primaryStep = 1.0, quickAddValues = listOf(5.0, 10.0))
        target <= 150.0 -> DynamicStepConfig(primaryStep = 5.0, quickAddValues = listOf(10.0, 25.0))
        target <= 500.0 -> DynamicStepConfig(primaryStep = 10.0, quickAddValues = listOf(25.0, 50.0, 100.0))
        target <= 2500.0 -> DynamicStepConfig(primaryStep = 50.0, quickAddValues = listOf(100.0, 250.0, 500.0))
        target <= 10000.0 -> DynamicStepConfig(primaryStep = 250.0, quickAddValues = listOf(500.0, 1000.0, 2500.0))
        else -> {
            val power = 10.0.pow(floor(log10(target)) - 1)
            DynamicStepConfig(primaryStep = power, quickAddValues = listOf(power * 2, power * 5))
        }
    }
}

fun getDynamicTimerConfig(targetMinutes: Double = 30.0): DynamicStepConfig {
    val target = maxOf(1.0, targetMinutes)
    return when {
        target <= 15.0 -> DynamicStepConfig(primaryStep = 1.0, quickAddValues = listOf(2.0, 5.0, 10.0))
        target <= 30.0 -> DynamicStepConfig(primaryStep = 5.0, quickAddValues = listOf(5.0, 10.0, 15.0))
        target <= 60.0 -> DynamicStepConfig(primaryStep = 5.0, quickAddValues = listOf(10.0, 15.0, 30.0))
        else -> DynamicStepConfig(primaryStep = 15.0, quickAddValues = listOf(15.0, 30.0, 60.0))
    }
}
```

## Screen Specifications and Jetpack Compose UI

### 1. Daily Tracker Screen (Main Dashboard)

The primary entry point showing current and historical habit progress.

#### UI Components and Layout

- **Top Action Bar:**
  - Segmented control toggling between `Daily`, `Week Matrix`, and `Analytics`.
  - Floating Action Button (FAB) or top button to open Add Habit modal.
- **Historical Date Indicator Banner:**
  - When a past date is selected, an amber banner informs the user: *"Viewing [Date]"* with a `"Return to Today"` button.
- **Date Navigator and Rolling Week Strip:**
  - `<` and `>` day stepper buttons with a central `"Today"` pill.
  - Horizontal rolling 7-day strip centered on selected date showing Day Name (Mon, Tue), Day Number (17, 18), selection highlight, and completion indicator dot.
- **Quick-Add Bar:**
  - Inline title input field and category dropdown for single-tap habit creation.
- **Filter and Search Bar:**
  - Search field matching title and description.
  - Horizontal scrolling category filter chips.
  - Sort dropdown: *Pinned first (default)*, *Streak length*, *Alphabetical*, *Category*.
  - Show archived toggle.
- **Habit Card List:**
  - LazyColumn rendering individual habit cards with touch animations and haptic feedback.

#### Habit Card UI Details

- **Header Strip:** Color-tinted icon container, habit title, category badge, and pin star.
- **Streak Pill:** Flame icon with current consecutive streak count (`🔥 7 days`).
- **Interactive Control Variations:**
  - **Yes/No:** Large circular checkbox. Tap triggers heavy confirmation haptic on completion.
  - **Counter:** Progress bar, current vs target text (e.g. `1,250 / 2,000 ml`), minus/plus stepper buttons, quick-add chips, and an inline pencil button to enter numbers directly.
  - **Timer:** Progress bar (e.g. `15 / 25 mins`), quick +5m/+10m buttons, and a `"Start Focus"` button that launches the circular timer.
  - **Interval Slots:** Horizontal row of time slot pills (e.g. `08:00`, `11:00`, `14:00`) with independent check-in states.
- **Card interactions:** Pin toggle and check-in controls on the card. Archive and delete are **not** on the card — only on Habit Detail.
- **Card Tap Interaction:** Opens the full Habit Detail Screen.

### 2. Dedicated Habit Detail Screen

The deep dive view for individual habit execution, metadata, and history.

#### UI Components and Layout

- **Top Navigation Bar:**
  - Back arrow with predictive back support.
  - Action menu: *Edit*, *Pin/Unpin*, *Archive/Restore*, *Delete*.
- **Hero Header:**
  - Large color-accented icon and title.
  - Description text.
  - Category badge and creation date.
- **3-Metric Stats Strip:**
  - Current Streak (`🔥 X days` or `🔥 X weeks` for `WEEKLY` habits)
  - Best Streak (`🏆 X days` / `🏆 X weeks`)
  - All-Time Total Completions (`✅ X times`)
- **10-Dot Segmented Progress Bar (NUMERIC and TIMER only):**
  - Hidden for `BOOLEAN` and for subday / times-per-day slot habits.
  - Dotted progress visual indicating 0–10 segments of progress toward `targetValue`.
  - Tapping dot `N` (1–10) writes logged value as `ceil(N / 10.0 * targetValue)` (timer: minutes; numeric: unit value). Tapping the active top dot again may clear/set zero per UX polish — default: set to that level.
  - Display fill = `min(10, floor(currentValue / targetValue * 10))`.
- **Dedicated Circular Focus Timer:**
  - Circular SVG progress ring with smooth sweep countdown animation.
  - Central display showing remaining minutes and seconds (`MM:SS`).
  - Play, Pause, and Reset buttons.
  - Stepper chips: `-10m`, `-5m`, `+5m`, `+10m`.
  - Autofill Remaining button to set the timer directly to remaining unlogged minutes.
  - Direct minute editing dialog.
  - Audio/vibration alert upon completion.
- **Motivation and Notes Card:**
  - Styled motivation card with sparkle icon accent and personalized quote/reminder.
- **Scheduled Notifications List:**
  - List of active reminder times with toggle controls.
- **Monthly History Calendar:**
  - Full-month grid showing scheduled vs completed dates with month navigation (`<`, `>`).
  - Monthly metrics strip: Completion Rate %, Completed Days Count, Month's Best Streak, Total Accumulated Units/Minutes.

### 3. Add / Edit Habit Modal

Streamlined bottom sheet or full-screen dialog for habit configuration.

#### Form Sections

- **Basic Information:**
  - Habit Title (required).
  - Description and Motivation Note.
  - Category selector.
  - Color palette (8 curated presets) and Icon picker (16+ keys from `HabitIconRegistry`).
- **Target Model Selector (Segmented):**
  - `Yes/No (Boolean)`
  - `Counter (Numeric)` -> Target Value + Unit preset dropdown (`glasses`, `pages`, `reps`, `steps`, `ml`, `km`, `mins`, `cal`) or custom unit input.
  - `Timer (Duration)` -> Target duration in minutes with presets (15, 25, 30, 45, 60 mins).
- **Frequency and Recurrence Rules:**
  - `Daily`
  - `Specific Days of Week` -> Toggle buttons for Mon, Tue, Wed, Thu, Fri, Sat, Sun.
  - `Times Per Week` -> Stepper (1 to 6 times).
  - `Subday Intervals` -> Interval in hours (e.g. Every 2 hours) + Active Time Window (Start Time and End Time pickers).
  - `Times Per Day` -> Fixed count of check-ins.
- **Reminders and Notifications:**
  - Multi-reminder list.
  - One-tap preset pills: *Morning (08:00)*, *Midday (12:30)*, *Evening (18:00)*, *Night (21:30)*.
  - Custom TimePicker integration.

### 4. Week Matrix Screen

Full week consistency visualizer.

- **Header:** Week date range (e.g. `Aug 11 - Aug 17, 2026`) with previous/next week buttons and `Current Week` shortcut.
- **Matrix Grid:**
  - Row header: Habit icon, title, and weekly goal badge.
  - Columns: Mon, Tue, Wed, Thu, Fri, Sat, Sun.
  - Cells: Circular toggle icons with color coding:
    - Filled green/theme color = Completed
    - Outlined circle = Scheduled but not completed
    - Empty dot = Not scheduled
  - Direct tap on cell logs or un-logs completion.
- **Weekly Adherence Summary:**
  - Aggregate completion percentage.
  - Total completed check-ins vs total scheduled check-ins.
- **Toggleable Bar Chart View:**
  - Daily completion comparison across Monday through Sunday.

### 5. Analytics and Trends Screen

Long-term habit adherence insights and historical trends.

- **Top KPI Cards:**
  - 30-Day Consistency Score (%)
  - Best Overall Streak
  - Completed Today Count
- **Streaks Leaderboard:**
  - Ranked list of top 5 active habits sorted by current consecutive streak.
- **Adherence Trend Chart:**
  - Interactive Area chart with `7-Day` and `30-Day` filters displaying adherence rate over time.
- **Monthly Heatmap Grid:**
  - Year/Month calendar grid where each cell is shaded by completion density (0%, 1-49%, 50-99%, 100%).

## Android System Integration and Native Features

### 0. WorkManager Day Rollover and Maintenance

`WorkManager` (Phase 5) handles non-exact background work:

- **Midnight day rollover:** periodic / next-midnight worker refreshes “today” derived state, widget timelines, and cancels stale same-day notification copies.
- **Reminder maintenance:** after boot or habit edits, reconcile scheduled alarms; if exact-alarm permission is denied, schedule **inexact** reminder windows via WorkManager as fallback.
- **Widget refresh:** enqueue widget update work when habit logs change and exact UI process may not be alive.

Exact user-facing reminder times still prefer `AlarmManager.setExactAndAllowWhileIdle()` when permitted.

### 1. AlarmManager and Notification System

Precise scheduled notifications with interactive notification action buttons.

```kotlin
class HabitReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val habitId = intent.getStringExtra("EXTRA_HABIT_ID") ?: return
        val habitTitle = intent.getStringExtra("EXTRA_HABIT_TITLE") ?: "Habit Reminder"
        val habitColor = intent.getIntExtra("EXTRA_HABIT_COLOR", 0xFF0A7A64.toInt())

        val detailIntent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("app://habits/detail/$habitId"),
            context,
            MainActivity::class.java
        )
        val pendingDetailIntent = PendingIntent.getActivity(
            context,
            habitId.hashCode(),
            detailIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Interactive Notification Action: Check-in +1
        val checkInIntent = Intent(context, HabitActionReceiver::class.java).apply {
            action = "ACTION_CHECK_IN"
            putExtra("EXTRA_HABIT_ID", habitId)
        }
        val pendingCheckIn = PendingIntent.getBroadcast(
            context,
            habitId.hashCode() + 1,
            checkInIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_HABIT_REMINDERS)
            .setSmallIcon(R.drawable.ic_notification_habit)
            .setContentTitle(habitTitle)
            .setContentText("Time to complete your habit!")
            .setColor(habitColor)
            .setAutoCancel(true)
            .setContentIntent(pendingDetailIntent)
            .addAction(R.drawable.ic_check, "Check-In (+1)", pendingCheckIn)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        NotificationManagerCompat.from(context).notify(habitId.hashCode(), notification)
    }
}
```

### 2. Deep Linking and Navigation Routing

The app registers deep links for instant navigation from notifications and widgets:

- Detail Screen: `app://habits/detail/{habitId}`
- New Habit Dialog: `app://habits/new`
- Analytics Screen: `app://habits/analytics`

### 3. Jetpack Glance Home Screen Widgets

#### Quick-Log Habit Widget (4x2 / 4x1)
- Displays top 3–4 pinned or active habits for the day.
- Single-tap check-in buttons directly from the Android Home Screen using Glance `ActionCallback`.
- Real-time streak counter and daily progress circle.

#### Daily Focus Widget (2x2)
- Circular adherence progress ring showing percentage completed today.
- Today's completed count (e.g. `4/6 Completed`).
- Top active streak badge.

### 4. Haptics and Micro-Animations

- **Light Haptic Click:** On stepper button taps and segmented tab switches (`HapticFeedbackType.TextHandleMove`).
- **Heavy Confirmation Haptic:** On habit completion toggle (`HapticFeedbackType.LongPress`).
- No particle / Konfetti effects.

### 5. Foreground Focus Timer Service Policy

`FocusTimerService` uses a foreground service. Prefer `FOREGROUND_SERVICE_TYPE_SPECIAL_USE` (or the most specific allowed type for a user-initiated focus timer) with a Play Console declaration explaining user-started countdown sessions. Manifest must declare the matching `foregroundServiceType` and runtime notification while running.

## Implementation Roadmap and Milestones

1. **Milestone 1: Project Setup and Data Architecture**
   - Initialize Jetpack Compose project with Material 3.
   - Configure Room Database with entities, DAOs, converters, and unit tests for Streak, Weekly, Dynamic Stepper, and Subday Slot algorithms.
   - Add `HabitReminderScheduler` interface with no-op implementation (real AlarmManager/WorkManager wiring in Milestone 5).
2. **Milestone 2a: Daily Tracker Core and Boolean Cards**
   - Material 3 theme, navigation, `DailyTrackerScreen`, rolling date strip, search/filter.
   - Boolean `HabitCard` with pin + check-in and real haptics.
3. **Milestone 2b: Numeric / Timer / Slots and Habit Form**
   - Numeric, timer, and subday/times-per-day card controls.
   - `HabitFormBottomSheet` for create/edit (calls reminder scheduler interface; no-op until Milestone 5).
4. **Milestone 3: Dedicated Detail Screen and Circular Timer**
   - `HabitDetailScreen` with archive/delete (detail-only), NUMERIC/TIMER 10-dot bar, monthly calendar.
   - `CircularFocusTimer` + foreground service with Play policy declaration.
5. **Milestone 4: Week Matrix, Analytics, and Visualizations**
   - Week matrix and analytics with Vico charts and heatmap.
6. **Milestone 5: Notifications, Widgets, and WorkManager**
   - AlarmManager exact reminders + notification quick actions; WorkManager rollover / inexact fallback / widget maintenance.
   - Jetpack Glance Home Screen Widgets.
   - Haptics already shipped in 2a/2b — Phase 5 does not add Konfetti.
