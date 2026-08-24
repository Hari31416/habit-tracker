import 'dart:math';
import 'package:drift/drift.dart';
import '../../domain/engines/streak_calculator.dart';
import '../../domain/gamification/gamification_engine.dart';
import '../../domain/models/habit_routine.dart';
import '../../domain/models/routine_log.dart';
import '../../domain/repositories/routine_repository.dart';
import '../local/app_database.dart';
import '../local/converters/entity_mappers.dart';
import '../local/daos/gamification_dao.dart';
import '../local/daos/habit_dao.dart';
import '../local/daos/habit_log_dao.dart';
import '../local/daos/routine_dao.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  final RoutineDao routineDao;
  final GamificationDao gamificationDao;
  final HabitDao habitDao;
  final HabitLogDao habitLogDao;

  RoutineRepositoryImpl({
    required this.routineDao,
    required this.gamificationDao,
    required this.habitDao,
    required this.habitLogDao,
  });

  HabitRoutine routineFromRow(HabitRoutineRow row) {
    return HabitRoutine(
      id: row.id,
      title: row.title,
      description: row.description,
      color: row.color,
      icon: row.icon,
      targetTimeWindow: row.targetTimeWindow,
      habitIds: row.habitIds,
      bonusXp: row.bonusXp,
      isDeleted: row.isDeleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  HabitRoutinesCompanion routineToCompanion(HabitRoutine r) {
    return HabitRoutinesCompanion(
      id: Value(r.id),
      title: Value(r.title),
      description: Value(r.description),
      color: Value(r.color),
      icon: Value(r.icon),
      targetTimeWindow: Value(r.targetTimeWindow),
      habitIds: Value(r.habitIds),
      bonusXp: Value(r.bonusXp),
      isDeleted: Value(r.isDeleted),
      createdAt: Value(r.createdAt),
      updatedAt: Value(r.updatedAt),
    );
  }

  RoutineLog routineLogFromRow(RoutineLogRow row) {
    return RoutineLog(
      id: row.id,
      routineId: row.routineId,
      date: row.date,
      completedAt: row.completedAt,
      completedHabitIds: row.completedHabitIds,
      xpEarned: row.xpEarned,
      isDeleted: row.isDeleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  RoutineLogsCompanion routineLogToCompanion(RoutineLog l) {
    return RoutineLogsCompanion(
      id: Value(l.id),
      routineId: Value(l.routineId),
      date: Value(l.date),
      completedAt: Value(l.completedAt),
      completedHabitIds: Value(l.completedHabitIds),
      xpEarned: Value(l.xpEarned),
      isDeleted: Value(l.isDeleted),
      createdAt: Value(l.createdAt),
      updatedAt: Value(l.updatedAt),
    );
  }

  @override
  Stream<List<HabitRoutine>> watchActiveRoutines() {
    return routineDao.watchActiveRoutines().map((rows) => rows.map(routineFromRow).toList());
  }

  @override
  Future<List<HabitRoutine>> getActiveRoutinesOnce() async {
    final rows = await routineDao.getActiveRoutinesOnce();
    return rows.map(routineFromRow).toList();
  }

  @override
  Future<List<HabitRoutine>> getAllRoutinesOnce() async {
    final rows = await routineDao.getAllRoutinesIncludingDeleted();
    return rows.map(routineFromRow).toList();
  }

  @override
  Future<HabitRoutine?> getRoutineById(String id) async {
    final row = await routineDao.getRoutineById(id);
    return row != null ? routineFromRow(row) : null;
  }

  @override
  Future<void> upsertRoutine(HabitRoutine routine) {
    return routineDao.upsertRoutine(routineToCompanion(routine));
  }

  @override
  Future<void> deleteRoutine(String id) {
    return routineDao.deleteRoutine(id, DateTime.now().toUtc());
  }

  @override
  Future<void> reorderHabitsInRoutine(String routineId, List<String> habitIds) async {
    final routine = await getRoutineById(routineId);
    if (routine != null) {
      final updated = routine.copyWith(
        habitIds: habitIds,
        updatedAt: DateTime.now().toUtc(),
      );
      await upsertRoutine(updated);
    }
  }

  @override
  Stream<List<RoutineLog>> watchRoutineLogsForDate(String date) {
    return routineDao.watchRoutineLogsForDate(date).map((rows) => rows.map(routineLogFromRow).toList());
  }

  @override
  Future<List<RoutineLog>> getRoutineLogsForDateOnce(String date) async {
    final rows = await routineDao.getRoutineLogsForDateOnce(date);
    return rows.map(routineLogFromRow).toList();
  }

  @override
  Future<List<RoutineLog>> getAllRoutineLogsOnce() async {
    final rows = await routineDao.getAllRoutineLogsOnce();
    return rows.map(routineLogFromRow).toList();
  }

  @override
  Future<RoutineLog?> getRoutineLog(String routineId, String date) async {
    final row = await routineDao.getRoutineLog(routineId, date);
    return row != null ? routineLogFromRow(row) : null;
  }

  @override
  Future<RoutineLog> completeRoutine({
    required String routineId,
    required String date,
    required List<String> completedHabitIds,
    int? customBonusXp,
  }) async {
    final now = DateTime.now().toUtc();
    final routine = await getRoutineById(routineId);
    final baseXp = customBonusXp ?? routine?.bonusXp ?? GamificationEngine.baseRoutineCompletionBonusXp;

    // Calculate active streak multiplier
    final activeHabits = await habitDao.getActiveHabitsOnce();
    final allLogs = await habitLogDao.getAllLogsOnce();
    final logsByHabit = <String, List<HabitLogRow>>{};
    for (final l in allLogs) {
      logsByHabit.putIfAbsent(l.habitId, () => []).add(l);
    }

    var longestActiveStreak = 0;
    for (final hRow in activeHabits) {
      final h = hRow.toDomain();
      final logs = (logsByHabit[h.id] ?? []).map((lr) => lr.toDomain()).toList();
      final streak = StreakCalculator.calculateStreak(h, logs, now);
      longestActiveStreak = max(longestActiveStreak, streak.currentStreak);
    }

    final multiplier = GamificationEngine.calculateStreakMultiplier(longestActiveStreak);
    final awardedXp = GamificationEngine.applyMultiplier(baseXp, multiplier);

    // Award bonus XP to gamification progression
    final currentGam = await gamificationDao.getUserGamificationOnce();
    if (currentGam != null) {
      final newTotalXp = currentGam.totalXp + awardedXp;
      final progression = GamificationEngine.calculateProgression(
        totalXp: newTotalXp,
        longestActiveStreak: longestActiveStreak,
      );
      await gamificationDao.upsertUserGamification(
        UserGamificationCompanion(
          id: const Value('user_gamification'),
          totalXp: Value(newTotalXp),
          currentLevel: Value(progression.level),
          lastCelebratedLevel: Value(currentGam.lastCelebratedLevel),
          maxShieldsCapacity: Value(currentGam.maxShieldsCapacity),
          autoConsumeShields: Value(currentGam.autoConsumeShields),
          updatedAt: Value(now),
        ),
      );
    }

    final logId = 'routine_log_${routineId}_$date';
    final routineLog = RoutineLog(
      id: logId,
      routineId: routineId,
      date: date,
      completedAt: now,
      completedHabitIds: completedHabitIds,
      xpEarned: awardedXp,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );

    await routineDao.upsertRoutineLog(routineLogToCompanion(routineLog));
    return routineLog;
  }
}
