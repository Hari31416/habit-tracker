# Regression harness plan

Agent implementation plan. Makes broken changes *red* before merge: a dropped field, a bad Drift upgrade, a broken check-in journey, or a visual slip fails a test.

Existing `test/` engines and faked widget tests stay. This harness adds *contract*, *journey*, *golden*, CI tripwires, and a Maestro black-box smoke on a real APK.

## Session

1. Read this whole file once.
2. Pick the phase: the one named in the user prompt, otherwise the first phase whose Done is still false in the tree.
3. Implement only that phase.
4. Stop when that phase's Done is true and `make test` is green.

Leave later phases for a later session. Commit only if the user asks.

## Shared rules

**red.** Every new test starts from a failure you have seen: omit a field, skip a migration step, or break an *invariant*, then confirm the test fails, then make it pass.

**tight.** Prefer in-memory Drift (`NativeDatabase.memory()`), fixed `DateTime.utc` clocks, and no network. Fake Riverpod only in widget/golden tests. *Journey* tests use real `HabitRepositoryImpl`, `BackupRepositoryImpl`, and `GamificationRepositoryImpl`.

**fixture.** One fully populated object per entity, every optional field set to a distinctive non-default. Shared helper: `test/helpers/contract_fixtures.dart`. Production seed data is not a *fixture*.

**field assert.** Compare round-trips field-by-field (or a generated field list). `Habit` has no `==`. A single `expect(actual, equals(expected))` on a map of a few keys is not a *contract*.

**SoT.** After Phase 1, the *contract* test is the source of truth for entity mapping. `AGENTS.md` points at that test; it does not restate the mapper list.

**scope.** Follow existing test style. Add Dart packages only if a phase names one. Maestro is a **CLI**, not a `pubspec` dependency. Device UI automation is Maestro YAML; leave `scripts/adb_automated_test.sh` as optional screenshots.

## Baseline (do not re-solve)

CI (`.github/workflows/ci.yml`) already runs `flutter analyze`, `flutter test`, and a debug APK. `test/` already covers streak, shields, gamification, backup import modes, and screen smoke tests with fakes. `AppDatabase.schemaVersion` is `7`. Package id is `app.phial.habits`. `make adb-test` taps by screen percentage. Flutter `Key` / `ValueKey` are invisible to Maestro; only the semantics tree is. Nav labels today are `Today`, `Week`, `Analytics`, `Mastery`; the add control is an unlabeled `Icons.add`. Fresh install seeds categories only; demo habits appear after `seedDemoHabits()` (daily tracker path), so a Maestro smoke that `clearState`s must create a habit or assert empty Today — it must not assume `Deep Work Session` exists.

## Phase 1: Entity contract

Close the six-layer mapping gap with one *red* *contract*.

### Layers the fixture must survive

For `Habit` and `HabitLog` (and every other type the envelope serializes: category, shield, gamification, achievement):

- Domain constructor and `copyWith`
- Drift table column, nullability, converter
- `HabitRepositoryImpl` row↔domain (`_habitRowToDomain`, `_habitDomainToCompanion`, `_logRowToDomain`, `_logDomainToCompanion`)
- `BackupRepositoryImpl` row↔companion (`_habitRowToDomain`, `_habitToCompanion`, `_logRowToDomain`, `_logToCompanion`)
- `GamificationRepositoryImpl` row→domain (`_habitRowToDomain`, `_logRowToDomain`)
- `SyncEnvelope` JSON (`_habitToJson`, `_habitFromJson`, `_logToJson`, `_logFromJson`, plus the sibling maps for other collections)

### Steps

1. Add `test/helpers/contract_fixtures.dart` with one *fixture* per envelope collection. Distinctive values: non-default `TimeWindow`, `targetDaysOfWeek`, elastic targets, `healthMetric`, `reminderTimes`, log `intervalIndex`, `targetTier`, `energyLevel`, `mood`.
2. Add `test/data/entity_contract_roundtrip_test.dart`:
   - Upsert *fixture* via `HabitRepositoryImpl` into memory Drift.
   - Read back via `HabitRepositoryImpl` and `GamificationRepositoryImpl`; *field assert* every field.
   - `exportBackupJson` → parse → *golden* JSON (stable clock, pretty-printed, sorted keys) at `test/goldens/sync/envelope_full.json`.
   - `executeImport` overwrite into a fresh memory DB; *field assert* every field again.
