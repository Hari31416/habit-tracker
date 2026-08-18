import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/di/providers.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/analytics/controllers/analytics_controller.dart';
import 'package:habit_tracker/ui/analytics/habit_analytics_screen.dart';
import 'package:habit_tracker/ui/analytics/widgets/adherence_area_chart.dart';
import 'package:habit_tracker/ui/analytics/widgets/monthly_heatmap_grid.dart';

import 'habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  final now = DateTime.now();

  final habit1 = Habit(
    id: 'analytics_h1',
    title: 'Daily Meditation',
    color: '#8B5CF6',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.boolean,
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('AdherenceAreaChart renders toggle and labels', (tester) async {
    final points = [
      AdherenceDataPoint(
        date: DateTime(2026, 8, 17),
        label: 'Mon',
        adherencePercent: 80,
      ),
      AdherenceDataPoint(
        date: DateTime(2026, 8, 18),
        label: 'Tue',
        adherencePercent: 100,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdherenceAreaChart(
            dataPoints: points,
            selectedRange: TrendRange.sevenDays,
            onRangeSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Adherence Trend'), findsOneWidget);
    expect(find.text('7 Days'), findsOneWidget);
    expect(find.text('30 Days'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
  });

  testWidgets('MonthlyHeatmapGrid renders month and legend', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthlyHeatmapGrid(
              month: DateTime(2026, 8, 1),
              dayDataMap: const {},
              onPreviousMonth: () {},
              onNextMonth: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('Less'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('HabitAnalyticsScreen renders consistency card, secondary KPIs, leaderboard, and charts',
      (tester) async {
    final fakeRepo = FakeHabitRepository(
      initialHabits: [habit1],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: HabitAnalyticsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Analytics'), findsWidgets);
    expect(find.text('Your Consistency'), findsOneWidget);
    expect(find.text('Best Streak'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Focus Time'), findsOneWidget);
    expect(find.text('Adherence Trend'), findsOneWidget);
  });
}
