import 'dart:async';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../domain/engines/shield_banking_engine.dart';
import '../../domain/engines/streak_calculator.dart';
import '../../domain/gamification/achievement_evaluator.dart';
import '../../domain/gamification/gamification_engine.dart';
import '../../domain/gamification/gamification_models.dart';
import '../../domain/gamification/player_title.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_category.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/models/habit_shield.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../local/app_database.dart';
import '../local/daos/gamification_dao.dart';
import '../local/daos/habit_category_dao.dart';
import '../local/daos/habit_dao.dart';
import '../local/daos/habit_log_dao.dart';
import '../local/daos/habit_shield_dao.dart';

class _CombinedGamificationData {
  final PlayerProgression progression;
  final List<AchievementStatus> achievements;
  final ShieldBankState shieldBank;
  final LevelUpCelebration? celebration;

  const _CombinedGamificationData({
    required this.progression,
    required this.achievements,
    required this.shieldBank,
    this.celebration,
  });
}

class GamificationRepositoryImpl implements GamificationRepository {
  final HabitDao habitDao;
  final HabitLogDao habitLogDao;
  final HabitShieldDao habitShieldDao;
  final HabitCategoryDao habitCategoryDao;
  final GamificationDao gamificationDao;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  GamificationRepositoryImpl({
    required this.habitDao,
    required this.habitLogDao,
    required this.habitShieldDao,
    required this.habitCategoryDao,
    required this.gamificationDao,
  });

