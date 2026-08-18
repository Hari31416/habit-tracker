import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/di/providers.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/detail/controllers/timer_state_holder.dart';
import 'package:habit_tracker/ui/detail/focus_timer_screen.dart';
import 'package:habit_tracker/ui/detail/habit_detail_screen.dart';
import 'package:habit_tracker/ui/detail/widgets/circular_focus_timer.dart';
import 'package:habit_tracker/ui/detail/widgets/habit_monthly_calendar.dart';
import 'package:habit_tracker/ui/detail/widgets/motivation_card.dart';
import 'package:habit_tracker/ui/detail/widgets/stats_metric_strip.dart';
import 'package:habit_tracker/ui/detail/widgets/ten_dot_progress_bar.dart';

import 'habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  final now = DateTime.now();

  final testCategory = const HabitCategory(
    id: 'cat-work',
    name: 'Work',
    color: '#8B5CF6',
    icon: 'briefcase',
  );

  final numericHabit = Habit(
    id: 'habit-num',
    title: 'Daily Pages',
    description: 'Read 20 pages',
    color: '#8B5CF6',
    icon: 'book-open',
    categoryId: 'cat-work',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.numeric,
    targetValue: 20.0,
    unit: 'pages',
    reminderTimes: const ['08:00', '20:00'],
    motivationNotes: 'Reading makes you wiser',
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('TenDotProgressBar renders 10 dots and handles taps',
      (tester) async {
    double clickedVal = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenDotProgressBar(
            habit: numericHabit,
            currentValue: 10.0,
            accentColor: Colors.purple,
            onDotClick: (val) => clickedVal = val,
          ),
        ),
      ),
    );

    expect(find.text('10-Dot Progress'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    // 10 numbered dots
    for (int i = 1; i <= 10; i++) {
      expect(find.text('$i'), findsOneWidget);
    }

    // Tap 5th dot
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(clickedVal, 10.0); // ceil(5/10 * 20) = 10.0

    // Tap 10th dot
    await tester.tap(find.text('10'));
    await tester.pump();
    expect(clickedVal, 20.0); // ceil(10/10 * 20) = 20.0
  });

  testWidgets('StatsMetricStrip renders current streak, best streak, and completions',
      (tester) async {
    const streak = StreakResult(
      currentStreak: 5,
      bestStreak: 12,
      completionRate30Days: 80,
      totalCompletions: 34,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatsMetricStrip(
            streak: streak,
            streakUnit: 'days',
            accentColor: Colors.purple,
          ),
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);
    expect(find.text('Current (days)'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Best (days)'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);
    expect(find.text('Total Times'), findsOneWidget);
  });

  testWidgets('MotivationCard displays motivation notes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MotivationCard(
            motivationNotes: 'Build consistent momentum\nStay focused',
            accentColor: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.text('Motivation'), findsOneWidget);
    expect(find.text('Build consistent momentum'), findsOneWidget);
    expect(find.text('Stay focused'), findsOneWidget);
  });

  testWidgets('HabitMonthlyCalendar renders month header, day cells, and metrics strip',
      (tester) async {
    DateTime? clickedDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HabitMonthlyCalendar(
              habit: numericHabit,
              logs: const [],
              currentMonth: DateTime(2026, 8, 1),
              selectedDate: DateTime(2026, 8, 18),
              accentColor: Colors.purple,
              onPreviousMonth: () {},
              onNextMonth: () {},
              onDateClick: (d) => clickedDate = d,
            ),
          ),
        ),
      ),
    );

    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('S'), findsNWidgets(2)); // Sun & Sat
    expect(find.text('M'), findsOneWidget);
    expect(find.text('Rate'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Best Streak'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);

    // Tap day 18
    await tester.tap(find.text('18'));
    await tester.pump();
    expect(clickedDate, DateTime(2026, 8, 18));
  });

  testWidgets('CircularFocusTimer renders controls and time display',
      (tester) async {
    TimerStateHolder.stop();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CircularFocusTimer(
              habitId: 'habit-timer',
              habitTitle: 'Deep Coding',
              defaultDurationMinutes: 25.0,
              accentColor: Colors.green,
              onFocusScreenClick: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Focus Timer'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('25m Goal'), findsOneWidget);
  });

  testWidgets('FocusTimerScreen renders distraction-free timer with play/pause',
      (tester) async {
    TimerStateHolder.stop();

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FocusTimerScreen(
            habitId: 'habit-timer',
            onBack: _noop,
          ),
        ),
      ),
    );

    expect(find.text('Focus Timer'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('HabitDetailScreen renders complete hero, stats, 10-dot, reminders, calendar',
      (tester) async {
    final fakeRepo = FakeHabitRepository(
      initialHabits: [numericHabit],
      initialCategories: [testCategory],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: HabitDetailScreen(
            habitId: 'habit-num',
            onBack: _noop,
            onNavigateToFocusScreen: (_) {},
          ),
        ),
      ),
    );

    // Initial pump & state settlement
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Daily Pages'), findsWidgets);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('10-Dot Progress'), findsOneWidget);
    expect(find.text('Scheduled Reminders'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('Motivation'), findsOneWidget);
    expect(find.text('Reading makes you wiser'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}

void _noop() {}
