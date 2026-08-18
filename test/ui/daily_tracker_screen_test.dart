import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/daily/controllers/daily_tracker_controller.dart';
import 'package:habit_tracker/ui/daily/daily_tracker_screen.dart';
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
}
