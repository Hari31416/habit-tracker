import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/di/providers.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/ui/form/habit_form_bottom_sheet.dart';
import 'package:habit_tracker/ui/theme/app_theme.dart';
import 'daily_tracker_controller_test.dart';

void main() {
  testWidgets('HabitFormBottomSheet renders and saves new habit',
      (WidgetTester tester) async {
    const testCat = HabitCategory(
      id: 'cat-mind',
      name: 'Mindfulness',
      color: '#8B5CF6',
      icon: 'brain',
    );

    final fakeRepo = FakeHabitRepository(
      initialCategories: [testCat],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => HabitFormBottomSheet.show(context),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('New Habit'), findsOneWidget);
    expect(find.text('Mindfulness'), findsOneWidget);
    expect(find.text('Accent Color'), findsOneWidget);
    expect(find.text('Target Type'), findsOneWidget);
    expect(find.text('Frequency'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);

    // Enter title
    await tester.enterText(
      find.widgetWithText(TextField, 'Habit Title *'),
      'Deep Meditation',
    );

    // Tap 'Mindfulness' category chip
    await tester.tap(find.text('Mindfulness'));
    await tester.pump();

    // Scroll to 'Morning (08:00)' reminder chip and tap
    await tester.ensureVisible(find.text('Morning (08:00)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Morning (08:00)'));
    await tester.pump();

    // Scroll to and tap 'Create Habit' button
    await tester.ensureVisible(find.text('Create Habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Habit'));
    await tester.pumpAndSettle();

    // Verify habit was created in repo
    final habits = await fakeRepo.getAllActiveHabitsOnce();
    expect(habits.length, 1);
    expect(habits.first.title, 'Deep Meditation');
    expect(habits.first.categoryId, 'cat-mind');
    expect(habits.first.reminderTimes, ['08:00']);
    expect(habits.first.promptReflection, isFalse);
  });

  testWidgets('HabitFormBottomSheet toggles reflection on check-in setting',
      (WidgetTester tester) async {
    final fakeRepo = FakeHabitRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => HabitFormBottomSheet.show(context),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Habit Title *'),
      'Evening Journal',
    );

    // Drag sheet upwards to reveal reflection switch and create button
    await tester.drag(find.byType(HabitFormBottomSheet), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Reflection on Check-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reflection on Check-in'));
    await tester.pumpAndSettle();

    // Scroll to and tap 'Create Habit' button
    await tester.ensureVisible(find.text('Create Habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Habit'));
    await tester.pumpAndSettle();

    final habits = await fakeRepo.getAllActiveHabitsOnce();
    expect(habits.length, 1);
    expect(habits.first.title, 'Evening Journal');
    expect(habits.first.promptReflection, isTrue);
  });
}
