# Phial brand

Locked for the Android alpha. Use this file for launcher copy, Play listing, package id, and in-app voice. Do not put Drop, Ripple, potion, or drink in the product name or store title.

## Name

| Surface                   | Value                        |
| ------------------------- | ---------------------------- |
| Brand                     | Phial                        |
| Launcher and in-app title | Phial                        |
| Play Store title          | Phial: Habit Tracker & Focus |
| Play title length         | 28 characters (limit 30)     |
| Pronunciation             | FYE-ul (like vial)           |

The home-screen label is **Phial** only. The long form exists only on the store card so search can still match habit tracker and focus.

### Public site hero

Locked for `docs/index.html` and feature graphics. Prefer this over stacked metaphors (shelf, cork, seal the day) on first-run surfaces.

**Headline**

```text
Fill today’s phial.
Protect the streak.
```

**Lead**

```text
Phial tracks daily habits and focus sessions on your phone. Check in to complete the day, run the timer when you need depth, and a missed day does not have to break your streak. Offline. No account.
```

## Story

A phial is a small bottle for something you do not waste: a dose of attention, a drop of light, a day’s worth of work. Each day you seal a drop of focus. The streak is how many phials still stand.

The icon is not a water drop. It is the charge inside the glass: teal essence, check cut through it when the day is done. The dark forest UI is the shelf. Amber is streak heat and gold badges, not the liquid.

### How the product maps

- **Check-in:** Fill today’s phial and mark it. Done is sealed, not logged.
- **Focus timer:** Sit with the charge for the session. Do not empty it in a tap.
- **Streak:** An unbroken row of sealed phials. A miss tips one.
- **Shield:** A cork you earned. It keeps one miss from spilling the shelf.
- **XP and titles (Novice to Grandmaster):** Ranks in the craft of keeping the shelf, not arcade noise.
- **Offline:** The phials live on the device. Nobody else’s vault.

### Voice

Quiet game, not cartoon RPG. Prefer “seal the day,” “the phial holds,” “the shelf stands.” Avoid “potion,” “drink,” “sip,” “level up!!,” and any line that still works if you swap in water. The drop is the contents. The product is keeping the vessel.

### Color

- **Teal** (`#0A7A64` light, `#14B8A6` dark): essence, completion, the drop.
- **Forest** (`#0B1211`, `#111C1A`): shelf, surfaces.
- **Amber** (`#F59E0B`): streak, XP gold, warning. Accent only.

## Unique identifiers

Change the application id **before** the first Play upload. Google does not allow renaming it later. `com.phial.app` is already a flashlight app; do not use it.

| Kind                        | Value                        | Notes                                                         |
| --------------------------- | ---------------------------- | ------------------------------------------------------------- |
| Android `applicationId`     | `app.phial.habits`           | Reverse-DNS style, habits disambiguates from other Phial apps |
| Current id (replace)        | `com.productivity.habits`    | Debug/alpha only until the rename lands                       |
| Kotlin / manifest namespace | `app.phial.habits`           | Keep in lockstep with `applicationId`                         |
| Android `android:label`     | `@string/app_name` → `Phial` | Launcher name                                                 |
| Deep-link scheme (target)   | `phial`                      | Example: `phial://habits/detail/{id}`                         |
| Deep-link scheme (today)    | `app`                        | `app://habits/...` until the rename is implemented            |
| iOS bundle id (later)       | `app.phial.habits`           | Not in this alpha                                             |
| Play developer name         | Set in Play Console          | Use the same legal name on every listing                      |

When renaming the id, update Gradle `applicationId` / `namespace`, deep links, widget `PendingIntent` actions, notification channels, and any `ComponentName` strings. Do not ship two packages to testers.

## Play Store listing

Category: **Productivity**. Tags to use in prose, not stuffed in the title: habits, streaks, focus timer, offline.

### Title

```text
Phial: Habit Tracker & Focus
```

Do not add emojis, ALL CAPS, Free, Best, or extra keywords. The title already uses the two search terms that matter.

### Short description

Limit 80 characters including spaces. Use this:

```text
Habit tracker & focus timer. Streaks, shields, XP. Fully offline, no account.
```

Character count: 78.

### Full description

```text
Phial is a habit tracker and focus companion. Each day you seal a drop of attention. Check in to complete the day, run a focus session to fill the charge, and protect your streak when life knocks one over.

WHAT YOU CAN TRACK

- Daily, weekly, and custom-day habits
- Yes/no check-ins, numeric targets, and timed focus sessions
- Sub-day slots and intervals for structured routines

CONSISTENCY WITHOUT A CLOUD

- Streaks that skip unscheduled days instead of punishing you
- Shields that cork a single miss so the shelf does not spill
- XP, titles from Novice to Grandmaster, and achievement badges
- Home screen widgets for today, streaks, focus, and mastery

FOCUS

- A countdown focus timer with a foreground session
- Optional do-not-disturb while you sit with the work

PRIVACY

- Fully offline. No account, no ads, no tracking
- Habit titles, notes, mood, and energy stay on the device
- Android Auto Backup is disabled for this alpha

Phial is an Android alpha. iOS is not included yet.
```

### Asset copy

- **Icon:** Existing teal drop with check. Do not add the word Phial on the icon.
- **Feature graphic headline:** Fill today’s phial.
- **Feature graphic subhead:** Protect the streak.

## In-app strings

Replace visible “Habit Tracker” with Phial in:

- `android/app/src/main/res/values/strings.xml` (`app_name`)
- `lib/main.dart` (`MaterialApp` title)
- About / settings if a product name appears

Widget *names* stay functional (Today’s Habits, Streaks, Daily Focus, XP / Mastery). They describe the widget, not the brand.

## What not to say

- Drop, DropMark, Dropwise, DailyDrop, Ripple in the brand or title
- Potion, elixir, drink, hydration, water tracker
- Cloud sync, AI coach, or social features we do not ship
- iOS availability until it is release-validated
