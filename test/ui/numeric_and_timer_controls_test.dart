import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/preferences/theme_preferences.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/time_window.dart';
import 'package:habit_tracker/ui/daily/dialogs/direct_numeric_input_dialog.dart';
import 'package:habit_tracker/ui/daily/widgets/numeric_habit_controls.dart';
import 'package:habit_tracker/ui/daily/widgets/slot_habit_controls.dart';
import 'package:habit_tracker/ui/daily/widgets/timer_habit_controls.dart';
import 'package:habit_tracker/ui/detail/focus_timer_screen.dart';
import 'package:habit_tracker/ui/detail/widgets/circular_focus_timer.dart';
import 'package:habit_tracker/ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DirectNumericInputDialog', () {
    testWidgets('Renders with target label and submits entered number',
        (WidgetTester tester) async {
      double? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DirectNumericInputDialog(
              habitTitle: 'Drink Water',
              currentValue: 1250,
              targetValue: 2000,
              unit: 'ml',
              onDismiss: () {},
              onConfirm: (val) {
                submittedValue = val;
              },
            ),
          ),
        ),
      );

      expect(find.text('Log Drink Water'), findsOneWidget);
      expect(find.text('Target: 2000 ml'), findsOneWidget);
      expect(find.text('1250'), findsOneWidget);

      // Enter new number
      await tester.enterText(find.byType(TextField), '1750');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(submittedValue, 1750.0);
    });
  });

  group('NumericHabitControls', () {
    testWidgets('Renders progress, stepper buttons, and quick add chips',
        (WidgetTester tester) async {
      final habit = Habit(
        id: 'h-numeric',
        title: 'Drink Water',
        color: '#10B981',
        targetType: HabitTargetType.numeric,
        targetValue: 2000,
        unit: 'ml',
        frequencyType: HabitFrequencyType.daily,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      double? deltaAdded;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: NumericHabitControls(
              habit: habit,
              currentValue: 500,
              isCompleted: false,
              accentColor: const Color(0xFF10B981),
              onValueChange: (_) {},
              onDeltaAdd: (delta) {
                deltaAdded = delta;
              },
            ),
          ),
        ),
      );

      expect(find.text('500'), findsOneWidget);
      expect(find.textContaining('2,000 ml'), findsOneWidget);

      // Tap '+' primary step (+250 for ml)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(deltaAdded, 250.0);

      // Tap Quick Add '+500' chip
      await tester.tap(find.text('+500'));
      await tester.pump();
      expect(deltaAdded, 500.0);
    });
  });

  group('TimerHabitControls', () {
    testWidgets('Renders elapsed duration, Focus button, and +Xm chips',
        (WidgetTester tester) async {
      final habit = Habit(
        id: 'h-timer',
        title: 'Meditation',
        color: '#3B82F6',
        targetType: HabitTargetType.timer,
        targetValue: 30,
        frequencyType: HabitFrequencyType.daily,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool focusClicked = false;
      double? deltaMins;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TimerHabitControls(
              habit: habit,
              currentMinutes: 10,
              isCompleted: false,
              accentColor: const Color(0xFF3B82F6),
              onDeltaAddMinutes: (d) {
                deltaMins = d;
              },
              onStartFocus: () {
                focusClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
      expect(find.textContaining('30 mins'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);

      await tester.tap(find.text('Focus'));
      await tester.pump();
      expect(focusClicked, isTrue);

      await tester.tap(find.text('+15m'));
      await tester.pump();
      expect(deltaMins, 15.0);
    });
  });

  group('SlotHabitControls', () {
    testWidgets('Renders interval slots and handles slot completion toggle',
        (WidgetTester tester) async {
      final habit = Habit(
        id: 'h-slots',
        title: 'Drink Water Schedule',
        color: '#10B981',
        targetType: HabitTargetType.boolean,
        frequencyType: HabitFrequencyType.subdayInterval,
        intervalHours: 3,
        timeWindow: const TimeWindow(startTime: '09:00', endTime: '18:00'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Slot 0 logged, Slot 1 unlogged
      final logs = [
        HabitLog(
          id: 'log-1',
          habitId: 'h-slots',
          date: '2026-08-17',
          completed: true,
          intervalIndex: 0,
          timestamp: DateTime(2026, 8, 17, 9, 0),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      int? toggledSlot;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SlotHabitControls(
              habit: habit,
              logsForDate: logs,
              accentColor: const Color(0xFF10B981),
              onToggleSlot: (slotIdx) {
                toggledSlot = slotIdx;
              },
            ),
          ),
        ),
      );

      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);

      // Tap slot index 1 (12:00)
      await tester.tap(find.text('12:00'));
      await tester.pump();
      expect(toggledSlot, 1);
    });
  });

  group('CircularFocusTimer and FocusTimerScreen DND Toggle', () {
    testWidgets('CircularFocusTimer renders DND toggle chip and reflects state',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'key_focus_dnd_enabled': false});
      final prefs = await SharedPreferences.getInstance();
      final themePrefs = ThemePreferences(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themePreferencesProvider.overrideWithValue(themePrefs),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CircularFocusTimer(
                habitId: 'h-timer',
                habitTitle: 'Meditation',
                defaultDurationMinutes: 25,
                accentColor: const Color(0xFF3B82F6),
                onFocusScreenClick: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('DND Off'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);

      await tester.tap(find.text('DND Off'));
      await tester.pumpAndSettle();

      expect(find.text('DND On (Standby)'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off), findsOneWidget);
    });

    testWidgets('FocusTimerScreen renders DND toggle chip and reflects state',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'key_focus_dnd_enabled': true});
      final prefs = await SharedPreferences.getInstance();
      final themePrefs = ThemePreferences(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themePreferencesProvider.overrideWithValue(themePrefs),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: FocusTimerScreen(
                habitId: 'h-timer',
                onBack: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('DND On (Standby)'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off), findsOneWidget);

      await tester.tap(find.text('DND On (Standby)'));
      await tester.pumpAndSettle();

      expect(find.text('DND Off'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });
  });
}