3. Prove *red*: temporarily drop one JSON key or one companion column mapping; the test fails; revert the sabotage.
4. Replace the six-layer bullet list in `AGENTS.md` with a pointer to this test file and the *fixture* helper. Keep streak and gamification *invariant* bullets; those are Phase 3.

### Done

- `flutter test test/data/entity_contract_roundtrip_test.dart` is green.
- Removing any `Habit` or `HabitLog` field from `_habitToJson` / `_logToJson` (or from a repository companion map) makes that test fail.
- `test/goldens/sync/envelope_full.json` is committed and matches export output.
- `AGENTS.md` mapping checklist is a pointer to the *contract* test.
- `make test` is green.

## Phase 2: Drift schema upgrades

Fresh `NativeDatabase.memory()` never runs `onUpgrade`. Version 7 already has additive steps; the next bump needs a *red* upgrade test.

### Steps

1. Dump the current schema with Drift's schema tools (`drift_dev schema dump` against `lib/data/local/app_database.dart` into `drift_schemas/`). Commit the dump for version 7.
2. Generate verifier helpers (`drift_dev schema generate` into `test/generated_migrations/` or the path Drift documents for this `drift_dev` version). Commit generated test support.
3. Add `test/data/database_migration_test.dart` using Drift `SchemaVerifier`: open at version N, insert a row that uses columns introduced at N, upgrade to current, assert the row and new columns exist. Cover at least `6 → 7` (elastic targets / `targetTier`) and `current → current` (no-op).
4. Document in that test's header comment the dump/generate commands used, so the next `schemaVersion` bump is a mechanical follow-on.
5. Wire `make codegen` or a named Makefile target only if dump/generate is not already implied by `flutter-codegen`; keep lookup in the Makefile, not duplicated here.

### Done

- `drift_schemas/` contains the version 7 dump.
- `flutter test test/data/database_migration_test.dart` is green.
- A sabotaged `onUpgrade` that skips the v7 columns makes the `6 → 7` test fail.
- `make test` is green.

## Phase 3: Journeys and named invariants

Catch wiring bugs *contract* tests miss: calculator correct, controller or XP path stale.

### Steps

1. Add `test/data/journeys/` with real repos and memory Drift:
   - **check-in → streak → XP:** boolean daily habit, consecutive completed days, unlogged today still keeps the in-progress chain; gamification read shows XP and multiplier from `currentStreak`.
   - **elastic mini-target:** numeric habit with `miniTargetValue`; a mini-tier log keeps the streak.
   - **backup restore:** *fixture* export, wipe/overwrite import, same streak and XP as before export.
   - **archive vs delete:** archive hides from active watch; delete is a detail-path operation as the product rule states.
2. In existing engine tests (`test/domain/streak_calculator_test.dart`, `test/domain/elastic_goals_test.dart`, `test/domain/achievement_evaluator_test.dart`, `test/domain/gamification_engine_test.dart`, `test/domain/sync/sync_merge_engine_test.dart`), give each *invariant* in `AGENTS.md` a dedicated `test(...)` name that matches the rule (daily unlogged today, ISO weekly target, custom-day skip, mini-target preserves streak, multiplier uses `currentStreak`, unlock iff `progress >= targetValue`, merge exports only `isUnlocked`). Add a test only when that name is missing; keep existing coverage.
3. Prove *red* on one *journey*: break the controller/repo handoff (or skip persisting a log) and confirm the *journey* fails.

### Done

- Every *invariant* bullet in `AGENTS.md` has a same-named test that fails if the rule is inverted.
- The four *journeys* above exist and pass with real Drift.
- `make test` is green.

## Phase 4: UI goldens and CI tripwires

Catch layout and process misses. Pin pixels and generated code.

### Steps

1. Add Flutter `matchesGoldenFile` tests using `PreviewFixtures` / existing preview wrappers:
   - `HabitCard` boolean complete and incomplete (light)
   - `HabitCard` numeric with elastic tiers (light)
   - one week-matrix cell or grid slice (light)
   - `HabitBottomNavigation` (light)
   Dark variants only if they stay stable on CI (same Flutter version).
