import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/daily/controllers/daily_tracker_controller.dart';
import 'package:habit_tracker/ui/daily/daily_tracker_screen.dart';
import 'package:habit_tracker/ui/daily/widgets/habit_card.dart';
import 'package:habit_tracker/ui/navigation/habit_bottom_navigation.dart';
import 'package:habit_tracker/ui/theme/app_theme.dart';
import 'daily_tracker_controller_test.dart';

void main() {
  testWidgets(
      'DailyTrackerScreen renders with progress card and category chips',
      (WidgetTester tester) async {
    const cat = HabitCategory(
      id: 'cat-1',
      name: 'Health',
      color: '#10B981',
      icon: 'heart',
    );

    final habit = Habit(
      id: 'h-1',
      title: 'Daily Walk',
      description: 'Walk 5000 steps',
      color: '#10B981',
      icon: 'walk',
      categoryId: 'cat-1',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final fakeRepo = FakeHabitRepository(
      initialHabits: [habit],
      initialCategories: [cat],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyTrackerControllerProvider.overrideWith(
            (ref) => DailyTrackerController(fakeRepo),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DailyTrackerScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("Today's Progress"), findsOneWidget);
    expect(find.text('Daily Walk'), findsOneWidget);
    expect(find.text('Health'), findsWidgets);
    expect(find.byType(HabitBottomNavigation), findsOneWidget);
  });

  testWidgets('DailyTrackerScreen shows SnackBar with Reflect action only for opt-in habits',
      (WidgetTester tester) async {
    final habitWithReflection = Habit(
      id: 'h-reflect',
      title: 'Mindful Meditation',
      color: '#10B981',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      promptReflection: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final fakeRepo = FakeHabitRepository(
      initialHabits: [habitWithReflection],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyTrackerControllerProvider.overrideWith(
            (ref) => DailyTrackerController(fakeRepo),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DailyTrackerScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Tap check in on the habit card
    await tester.tap(
      find.descendant(
        of: find.byType(HabitCard),
        matching: find.byType(AnimatedContainer),
      ).first,
    );
    await tester.pumpAndSettle();

    // Verify floating toast with Reflect action is shown
    expect(find.text('Completed "Mindful Meditation"'), findsOneWidget);
    expect(find.text('Reflect'), findsOneWidget);

    // Advance time by 2.6 seconds to trigger auto-fadeout
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    // Verify reflection toast automatically dismissed
    expect(find.text('Completed "Mindful Meditation"'), findsNothing);
    expect(find.text('Reflect'), findsNothing);
  });

  testWidgets('DailyTrackerScreen empty state provides Create Habit and Load Demo Habits actions',
      (WidgetTester tester) async {
    final fakeRepo = FakeHabitRepository(
      initialHabits: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyTrackerControllerProvider.overrideWith(
            (ref) => DailyTrackerController(fakeRepo),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DailyTrackerScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No habits scheduled for this day'), findsOneWidget);
    expect(find.text('Create Habit'), findsOneWidget);
    expect(find.text('Load Demo Habits'), findsOneWidget);

    // Tap Load Demo Habits button
    await tester.tap(find.text('Load Demo Habits'));
    await tester.pumpAndSettle();

    // Verify demo habit is now rendered
    expect(find.text('Demo Habit'), findsOneWidget);
  });
}
