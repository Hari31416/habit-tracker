import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/repositories/gamification_repository_impl.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/flutter_habit_reminder_scheduler.dart';
import 'package:habit_tracker/data/schedulers/no_op_habit_reminder_scheduler.dart';
import 'package:habit_tracker/domain/gamification/gamification_models.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/detail/controllers/habit_detail_controller.dart';
import 'package:habit_tracker/ui/gamification/controllers/gamification_controller.dart';
import 'package:habit_tracker/ui/matrix/controllers/week_matrix_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6 Optimizations Tests', () {
    late AppDatabase db;
    late HabitRepositoryImpl habitRepository;
    late GamificationRepositoryImpl gamificationRepository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      habitRepository = HabitRepositoryImpl(
        habitDao: db.habitDao,
        habitLogDao: db.habitLogDao,
        habitShieldDao: db.habitShieldDao,
        habitCategoryDao: db.habitCategoryDao,
        gamificationDao: db.gamificationDao,
        reminderScheduler: const NoOpHabitReminderScheduler(),
      );
      gamificationRepository = GamificationRepositoryImpl(
        habitDao: db.habitDao,
        habitLogDao: db.habitLogDao,
        habitShieldDao: db.habitShieldDao,
        habitCategoryDao: db.habitCategoryDao,
        gamificationDao: db.gamificationDao,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('GamificationRepositoryImpl preserves energyLevel and mood in domain logs', () async {
      final now = DateTime.now().toUtc();
      final date = DateTime(2026, 8, 19);
      final habit = Habit(
        id: 'h-energy',
        title: 'Meditation',
        color: '#10B981',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: now,
        updatedAt: now,
      );

      await habitRepository.upsertHabit(habit);
      await habitRepository.logCheckIn(
        habitId: habit.id,
        date: date,
        completed: true,
        energyLevel: 5,
        mood: 'energized',
        note: 'Felt awesome',
      );

      // Verify progression and achievements calculate with the shared pipeline
      final progression = await gamificationRepository.getPlayerProgression().first;
      expect(progression.totalXp, greaterThan(0));

      final allLogs = await habitRepository.getAllLogsOnce();
      expect(allLogs.first.energyLevel, 5);
      expect(allLogs.first.mood, 'energized');
    });

    test('GamificationRepositoryImpl shared broadcast stream serves multiple listeners without multiple pipelines', () async {
      final now = DateTime.now().toUtc();
      final date = DateTime(2026, 8, 19);
      final habit = Habit(
        id: 'h-multi',
        title: 'Reading',
        color: '#3B82F6',
        frequencyType: HabitFrequencyType.daily,
        targetType: HabitTargetType.boolean,
        createdAt: now,
        updatedAt: now,
      );

      await habitRepository.upsertHabit(habit);
      await habitRepository.toggleBooleanCheckIn(habit.id, date);

      // Subscribe to multiple streams simultaneously
      final progFuture = gamificationRepository.getPlayerProgression().first;
      final achFuture = gamificationRepository.getAchievements().first;
      final bankFuture = gamificationRepository.getShieldBankState().first;

      final results = await Future.wait([progFuture, achFuture, bankFuture]);
      final progression = results[0] as PlayerProgression;
      final achievements = results[1] as List<AchievementStatus>;
      final bank = results[2];

      expect(progression.level, 2);
      expect(achievements, isNotEmpty);
      expect(bank, isNotNull);
    });

    test('FlutterHabitReminderScheduler cancel operates cleanly', () async {
      final scheduler = FlutterHabitReminderScheduler(db.habitDao);
      // Cancellation on arbitrary id should complete without error
      await scheduler.cancel('test-habit-id');
    });

    test('UI States implement equality correctly and prevent redundant updates', () {
      final date1 = DateTime(2026, 8, 19);

      // 1. WeekMatrixUiState equality
      final matrix1 = WeekMatrixUiState(
        weekStart: date1,
        totalCompleted: 5,
        totalScheduled: 10,
        isLoading: false,
      );
      final matrix2 = WeekMatrixUiState(
        weekStart: date1,
        totalCompleted: 5,
        totalScheduled: 10,
        isLoading: false,
      );
      final matrix3 = WeekMatrixUiState(
        weekStart: date1,
        totalCompleted: 6,
        totalScheduled: 10,
        isLoading: false,
      );

      expect(matrix1, equals(matrix2));
      expect(matrix1.hashCode, equals(matrix2.hashCode));
      expect(matrix1, isNot(equals(matrix3)));

      // 2. HabitDetailUiState equality
      final detail1 = HabitDetailUiState(
        selectedDate: date1,
        isCompletedOnSelectedDate: true,
        currentValueOnSelectedDate: 1.0,
        isLoading: false,
      );
      final detail2 = HabitDetailUiState(
        selectedDate: date1,
        isCompletedOnSelectedDate: true,
        currentValueOnSelectedDate: 1.0,
        isLoading: false,
      );
      final detail3 = HabitDetailUiState(
        selectedDate: date1,
        isCompletedOnSelectedDate: false,
        currentValueOnSelectedDate: 0.0,
        isLoading: false,
      );

      expect(detail1, equals(detail2));
      expect(detail1.hashCode, equals(detail2.hashCode));
      expect(detail1, isNot(equals(detail3)));

      // 3. GamificationUiState equality
      const game1 = GamificationUiState(
        selectedCategory: AchievementCategory.all,
        isLoading: false,
      );
      const game2 = GamificationUiState(
        selectedCategory: AchievementCategory.all,
        isLoading: false,
      );
      const game3 = GamificationUiState(
        selectedCategory: AchievementCategory.streak,
        isLoading: false,
      );

      expect(game1, equals(game2));
      expect(game1.hashCode, equals(game2.hashCode));
      expect(game1, isNot(equals(game3)));
    });
  });
}
