import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/reflection/reflection_bottom_sheet.dart';

void main() {
  testWidgets('ReflectionBottomSheet renders energy rating, mood chips, and micro-note',
      (tester) async {
    final now = DateTime(2026, 8, 18);
    final habit = Habit(
      id: 'h-ui-1',
      title: 'Workout',
      color: '#4CAF50',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReflectionBottomSheet(
              habit: habit,
              date: now,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Check-In Reflection'), findsOneWidget);
    expect(find.textContaining('Workout'), findsOneWidget);

    // Verify Energy Level and labels
    expect(find.text('Energy Level'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Peak'), findsOneWidget);

    // Verify Mood Tag
    expect(find.text('Mood Tag'), findsOneWidget);
    expect(find.text('Energized'), findsOneWidget);
    expect(find.text('Happy'), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);

    // Verify Micro-Note input and Action buttons
    expect(find.text('Micro-Note'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Save Reflection'), findsOneWidget);

    // Tap Energy Level 5
    await tester.tap(find.text('Peak'));
    await tester.pumpAndSettle();

    // Tap Mood Chip
    await tester.tap(find.text('Energized'));
    await tester.pumpAndSettle();

    // Enter micro-note text
    await tester.enterText(find.byType(TextField), 'Felt strong throughout');
    await tester.pumpAndSettle();

    expect(find.text('Felt strong throughout'), findsOneWidget);
  });
}
