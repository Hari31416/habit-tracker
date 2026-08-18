import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/domain/models/habit_with_progress.dart';
import 'package:habit_tracker/ui/daily/widgets/habit_card.dart';
import 'package:habit_tracker/ui/daily/widgets/historical_banner.dart';
import 'package:habit_tracker/ui/daily/widgets/quick_add_bar.dart';
import 'package:habit_tracker/ui/daily/widgets/rolling_week_strip.dart';
import 'package:habit_tracker/ui/navigation/habit_bottom_navigation.dart';
import 'package:habit_tracker/ui/navigation/screen.dart';
import 'package:habit_tracker/ui/theme/app_theme.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('HistoricalBanner', () {
    testWidgets('Hidden when selected date is today', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          HistoricalBanner(
            selectedDate: DateTime.now(),
            onReturnToToday: () {},
          ),
        ),
      );

      expect(find.byType(HistoricalBanner), findsOneWidget);
      expect(find.text('Return to Today'), findsNothing);
    });

    testWidgets('Visible when selected date is past and triggers callback',
        (tester) async {
      var returnedToToday = false;
      final pastDate = DateTime.now().subtract(const Duration(days: 5));

      await tester.pumpWidget(
        createTestWidget(
          HistoricalBanner(
            selectedDate: pastDate,
            onReturnToToday: () => returnedToToday = true,
          ),
        ),
      );

      expect(find.text('Return to Today'), findsOneWidget);
      expect(find.textContaining('Viewing Past:'), findsOneWidget);

      await tester.tap(find.text('Return to Today'));
      expect(returnedToToday, isTrue);
    });
  });

  group('RollingWeekStrip', () {
    testWidgets('Renders 7 days centered on selected date', (tester) async {
      final now = DateTime.now();
      var selectedDate = now;

      await tester.pumpWidget(
        createTestWidget(
          RollingWeekStrip(
            selectedDate: selectedDate,
            weekLogs: const {},
            onDateSelected: (d) => selectedDate = d,
            onPreviousDay: () {},
            onNextDay: () {},
            onTodayClick: () {},
          ),
        ),
      );

      // Should render 7 day items
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      // Day numbers present
      expect(find.text(now.day.toString()), findsWidgets);
    });
  });

  group('QuickAddBar', () {
    testWidgets('Submits text on done keyboard action and triggers callback',
        (tester) async {
      String? addedText;
      var openedFullForm = false;

      await tester.pumpWidget(
        createTestWidget(
          QuickAddBar(
            onQuickAdd: (text) => addedText = text,
            onOpenFullForm: () => openedFullForm = true,
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Stretch 15m');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(addedText, 'Stretch 15m');

      await tester.tap(find.byIcon(Icons.tune));
      expect(openedFullForm, isTrue);
    });
  });

  group('HabitCard', () {
    final habit = Habit(
      id: 'h-100',
      title: 'Morning Yoga',
      description: 'Morning flexibility routine',
      color: '#10B981',
      icon: 'heart',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      pinned: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    const category = HabitCategory(
      id: 'c-1',
      name: 'Wellness',
      color: '#10B981',
      icon: 'heart',
    );

    testWidgets('Renders title, pin indicator, category, and streak pill',
        (tester) async {
      final habitWithProgress = HabitWithProgress(
        habit: habit,
        category: category,
        streak: const StreakResult(
          currentStreak: 5,
          bestStreak: 10,
          completionRate30Days: 80,
          totalCompletions: 25,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          HabitCard(
            habitWithProgress: habitWithProgress,
            onHabitClick: (_) {},
            onToggleCheckIn: () {},
          ),
        ),
      );

      expect(find.text('Morning Yoga'), findsOneWidget);
      expect(find.text('Wellness'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.text('5 d streak'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);

      // Verify no archive or delete icons on habit card
      expect(find.byIcon(Icons.archive), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('Check-in button tap triggers check-in callback',
        (tester) async {
      var checkInToggled = false;
      var cardClickedId = '';

      final habitWithProgress = HabitWithProgress(
        habit: habit,
        category: category,
        isCompletedOnDate: false,
      );

      await tester.pumpWidget(
        createTestWidget(
          HabitCard(
            habitWithProgress: habitWithProgress,
            onHabitClick: (id) => cardClickedId = id,
            onToggleCheckIn: () => checkInToggled = true,
          ),
        ),
      );

      // Tap card body -> onHabitClick
      await tester.tap(find.text('Morning Yoga'));
      expect(cardClickedId, 'h-100');

      // Tap checkmark circle -> onToggleCheckIn
      await tester.tap(find.byType(InkWell).last);
      expect(checkInToggled, isTrue);
    });
  });

  group('HabitBottomNavigation', () {
    testWidgets('Renders all navigation destinations and center add button',
        (tester) async {
      var navigatedRoute = '';
      var addClicked = false;

      await tester.pumpWidget(
        createTestWidget(
          HabitBottomNavigation(
            currentRoute: Screen.daily,
            onNavigate: (route) => navigatedRoute = route,
            onAddHabitClick: () => addClicked = true,
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Mastery'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.text('Week'));
      expect(navigatedRoute, Screen.matrix);

      await tester.tap(find.byIcon(Icons.add));
      expect(addClicked, isTrue);
    });
  });
}
