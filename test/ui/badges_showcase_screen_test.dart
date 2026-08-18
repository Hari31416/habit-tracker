import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/di/providers.dart';
import 'package:habit_tracker/domain/gamification/gamification_models.dart';
import 'package:habit_tracker/domain/gamification/player_title.dart';
import 'package:habit_tracker/ui/gamification/badges_showcase_screen.dart';
import 'package:habit_tracker/ui/gamification/dialogs/level_up_celebration_dialog.dart';
import 'package:habit_tracker/ui/gamification/widgets/player_level_header_badge.dart';

import 'gamification_controller_test.dart' show FakeGamificationRepository;

void main() {
  const testProgression = PlayerProgression(
    totalXp: 350,
    level: 3,
    title: PlayerTitle.novice,
    currentLevelBaseXp: 200,
    nextLevelTargetXp: 400,
    progressFraction: 0.75,
    activeStreakMultiplier: 1.25,
    unlockedBadgesCount: 4,
    totalBadgesCount: 15,
  );

  const testAchievement = AchievementStatus(
    definition: AchievementDefinition(
      id: 'streak_3',
      title: 'Getting Started',
      description: 'Reach a 3-day streak',
      category: AchievementCategory.streak,
      tier: AchievementTier.bronze,
      iconName: 'fire',
      xpReward: 50,
      targetValue: 3,
      unit: 'days',
    ),
    isUnlocked: true,
    currentProgress: 3,
    progressFraction: 1.0,
  );

  testWidgets('PlayerLevelHeaderBadge renders level, title, multiplier, badges count',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerLevelHeaderBadge(
            progression: testProgression,
            onClick: () {},
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('Novice'), findsOneWidget);
    expect(find.text('1.25x XP'), findsOneWidget);
    expect(find.text('350 / 400 XP'), findsOneWidget);
    expect(find.text('4/15'), findsOneWidget);
  });

  testWidgets('LevelUpCelebrationDialog renders celebration title and dismiss button',
      (tester) async {
    bool dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LevelUpCelebrationDialog(
            celebration: const LevelUpCelebration(
              newLevel: 5,
              previousLevel: 4,
              title: PlayerTitle.apprentice,
              titleChanged: true,
            ),
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LEVEL UP'), findsOneWidget);
    expect(find.text('Level 5'), findsOneWidget);
    expect(find.text('Apprentice'), findsOneWidget);
    expect(find.text('Claim & Continue'), findsOneWidget);

    await tester.tap(find.text('Claim & Continue'));
    await tester.pumpAndSettle();
    expect(dismissed, isTrue);
  });

  testWidgets('BadgesShowcaseScreen renders hero card, multipliers, filters, and badge cards',
      (tester) async {
    final fakeRepo = FakeGamificationRepository(
      progression: testProgression,
      achievements: [testAchievement],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamificationRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: BadgesShowcaseScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Mastery & Badges'), findsOneWidget);
    expect(find.text('Lv.3'), findsOneWidget);
    expect(find.text('Streak Multiplier'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Streaks'), findsOneWidget);
    expect(find.text('All Achievements'), findsOneWidget);
    expect(find.text('Getting Started'), findsOneWidget);
    expect(find.text('+50 XP'), findsOneWidget);
  });
}