2. Store goldens under `test/goldens/ui/`. Document in the test file how to regenerate (`flutter test --update-goldens` on the named files).
3. Pin Flutter in `.github/workflows/ci.yml` to a specific stable version (the one used to generate goldens), not a floating channel.
4. After `flutter pub get`, CI runs codegen (`dart run build_runner build --delete-conflicting-outputs`) and fails on a dirty git tree for generated Drift files.
5. CI runs `flutter test --coverage`. Fail the job if coverage of `lib/domain/` plus `lib/data/` is below a baseline you record in this phase (write the percentage into `.github/coverage_baseline` after measuring on `main` plus phases 1–3). Fail on a drop larger than 1.0 percentage point.

### Done

- Named UI goldens are committed and pass on CI's pinned Flutter.
- CI pins Flutter version, fails on stale codegen, and fails on domain+data coverage drop past the baseline file.
- `make test` is green locally (goldens included).

## Phase 5: Maestro smoke

Black-box flows against an **installed APK**. Maestro talks to Android accessibility (TalkBack's tree), not Dart. Same YAML can later run on iOS. One device suite: Maestro. Skip Flutter `integration_test/` unless a later prompt asks for both.

Maestro docs for Flutter: [Semantics and `identifier`](https://docs.maestro.dev/get-started/supported-platform/flutter). Selectors: `id:` for `Semantics(identifier:)`, visible text for `Text` / `semanticLabel`. `tapOn` by pixel percent is the same trap as the ADB script.

### Selectors to add in the app

Stable `Semantics(identifier:)` on:

- `nav_today`, `nav_week`, `nav_analytics`, `nav_mastery`, `nav_add`
- boolean check-in on a habit card (`habit_check_<habitId>` or a test-only id on the first card)
- habit form save (`habit_form_save`)
- unique screen headings if they are not already `Text` Maestro can see (`Today's Progress`, week/analytics/mastery titles)

Wrap the add `Icon` (no text today). Keep identifiers stable when copy changes. Screen-reader labels (`semanticLabel` / `Semantics(label:)`) stay human-readable; `identifier` is for tests.

### Flows

Directory: `.maestro/` (Maestro default). `appId: app.phial.habits`.

1. `smoke.yaml` — `launchApp` with `clearState: true` → assert Today chrome → tap `nav_add` → create a boolean habit with a unique title → assert that title on Today → tap its check-in id → tap `nav_week`, `nav_analytics`, `nav_mastery` → `assertVisible` each screen's heading → return `nav_today`.
2. Optional second flow only if the first is green: notification permission / overflow. Stay on one smoke until it is *red* on a missing nav id.

Prove *red*: remove `nav_week` identifier (or rename the Week heading) and confirm `maestro test` fails.

### Tooling

1. Flows only in git. Developers install the Maestro CLI locally (curl installer from Maestro docs). CI installs the same CLI in the job; do not vendor the binary.
2. Makefile: `make maestro` installs the debug APK if needed, then `maestro test .maestro/smoke.yaml`. Device/emulator must already be up (`make emulator-start` / `make run` is a separate step).
3. CI: a **nightly or `workflow_dispatch`** job: pinned AVD, `flutter build apk --debug`, install, `maestro test`. PR CI stays analyze + `flutter test` (Phases 1–4). Add Maestro to PR only after the smoke is stable on that AVD.
4. Point `make adb-test` help text at `make maestro` as the automated UI net; keep the ADB script for screenshot capture if you still want PNGs.

### Done

- `.maestro/smoke.yaml` exists and passes on a local emulator via `make maestro`.
- Nav, add, check-in, and form save are reachable with `id:` selectors (`Semantics.identifier`).
- Sabotaging one of those identifiers makes the flow fail.
- CI has a non-PR job that builds the debug APK and runs that flow, or the Makefile target is documented as local-only with a follow-up issue if emulator CI is deferred.
- `make test` stays green (Maestro is not part of `flutter test`).

## Out of scope until asked

Property-based random calendars, 100% line coverage, Patrol, Flutter `integration_test/`, screenshot diff of `make adb-test`, expanding faked screen widget tests, rewriting engines, Maestro Cloud.
