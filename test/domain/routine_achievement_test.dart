import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/gamification/achievement_evaluator.dart';
import 'package:habit_tracker/domain/models/habit_routine.dart';
import 'package:habit_tracker/domain/models/routine_log.dart';

void main() {
  test('AchievementEvaluator unlocks routine_1 and routine_5 when completed', () {
    final now = DateTime.utc(2026, 8, 21);
    final refDate = DateTime.utc(2026, 8, 21);

    final routineLogs = List.generate(5, (index) {
      return RoutineLog(
        id: 'rlog_$index',
        routineId: 'routine_1',
        date: '2026-08-${17 + index}',
        completedAt: now,
        completedHabitIds: const ['h1', 'h2'],
        xpEarned: 30,
        createdAt: now,
        updatedAt: now,
      );
    });

    final results = AchievementEvaluator.evaluateAll(
      EvaluationContext(
        habits: const [],
        allLogs: const [],
        categories: const [],
        routines: [
          HabitRoutine(
            id: 'routine_1',
            title: 'Morning Flow',
            color: '#3B82F6',
            habitIds: const ['h1', 'h2'],
            createdAt: now,
            updatedAt: now,
          ),
        ],
        routineLogs: routineLogs,
        currentLevel: 1,
        referenceDate: refDate,
      ),
    );

    final r1 = results.firstWhere((a) => a.definition.id == 'routine_1');
    expect(r1.isUnlocked, isTrue);
    expect(r1.currentProgress, 1);

    final r5 = results.firstWhere((a) => a.definition.id == 'routine_5');
    expect(r5.isUnlocked, isTrue);
    expect(r5.currentProgress, 5);

    final r25 = results.firstWhere((a) => a.definition.id == 'routine_25');
    expect(r25.isUnlocked, isFalse);
    expect(r25.currentProgress, 5);
  });
}
