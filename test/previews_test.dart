import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/ui/common/previews/phial_previews.dart';
import 'package:habit_tracker/ui/common/previews/preview_fixtures.dart';
import 'package:habit_tracker/ui/daily/widgets/habit_card.dart';
import 'package:habit_tracker/ui/daily/widgets/historical_banner.dart';
import 'package:habit_tracker/ui/detail/widgets/stats_metric_strip.dart';
import 'package:habit_tracker/ui/detail/widgets/ten_dot_progress_bar.dart';
import 'package:habit_tracker/ui/gamification/widgets/player_level_header_badge.dart';
import 'package:habit_tracker/ui/gamification/widgets/shield_bank_status_card.dart';

void main() {
  group('Phial Widget Previews & Fixtures Tests', () {
    test('PhialMultiBrightnessPreview generates Light and Dark preview entries', () {
      const preview = PhialMultiBrightnessPreview(name: 'Test Component');
      expect(preview.previews.length, 2);
      expect(preview.previews[0].name, 'Test Component (Light)');
      expect(preview.previews[0].brightness, Brightness.light);
      expect(preview.previews[1].name, 'Test Component (Dark)');
      expect(preview.previews[1].brightness, Brightness.dark);
    });

    test('PreviewFixtures generates valid sample models', () {
      final habit = PreviewFixtures.sampleHabit(title: 'Read Book');
      expect(habit.title, 'Read Book');

      final habitWithProgress = PreviewFixtures.sampleHabitWithProgress(isCompleted: true);
      expect(habitWithProgress.isCompletedOnDate, isTrue);

      final progression = PreviewFixtures.sampleProgression(level: 5);
      expect(progression.level, 5);

      final shieldState = PreviewFixtures.sampleShieldBankState(availableShields: 2);
      expect(shieldState.availableShields, 2);
    });

    testWidgets('ShieldBankStatusView renders properly in PhialPreviewWrapper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: previewShieldBankAvailable(),
        ),
      );
      expect(find.text('Streak Shields'), findsOneWidget);
      expect(find.text('2 / 3 Available'), findsOneWidget);
    });

    testWidgets('PlayerLevelHeaderBadge preview renders properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: previewPlayerLevelBadgeStandard(),
        ),
      );
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('HabitCard preview renders properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: previewHabitCardIncomplete(),
        ),
      );
      expect(find.text('Morning Meditation'), findsOneWidget);
    });

    testWidgets('TenDotProgressBar preview renders properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: previewTenDotProgressBarHalf(),
        ),
      );
      expect(find.text('10-Dot Progress'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('HistoricalBanner preview renders properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: previewHistoricalBannerPast(),
        ),
      );
      expect(find.text('Return to Today'), findsOneWidget);
    });

    testWidgets('StatsMetricStrip preview renders properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: previewStatsMetricStripDaily(),
        ),
      );
      expect(find.text('Current (d)'), findsOneWidget);
      expect(find.text('Best (d)'), findsOneWidget);
      expect(find.text('Total Times'), findsOneWidget);
    });
  });
}
