# Privacy Policy

Phial is built with a local-first, privacy-respecting architecture.

## Data Storage and Networking

- Fully Offline: The application does not require an internet connection and makes no network requests in release builds.
- No Accounts: No account creation, login, or cloud authentication is used.
- Local SQLite Database: All habits, logs, reflections, streaks, and preferences are stored locally on device via Drift SQLite and SharedPreferences.
- No Analytics or Tracking: No third-party trackers, analytics SDKs, advertising frameworks, or crash reporting telemetry are embedded.
- Backup Disabled: Android cloud backup and device transfer of application databases are disabled for the alpha release to ensure your habit data remains solely on your physical device.

## Permissions

- Notifications (`POST_NOTIFICATIONS`): Used strictly for local scheduled habit reminders on device.
- Exact Alarms (`SCHEDULE_EXACT_ALARM`): Used strictly to trigger scheduled reminder notifications at the precise time requested.
- Foreground Service: Used solely for the user-initiated focus countdown timer.
