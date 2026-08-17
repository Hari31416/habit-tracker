# Habit Tracker Implementation Plans

Master roadmap and phase-wise implementation plans for building the standalone native Android Habit Tracker application.

## Overview

The implementation is structured into six sequential phases (Phase 2 is split):

- [Phase 1: Project Setup and Data Architecture](phase-1-project-setup-and-data-architecture.md)
- [Phase 2a: Daily Tracker Core and Boolean Cards](phase-2a-daily-tracker-core-and-boolean-cards.md)
- [Phase 2b: Numeric / Timer / Slots and Habit Form](phase-2b-numeric-timer-slots-and-habit-form.md)
- [Phase 3: Habit Detail Screen and Circular Focus Timer](phase-3-detail-screen-and-circular-timer.md)
- [Phase 4: Week Matrix and Analytics](phase-4-week-matrix-and-analytics.md)
- [Phase 5: Native Notifications, WorkManager, and Glance Widgets](phase-5-native-notifications-and-glance-widgets.md)

Canonical product rules live in [`../overview.md`](../overview.md). Where phase docs and overview disagree, fix both — do not leave drift.

## Locked decisions

- **Charts:** Vico only (no MPAndroidChart).
- **Celebration:** System haptics only — **no Konfetti** / particle libraries.
- **WEEKLY habits:** ISO Monday–Sunday weeks; week is met when distinct completed days `>= targetCountPerWeek`; streak counts **weeks**.
- **10-dot progress:** NUMERIC and TIMER only; tap `N` sets value to `ceil(N / 10.0 * target)`.
- **List vs detail:** Cards support pin + check-in; **archive/delete only on Habit Detail**.
- **Reminders:** `HabitReminderScheduler` interface from Phase 1; no-op until Phase 5 wires AlarmManager + WorkManager.
- **Icons:** Lucide-style string keys → `HabitIconRegistry` → Material Icons / drawables.

## Phase Summary

### Phase 1: Project Setup and Data Architecture

Gradle version catalog, Room schema, domain engines (including weekly streak rules), repository, reminder scheduler interface (no-op), icon registry stub, and unit tests.

### Phase 2a: Daily Tracker Core and Boolean Cards

Material 3 theme, navigation, daily dashboard chrome, rolling week strip, search/filter, boolean habit cards with real haptics. Pin + check-in only (no archive/delete on list).

### Phase 2b: Numeric / Timer / Slots and Habit Form

Numeric, timer, and subday/times-per-day card controls; full add/edit form. Form calls reminder scheduler interface (still no-op).

### Phase 3: Habit Detail Screen and Circular Focus Timer

Detail screen with archive/delete, NUMERIC/TIMER 10-dot bar, monthly calendar, circular focus timer + foreground service (Play policy declaration).

### Phase 4: Week Matrix and Analytics

Week matrix grid and analytics (Vico area chart, streak leaderboard, monthly heatmap).

### Phase 5: Native Notifications, WorkManager, and Glance Widgets

Exact AlarmManager reminders, WorkManager midnight rollover / inexact fallback / widget maintenance, boot receiver, Glance widgets. No Konfetti.
