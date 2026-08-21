// UI golden snapshots (light theme).
//
// Regenerate after intentional visual changes:
//   flutter test test/ui/ui_goldens_test.dart --update-goldens
//
// Goldens live under test/goldens/ui/. CI pins Flutter to the version used
// when these were generated (see .github/workflows/ci.yml).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/common/previews/preview_fixtures.dart';
import 'package:habit_tracker/ui/daily/widgets/habit_card.dart';
import 'package:habit_tracker/ui/matrix/controllers/week_matrix_controller.dart';
import 'package:habit_tracker/ui/matrix/widgets/week_matrix_grid.dart';
import 'package:habit_tracker/ui/navigation/habit_bottom_navigation.dart';
import 'package:habit_tracker/ui/navigation/screen.dart';
import 'package:habit_tracker/ui/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child, {Size size = const Size(390, 200)}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
          body: Center(
            child: SizedBox(
              width: size.width,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpGolden(
    WidgetTester tester, {
    required Widget widget,
    required String goldenName,
    Size size = const Size(390, 200),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrap(widget, size: size));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/ui/$goldenName.png'),
    );
  }

  testWidgets('HabitCard boolean incomplete (light)', (tester) async {
    await pumpGolden(
      tester,
      goldenName: 'habit_card_boolean_incomplete',
      widget: HabitCard(
        habitWithProgress: PreviewFixtures.sampleHabitWithProgress(
          habit: PreviewFixtures.sampleHabit(
            id: 'golden-bool',
            title: 'Morning Meditation',
            targetType: HabitTargetType.boolean,
          ),
          isCompleted: false,
          currentStreak: 5,
        ),
        onHabitClick: (_) {},
        onToggleCheckIn: () {},
      ),
    );
  });

  testWidgets('HabitCard boolean complete (light)', (tester) async {
    await pumpGolden(
      tester,
      goldenName: 'habit_card_boolean_complete',
      widget: HabitCard(
        habitWithProgress: PreviewFixtures.sampleHabitWithProgress(
          habit: PreviewFixtures.sampleHabit(
            id: 'golden-bool',
            title: 'Morning Meditation',
            targetType: HabitTargetType.boolean,
          ),
          isCompleted: true,
          currentStreak: 5,
        ),
        onHabitClick: (_) {},
        onToggleCheckIn: () {},
      ),
    );
  });

  testWidgets('HabitCard numeric elastic tiers (light)', (tester) async {
    await pumpGolden(
      tester,
      size: const Size(390, 260),
      goldenName: 'habit_card_numeric_elastic',
      widget: HabitCard(
        habitWithProgress: PreviewFixtures.sampleHabitWithProgress(
          habit: PreviewFixtures.sampleHabitWithElasticTiers(
            id: 'golden-elastic',
            title: 'Read Book',
          ),
          currentValue: 12.0,
          isCompleted: false,
          currentStreak: 3,
        ),
        onHabitClick: (_) {},
        onToggleCheckIn: () {},
        onSelectTier: (_) {},
        onValueChange: (_) {},
        onDeltaAdd: (_) {},
      ),
    );
  });

  testWidgets('WeekMatrixGrid slice (light)', (tester) async {
    final habit = Habit(
      id: 'golden-matrix',
      title: 'Morning Yoga',
      color: '#10B981',
      icon: 'self_improvement',
      frequencyType: HabitFrequencyType.daily,
      targetType: HabitTargetType.boolean,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 8, 17),
    );
    final cells = List.generate(
      7,
      (i) => MatrixCell(
        date: DateTime(2026, 8, 17 + i),
        status: i == 0
            ? MatrixCellStatus.completed
            : i == 2
                ? MatrixCellStatus.shielded
                : MatrixCellStatus.scheduledIncomplete,
        isToday: i == 1,
      ),
    );

    await pumpGolden(
      tester,
      size: const Size(390, 180),
      goldenName: 'week_matrix_grid_slice',
      widget: WeekMatrixGrid(
        rows: [
          MatrixRow(
            habit: habit,
            cells: cells,
            completedCountThisWeek: 1,
            targetCountThisWeek: 7,
          ),
        ],
        onToggleCell: (_, __) {},
        onHabitClick: (_) {},
      ),
    );
  });

  testWidgets('HabitBottomNavigation (light)', (tester) async {
    await pumpGolden(
      tester,
      size: const Size(390, 96),
      goldenName: 'habit_bottom_navigation',
      widget: HabitBottomNavigation(
        currentRoute: Screen.daily,
        onNavigate: (_) {},
        onAddHabitClick: () {},
      ),
    );
  });
}
