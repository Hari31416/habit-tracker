# Product Feature Roadmap

Strategic feature roadmap for the Habit Tracker application, ordered sequentially by development priority, retention impact, and implementation efficiency.

## 1. Gamification and Progression Engine (Completed)

- [x] **Experience Points (XP) System:** Earn XP dynamically for each habit check-in based on difficulty, duration, and consistency.
- [x] **Player Levels and Titles:** Level up through quadratic XP thresholds to unlock mastery titles (Novice, Apprentice, Pathfinder, Grandmaster).
- [x] **Streak Multipliers:** Scale XP rewards with active streaks (1.25x for 7 days, 1.5x for 14 days, 2.0x for 30+ days).
- [x] **Milestone Achievement Badges:** 20+ unlockable achievements for streaks, total volume, category diversity, and perfect days.
- [x] **Progression UI:** Level status badge on dashboard header with animated progress bars, level-up celebration dialogs, and a dedicated badges showcase.

## 2. Habit Shields and Grace Days

- [ ] **Streak Freeze Mechanism:** Protect streaks against unavoidable missed days caused by illness, travel, or emergencies.
- [ ] **Shield Banking:** Automatically earn 1 shield for every 14 days of unbroken consistency, capped at a configurable maximum.
- [ ] **Auto and Manual Protection:** Option to auto-consume shields on missed days or manually apply them to past dates.
- [ ] **Visual Distinction:** Distinct shield markers in the calendar and matrix views so genuine completion history remains accurate.

## 3. Elastic Goals and Bad-Day Mode

- [ ] **Three-Tiered Targets:** Define Mini (minimum viable habit), Base (standard target), and Elite (high-energy goal) tiers for habits.
- [ ] **Momentum Preservation:** Completing a Mini target (e.g. 1 page read instead of 20) preserves streak continuity on difficult days.
- [ ] **Tiered XP Scaling:** Proportional XP rewards based on achieved tier (Mini: 5 XP, Base: 20 XP, Elite: 35 XP).

## 4. Habit Stacking and Daily Routines

- [ ] **Sequential Routine Chains:** Group habits into structured morning, workday, or evening sequences ("After Habit A, do Habit B").
- [ ] **Routine Player Mode:** Full-screen flow guiding users step-by-step through each habit in the stack with integrated timers and transition cues.
- [ ] **Routine Completion Bonus:** Award bonus XP and specific badges when completing an entire routine in sequence.

## 5. Google Health Connect Integration

- [ ] **Automated Physical Habit Sync:** Auto-log steps, active exercise minutes, hydration, and sleep duration from Health Connect.
- [ ] **Zero-Touch Check-Ins:** Mark daily targets as completed in the background as soon as fitness trackers or health apps report the required data.
- [ ] **Permissions and Privacy:** Granular per-habit permission toggles with background sync via WorkManager.

## 6. Quick Settings Tile and App Shortcuts

- [ ] **Notification Shade Tile:** Android Quick Settings Tile to view and check in the top pinned habit with a single tap.
- [ ] **Dynamic Launcher Shortcuts:** Long-press app icon to access instant check-ins or start focus sessions for top habits.

## 7. Habit Correlation Matrix and Synergies

- [ ] **Cross-Habit Insights:** Pearson correlation engine detecting hidden connections between habits (e.g. "Morning meditation increases deep work completion by 38%").
- [ ] **Keystone Habit Discovery:** Highlight habits with the highest positive ripple effect on overall daily consistency.
- [ ] **Synergy Cards:** Actionable intelligence cards presented in the Analytics screen.

## 8. Check-In Micro-Notes and Mood/Energy Tagging

- [ ] **Post-Check-In Reflection:** Optional 1-tap energy rating (1-5 scale), mood selection, and short 1-line notes on completion.
- [ ] **History Timeline:** Visual timeline of reflections and energy levels on the Habit Detail screen.
- [ ] **Wellbeing Correlation:** Visual charts showing how habit consistency impacts self-reported energy over time.

## 9. Negative Habits and Sobriety Counter

- [ ] **Abstinence Tracking:** Dedicated mode for habits to break (smoking, social media detox, sugar).
- [ ] **Elapsed Time Counter:** Real-time counter displaying days, hours, and minutes since last reset.
- [ ] **Urge Surfer Tool:** 2-minute box breathing focus timer to assist in overcoming sudden cravings.

## 10. "Habit Wrapped" Shareable Summaries

- [ ] **Milestone Recap Cards:** Monthly and year-end visual infographic cards displaying total minutes focused, volume logged, and achievements earned.
- [ ] **Image Export:** Direct image generation and sharing to social channels or personal journals.

## 11. Encrypted Google Drive Auto-Backup and Portability

- [ ] **Private AppData Cloud Backup:** Automated background backup to private Google Drive AppData folder with client-side AES-256 encryption.
- [ ] **Open Data Portability:** Full JSON and CSV import and export for spreadsheet analysis, backup archiving, or migration.
- [ ] **Biometric App Lock:** Optional fingerprint and face unlock protection for sensitive habits.

## 12. Physical Anchors (NFC and QR Check-Ins)

- [ ] **NFC Tag Scanning:** Tap phone against cheap NFC stickers (on water bottles, gym bags, bedside tables) to instantly log a habit.
- [ ] **Built-in Tag Writer:** In-app tool to write habit deep links to standard NTAG213/215 stickers from the Habit Detail screen.
- [ ] **Frictionless Action:** Record check-in and deliver haptic feedback without requiring full navigation into the app.
