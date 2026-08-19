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
        promptReflection: row.promptReflection,
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
        energyLevel: row.energyLevel,
        mood: row.mood,
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

  StreamController<_CombinedGamificationData>? _broadcastController;
  _CombinedGamificationData? _lastCombinedData;

  Stream<_CombinedGamificationData> _getOrCreateGamificationStream() {
    if (_broadcastController == null) {
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

      bool evaluateScheduled = false;
      Set<String> knownUnlockedIds = {};

      void evaluateAndEmit() {
        evaluateScheduled = false;
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
        
        final logsByHabit = <String, List<HabitLog>>{};
        final logsByDate = <String, List<HabitLog>>{};
        final logsByHabitDate = <String, Map<String, List<HabitLog>>>{};
        for (final log in logs) {
          logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
          logsByDate.putIfAbsent(log.date, () => []).add(log);
          logsByHabitDate
              .putIfAbsent(log.habitId, () => {})
              .putIfAbsent(log.date, () => [])
              .add(log);
        }

        final shieldsByHabit = <String, List<HabitShield>>{};
        for (final shield in shields) {
          shieldsByHabit.putIfAbsent(shield.habitId, () => []).add(shield);
        }

        final today = DateTime.now();
        final streakByHabit = <String, StreakResult>{};
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
          streakByHabit[habit.id] = streak;
          longestStreak = max(longestStreak, max(streak.currentStreak, streak.bestStreak));
        }

        // 2. Calculate Base Habit Check-in XP reusing streakByHabit
        var habitCheckInXp = 0;
        for (final habit in habits) {
          final habitLogsByDate = logsByHabitDate[habit.id] ?? const {};
          final currentStreak = streakByHabit[habit.id]?.currentStreak ?? 0;
          final habitMultiplier = GamificationEngine.calculateStreakMultiplier(currentStreak);

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
        for (final dateStr in logsByDate.keys) {
          final date = DateTime.tryParse(dateStr);
          if (date == null) continue;
          final scheduled = habits.where((h) => !h.archived && StreakCalculator.isHabitScheduledOnDate(h, date)).toList();
          if (scheduled.isNotEmpty) {
            final allCompleted = scheduled.every((h) {
              final dayLogs = logsByHabitDate[h.id]?[dateStr] ?? const [];
              return StreakCalculator.isHabitCompletedOnDate(h, dayLogs);
            });
            if (allCompleted) {
              perfectDaysBonusXp += GamificationEngine.perfectDayBonusXp;
            }
          }
        }

        // 4. Achievement Evaluator reusing precomputed streaks
        final initialTotalXp = habitCheckInXp + perfectDaysBonusXp;
        final estimatedProgression = GamificationEngine.calculateProgression(
          totalXp: initialTotalXp,
          longestActiveStreak: longestStreak,
        );

        final evalContext = EvaluationContext(
          habits: habits,
          allLogs: logs,
          categories: categories,
          currentLevel: estimatedProgression.level,
          storedUnlocks: { for (var a in latestAchievements!) a.id: a.unlockedAt },
          referenceDate: today,
          precomputedStreaks: streakByHabit,
        );
        final evaluatedAchievements = AchievementEvaluator.evaluateAll(evalContext);

        // 5. Total Achievement XP & Unlocked Badges count
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

        // 6. Shield Bank
        final shieldBankState = ShieldBankingEngine.calculateBankState(
          habits: habits,
          logs: logs,
          shields: shields,
          maxCapacity: latestUserGamification?.maxShieldsCapacity ?? ShieldBankingEngine.defaultMaxCapacity,
          autoConsumeEnabled: latestUserGamification?.autoConsumeShields ?? true,
          referenceDate: today,
          precomputedStreaks: streakByHabit,
        );

        // 7. Level Up Celebration
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

        // 8. Persist new unlocks
        final newlyUnlocked = evaluatedAchievements
            .where((a) => a.isUnlocked && !knownUnlockedIds.contains(a.definition.id))
            .toList();
        if (newlyUnlocked.isNotEmpty) {
          final companions = <AchievementsCompanion>[];
          for (var a in newlyUnlocked) {
            knownUnlockedIds.add(a.definition.id);
            companions.add(AchievementsCompanion(
              id: Value(a.definition.id),
              unlockedAt: Value(a.unlockedAt ?? DateTime.now().toUtc()),
              progress: Value(a.currentProgress),
            ));
          }
          gamificationDao.upsertAchievements(companions);
        }

        final combined = _CombinedGamificationData(
          progression: finalProgression,
          achievements: evaluatedAchievements,
          shieldBank: shieldBankState,
          celebration: celebration,
        );

        _lastCombinedData = combined;

        if (_broadcastController != null && !_broadcastController!.isClosed) {
          _broadcastController!.add(combined);
        }
      }

      void scheduleEvaluation() {
        if (evaluateScheduled) return;
        evaluateScheduled = true;
        scheduleMicrotask(evaluateAndEmit);
      }

      _broadcastController = StreamController<_CombinedGamificationData>.broadcast(
        onListen: () {
          subHabits = habitDao.watchAllHabits().listen((data) {
            latestHabits = data;
            scheduleEvaluation();
          });
          subLogs = habitLogDao.watchAllLogs().listen((data) {
            latestLogs = data;
            scheduleEvaluation();
          });
          subShields = habitShieldDao.watchAllShields().listen((data) {
            latestShields = data;
            scheduleEvaluation();
          });
          subCategories = habitCategoryDao.watchAllCategories().listen((data) {
            latestCategories = data;
            scheduleEvaluation();
          });
          subAchievements = gamificationDao.watchAllAchievements().listen((data) {
            latestAchievements = data;
            knownUnlockedIds = data.map((a) => a.id).toSet();
            scheduleEvaluation();
          });
          subUserGamification = gamificationDao.watchUserGamification().listen((data) {
            latestUserGamification = data;
            hasUserGamificationEmitted = true;
            scheduleEvaluation();
          });
        },
        onCancel: () {
          subHabits?.cancel();
          subLogs?.cancel();
          subShields?.cancel();
          subCategories?.cancel();
          subAchievements?.cancel();
          subUserGamification?.cancel();
          _broadcastController = null;
          _lastCombinedData = null;
        },
      );
    }

    return Stream<_CombinedGamificationData>.multi((multiController) {
      if (_lastCombinedData != null) {
        multiController.add(_lastCombinedData!);
      }
      final sub = _broadcastController!.stream.listen(
        (data) => multiController.add(data),
        onError: multiController.addError,
        onDone: multiController.close,
      );
      multiController.onCancel = () {
        sub.cancel();
      };
    });
  }

  @override
  Stream<PlayerProgression> getPlayerProgression() =>
      _getOrCreateGamificationStream().map((data) => data.progression);

  @override
  Stream<List<AchievementStatus>> getAchievements() =>
      _getOrCreateGamificationStream().map((data) => data.achievements);

  @override
  Stream<LevelUpCelebration?> getPendingCelebration() =>
      _getOrCreateGamificationStream().map((data) => data.celebration);

  @override
  Stream<ShieldBankState> getShieldBankState() =>
      _getOrCreateGamificationStream().map((data) => data.shieldBank);

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
