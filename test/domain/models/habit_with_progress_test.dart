import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/streak_calculator.dart';
import 'package:habit_tracker/domain/models/habit_tier.dart';
import 'package:habit_tracker/domain/models/habit_with_progress.dart';
import '../../helpers/test_factories.dart';

void main() {
  group('HabitWithProgress', () {
    final habit = createTestHabit(
      id: 'test_habit_1',
      title: 'Daily Exercise',
      icon: 'fitness',
    );

    test('tier helper properties evaluate correctly', () {
      final noneProgress = HabitWithProgress(habit: habit, achievedTier: HabitTier.none);
      expect(noneProgress.isMiniAchieved, isFalse);
      expect(noneProgress.isBaseAchieved, isFalse);
      expect(noneProgress.isEliteAchieved, isFalse);

      final miniProgress = HabitWithProgress(habit: habit, achievedTier: HabitTier.mini);
      expect(miniProgress.isMiniAchieved, isTrue);
      expect(miniProgress.isBaseAchieved, isFalse);
      expect(miniProgress.isEliteAchieved, isFalse);

      final baseProgress = HabitWithProgress(habit: habit, achievedTier: HabitTier.base);
      expect(baseProgress.isMiniAchieved, isTrue);
      expect(baseProgress.isBaseAchieved, isTrue);
      expect(baseProgress.isEliteAchieved, isFalse);

      final eliteProgress = HabitWithProgress(habit: habit, achievedTier: HabitTier.elite);
      expect(eliteProgress.isMiniAchieved, isTrue);
      expect(eliteProgress.isBaseAchieved, isTrue);
      expect(eliteProgress.isEliteAchieved, isTrue);
    });

    test('copyWith and value equality work accurately', () {
      final progress = HabitWithProgress(
        habit: habit,
        isCompletedOnDate: true,
        currentValueOnDate: 10.0,
        achievedTier: HabitTier.base,
        streak: const StreakResult(
          currentStreak: 5,
          bestStreak: 10,
          completionRate30Days: 80,
          totalCompletions: 25,
        ),
      );

      final copy = progress.copyWith(currentValueOnDate: 15.0);
      expect(copy.currentValueOnDate, 15.0);
      expect(copy.isCompletedOnDate, isTrue);
      expect(copy.streak.currentStreak, 5);

      final identicalCopy = progress.copyWith();
      expect(identicalCopy, equals(progress));
      expect(identicalCopy.hashCode, equals(progress.hashCode));
    });
  });
}