  Habit _habitRowToDomain(HabitRow row) => Habit(
        id: row.id,
        title: row.title,
        description: row.description,
        color: row.color,
        icon: row.icon,
        categoryId: row.categoryId,
        frequencyType: row.frequencyType,
        targetDaysOfWeek: row.targetDaysOfWeek,
        targetCountPerWeek: row.targetCountPerWeek,
        intervalHours: row.intervalHours,
        timesPerDay: row.timesPerDay,
        timeWindow: row.timeWindow,
        targetType: row.targetType,
        targetValue: row.targetValue,
        unit: row.unit,
        pinned: row.pinned,
        reminderTimes: row.reminderTimes,
        motivationNotes: row.motivationNotes,
        archived: row.archived,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  HabitLog _logRowToDomain(HabitLogRow row) => HabitLog(
        id: row.id,
        habitId: row.habitId,
        date: row.date,
        timestamp: row.timestamp,
        intervalIndex: row.intervalIndex,
        completed: row.completed,
        value: row.value,
        durationSeconds: row.durationSeconds,
        note: row.note,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  HabitShield _shieldRowToDomain(HabitShieldRow row) => HabitShield(
        id: row.id,
        habitId: row.habitId,
        date: row.date,
        autoApplied: row.autoApplied,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  HabitCategory _categoryRowToDomain(HabitCategoryRow row) => HabitCategory(
        id: row.id,
        name: row.name,
        color: row.color,
        icon: row.icon,
      );

  Stream<_CombinedGamificationData> _buildGamificationStream() {
    late StreamController<_CombinedGamificationData> controller;

    List<HabitRow>? latestHabits;
    List<HabitLogRow>? latestLogs;
    List<HabitShieldRow>? latestShields;
    List<HabitCategoryRow>? latestCategories;
    List<AchievementRow>? latestAchievements;
    UserGamificationRow? latestUserGamification;
    var hasUserGamificationEmitted = false;

    StreamSubscription? subHabits;
    StreamSubscription? subLogs;
    StreamSubscription? subShields;
    StreamSubscription? subCategories;
    StreamSubscription? subAchievements;
    StreamSubscription? subUserGamification;

    void evaluateAndEmit() {
      if (latestHabits == null ||
          latestLogs == null ||
          latestShields == null ||
          latestCategories == null ||
          latestAchievements == null ||
          !hasUserGamificationEmitted) {
        return;
      }

      final habits = latestHabits!.map(_habitRowToDomain).toList();
      final logs = latestLogs!.map(_logRowToDomain).toList();
      final shields = latestShields!.map(_shieldRowToDomain).toList();
      final categories = latestCategories!.map(_categoryRowToDomain).toList();
      final storedMap = {
        for (var a in latestAchievements!) a.id: a.unlockedAt
      };

      final logsByHabit = <String, List<HabitLog>>{};
      final logsByDate = <String, List<HabitLog>>{};
      for (final log in logs) {
        logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
        logsByDate.putIfAbsent(log.date, () => []).add(log);
      }

      final shieldsByHabit = <String, List<HabitShield>>{};
      for (final shield in shields) {
        shieldsByHabit.putIfAbsent(shield.habitId, () => []).add(shield);
      }

      final today = DateTime.now();

      // 1. Calculate streaks per habit to find multipliers
      var longestStreak = 0;
      for (final habit in habits) {
        final habitLogs = logsByHabit[habit.id] ?? const [];
        final habitShields = shieldsByHabit[habit.id] ?? const [];
        final streak = StreakCalculator.calculateStreak(
          habit,
          habitLogs,
          today,
          habitShields,
        );
        longestStreak = max(longestStreak, max(streak.currentStreak, streak.bestStreak));
      }

      // 2. Calculate Base Habit Check-in XP
      var habitCheckInXp = 0;
      for (final habit in habits) {
        final habitLogs = logsByHabit[habit.id] ?? const [];
        final habitShields = shieldsByHabit[habit.id] ?? const [];
        final habitLogsByDate = <String, List<HabitLog>>{};
        for (final log in habitLogs) {
          habitLogsByDate.putIfAbsent(log.date, () => []).add(log);
        }
        final streak = StreakCalculator.calculateStreak(
          habit,
          habitLogs,
          today,
          habitShields,
        );
        final habitMultiplier = GamificationEngine.calculateStreakMultiplier(streak.currentStreak);

        for (final dayLogs in habitLogsByDate.values) {
          final isCompleted = StreakCalculator.isHabitCompletedOnDate(habit, dayLogs);
          final baseXp = GamificationEngine.calculateHabitDayBaseXp(habit, dayLogs, isCompleted);
          if (baseXp > 0) {
            habitCheckInXp += GamificationEngine.applyMultiplier(baseXp, habitMultiplier);
          }
        }
      }

      // 3. Perfect Days XP Bonus
      var perfectDaysBonusXp = 0;
      final allDates = logsByDate.keys.map((d) {
        try {
          return _dateFormatter.parse(d);
        } catch (_) {
          return null;
        }
      }).where((d) => d != null).cast<DateTime>();

      for (final date in allDates) {
        final scheduled = habits.where((h) => !h.archived && StreakCalculator.isHabitScheduledOnDate(h, date)).toList();
        if (scheduled.isNotEmpty) {
          final dateStr = _dateFormatter.format(date);
          final allCompleted = scheduled.every((h) {
            final dayLogs = (logsByHabit[h.id] ?? const []).where((l) => l.date == dateStr).toList();
            return StreakCalculator.isHabitCompletedOnDate(h, dayLogs);
          });
          if (allCompleted) {
            perfectDaysBonusXp += GamificationEngine.perfectDayBonusXp;
          }
        }
      }

      // 4. Achievement Evaluation (first pass)
      final initialTotalXp = habitCheckInXp + perfectDaysBonusXp;
      final estimatedProgression = GamificationEngine.calculateProgression(
        totalXp: initialTotalXp,
        longestActiveStreak: longestStreak,
      );

      final evaluationContext = EvaluationContext(
        habits: habits,
        allLogs: logs,
        categories: categories,
        currentLevel: estimatedProgression.level,
        storedUnlocks: storedMap,
        referenceDate: today,
      );
      final evaluatedAchievements = AchievementEvaluator.evaluateAll(evaluationContext);

      // 5. XP from Unlocked Achievements
      final achievementsXp = evaluatedAchievements
          .where((a) => a.isUnlocked)
          .fold<int>(0, (sum, a) => sum + a.definition.xpReward);

      final finalTotalXp = habitCheckInXp + perfectDaysBonusXp + achievementsXp;
      final unlockedCount = evaluatedAchievements.where((a) => a.isUnlocked).length;
      final totalCount = evaluatedAchievements.length;

      final finalProgression = GamificationEngine.calculateProgression(
        totalXp: finalTotalXp,
        longestActiveStreak: longestStreak,
        unlockedBadgesCount: unlockedCount,
        totalBadgesCount: totalCount,
      );

      // 6. Shield Bank Calculation
      final maxCap = latestUserGamification?.maxShieldsCapacity ?? ShieldBankingEngine.defaultMaxCapacity;
      final autoConsume = latestUserGamification?.autoConsumeShields ?? true;
      final shieldBankState = ShieldBankingEngine.calculateBankState(
        habits: habits,
        logs: logs,
        shields: shields,
        maxCapacity: maxCap,
        autoConsumeEnabled: autoConsume,
        referenceDate: today,
      );

      // 7. Level Up Celebration Check
      final lastCelebrated = latestUserGamification?.lastCelebratedLevel ?? 1;
      LevelUpCelebration? celebration;
      if (finalProgression.level > lastCelebrated) {
        final prevTitle = PlayerTitle.fromLevel(lastCelebrated);
        celebration = LevelUpCelebration(
          newLevel: finalProgression.level,
          previousLevel: lastCelebrated,
          title: finalProgression.title,
          titleChanged: finalProgression.title != prevTitle,
        );
      }

      // 8. Persist newly unlocked achievements
      final newlyUnlocked = evaluatedAchievements
          .where((a) => a.isUnlocked && !storedMap.containsKey(a.definition.id))
          .toList();
      if (newlyUnlocked.isNotEmpty) {
        final entities = newlyUnlocked.map((a) {
          return AchievementsCompanion(
            id: Value(a.definition.id),
            unlockedAt: Value(a.unlockedAt ?? DateTime.now().toUtc()),
            progress: Value(a.currentProgress),
            notified: const Value(false),
          );
        }).toList();
        gamificationDao.upsertAchievements(entities);
      }

      if (!controller.isClosed) {
        controller.add(
          _CombinedGamificationData(
            progression: finalProgression,
            achievements: evaluatedAchievements,
            shieldBank: shieldBankState,
            celebration: celebration,
          ),
        );
      }
    }

    controller = StreamController<_CombinedGamificationData>(
      onListen: () {
        subHabits = habitDao.watchAllHabits().listen((data) {
          latestHabits = data;
          evaluateAndEmit();
        });
        subLogs = habitLogDao.watchAllLogs().listen((data) {
          latestLogs = data;
          evaluateAndEmit();
        });
        subShields = habitShieldDao.watchAllShields().listen((data) {
          latestShields = data;
          evaluateAndEmit();
        });
        subCategories = habitCategoryDao.watchAllCategories().listen((data) {
          latestCategories = data;
          evaluateAndEmit();
        });
        subAchievements = gamificationDao.watchAllAchievements().listen((data) {
          latestAchievements = data;
          evaluateAndEmit();
        });
        subUserGamification = gamificationDao.watchUserGamification().listen((data) {
          latestUserGamification = data;
          hasUserGamificationEmitted = true;
          evaluateAndEmit();
        });
      },
      onCancel: () {
        subHabits?.cancel();
        subLogs?.cancel();
        subShields?.cancel();
        subCategories?.cancel();
        subAchievements?.cancel();
        subUserGamification?.cancel();
      },
    );

    return controller.stream.asBroadcastStream();
  }

  @override
  Stream<PlayerProgression> getPlayerProgression() =>
      _buildGamificationStream().map((data) => data.progression);

  @override
  Stream<List<AchievementStatus>> getAchievements() =>
      _buildGamificationStream().map((data) => data.achievements);

  @override
  Stream<LevelUpCelebration?> getPendingCelebration() =>
      _buildGamificationStream().map((data) => data.celebration);

  @override
  Stream<ShieldBankState> getShieldBankState() =>
      _buildGamificationStream().map((data) => data.shieldBank);

  @override
  Future<void> updateShieldSettings({
    required int maxCapacity,
    required bool autoConsume,
  }) async {
    final current = await gamificationDao.getUserGamificationOnce();
    await gamificationDao.upsertUserGamification(
      UserGamificationCompanion(
        id: const Value('user_gamification'),
        totalXp: Value(current?.totalXp ?? 0),
        currentLevel: Value(current?.currentLevel ?? 1),
        lastCelebratedLevel: Value(current?.lastCelebratedLevel ?? 1),
        maxShieldsCapacity: Value(maxCapacity),
        autoConsumeShields: Value(autoConsume),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> dismissCelebration(int level) async {
    final current = await gamificationDao.getUserGamificationOnce();
    await gamificationDao.upsertUserGamification(
      UserGamificationCompanion(
        id: const Value('user_gamification'),
        totalXp: Value(current?.totalXp ?? 0),
        currentLevel: Value(max(level, current?.currentLevel ?? 1)),
        lastCelebratedLevel: Value(max(level, current?.lastCelebratedLevel ?? 1)),
        maxShieldsCapacity: Value(current?.maxShieldsCapacity ?? ShieldBankingEngine.defaultMaxCapacity),
        autoConsumeShields: Value(current?.autoConsumeShields ?? true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
