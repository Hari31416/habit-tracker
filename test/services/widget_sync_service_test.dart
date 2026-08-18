import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/gamification/gamification_models.dart';
import 'package:habit_tracker/domain/gamification/player_title.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/services/app_shortcuts_service.dart';
import 'package:habit_tracker/services/widget_sync_service.dart';

import '../ui/gamification_controller_test.dart'
    show FakeGamificationRepository;
import '../ui/habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime.now();

  final pinnedHabit = Habit(
    id: 'w_pinned',
    title: 'Morning Yoga',
    color: '#10B981',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.boolean,
    pinned: true,
    createdAt: today,
    updatedAt: today,
  );

  final unpinnedHabit = Habit(
    id: 'w_unpinned',
    title: 'Reading',
    color: '#6366F1',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.timer,
    targetValue: 30.0,
    pinned: false,
    createdAt: today,
    updatedAt: today,
  );

  test('WidgetSyncService generates DailyFocus, TodayHabits, and Streaks snapshots',
      () async {
    final habitRepo = FakeHabitRepository(
      initialHabits: [pinnedHabit, unpinnedHabit],
    );

    const testProgression = PlayerProgression(
      totalXp: 450,
      level: 4,
      title: PlayerTitle.apprentice,
      nextLevelTargetXp: 600,
      unlockedBadgesCount: 5,
      totalBadgesCount: 15,
    );

    final gamificationRepo = FakeGamificationRepository(
      progression: testProgression,
    );

    final widgetSync = WidgetSyncService(habitRepo, gamificationRepo);
    await widgetSync.syncAllWidgets(today);

    // 1. Daily Focus Snapshot
    final dailyFocus = widgetSync.lastDailyFocus;
    expect(dailyFocus, isNotNull);
    expect(dailyFocus!.totalScheduled, 2);
    expect(dailyFocus.completedCount, 0);
    expect(dailyFocus.ratePercent, 0);

    // 2. Today's Habits Snapshot (pinned first)
    final todaysHabits = widgetSync.lastTodaysHabits;
    expect(todaysHabits, isNotNull);
    expect(todaysHabits!.habits.length, 2);
    expect(todaysHabits.habits.first.id, 'w_pinned');
    expect(todaysHabits.habits.first.pinned, isTrue);

    // 3. Streaks Snapshot
    final streaks = widgetSync.lastStreaks;
    expect(streaks, isNotNull);
    expect(streaks!.habits.length, 2);

    // 4. XP Mastery Snapshot
    final xpMastery = widgetSync.lastXpMastery;
    expect(xpMastery, isNotNull);
    expect(xpMastery!.level, 4);
    expect(xpMastery.titleDisplayName, 'Apprentice');
    expect(xpMastery.unlockedBadgesCount, 5);
  });

  test('AppShortcutsService exposes top pinned habits for dynamic shortcuts',
      () async {
    final habitRepo = FakeHabitRepository(
      initialHabits: [pinnedHabit, unpinnedHabit],
    );
    final shortcutsService = AppShortcutsService(habitRepo);

    await shortcutsService.updateDynamicShortcuts();

    expect(shortcutsService.currentShortcuts.length, 2);
    expect(shortcutsService.currentShortcuts.first.id, 'shortcut_w_pinned');
    expect(
      shortcutsService.currentShortcuts.first.deepLinkUri,
      'app://habits/detail/w_pinned',
    );
  });
}
