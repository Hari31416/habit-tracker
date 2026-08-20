import 'dart:math';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/engines/shield_banking_engine.dart';
import '../../domain/engines/streak_calculator.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_category.dart';
import '../../domain/models/habit_frequency_type.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/models/habit_shield.dart';
import '../../domain/models/habit_target_type.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/schedulers/habit_reminder_scheduler.dart';
import '../local/app_database.dart';
import '../local/database_seeder.dart';
import '../local/daos/gamification_dao.dart';
import '../local/daos/habit_category_dao.dart';
import '../local/daos/habit_dao.dart';
import '../local/daos/habit_log_dao.dart';
import '../local/daos/habit_shield_dao.dart';

class HabitRepositoryImpl implements HabitRepository {
  final HabitDao habitDao;
  final HabitLogDao habitLogDao;
  final HabitShieldDao habitShieldDao;
  final HabitCategoryDao habitCategoryDao;
  final GamificationDao? gamificationDao;
  final HabitReminderScheduler reminderScheduler;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  final Uuid _uuid = const Uuid();

  HabitRepositoryImpl({
    required this.habitDao,
    required this.habitLogDao,
    required this.habitShieldDao,
    required this.habitCategoryDao,
    this.gamificationDao,
    required this.reminderScheduler,
  });

  // Domain Mappings
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
        healthMetric: row.healthMetric,
        healthSyncEnabled: row.healthSyncEnabled,
        isDeleted: row.isDeleted,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  HabitsCompanion _habitDomainToCompanion(Habit habit) => HabitsCompanion(
        id: Value(habit.id),
        title: Value(habit.title),
        description: Value(habit.description),
        color: Value(habit.color),
        icon: Value(habit.icon),
        categoryId: Value(habit.categoryId),
        frequencyType: Value(habit.frequencyType),
        targetDaysOfWeek: Value(habit.targetDaysOfWeek),
        targetCountPerWeek: Value(habit.targetCountPerWeek),
        intervalHours: Value(habit.intervalHours),
        timesPerDay: Value(habit.timesPerDay),
        timeWindow: Value(habit.timeWindow),
        targetType: Value(habit.targetType),
        targetValue: Value(habit.targetValue),
        unit: Value(habit.unit),
        pinned: Value(habit.pinned),
        reminderTimes: Value(habit.reminderTimes),
        motivationNotes: Value(habit.motivationNotes),
        archived: Value(habit.archived),
        promptReflection: Value(habit.promptReflection),
        healthMetric: Value(habit.healthMetric),
        healthSyncEnabled: Value(habit.healthSyncEnabled),
        isDeleted: Value(habit.isDeleted),
        createdAt: Value(habit.createdAt),
        updatedAt: Value(habit.updatedAt),
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
        isDeleted: row.isDeleted,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  HabitShield _shieldRowToDomain(HabitShieldRow row) => HabitShield(
        id: row.id,
        habitId: row.habitId,
        date: row.date,
        autoApplied: row.autoApplied,
        isDeleted: row.isDeleted,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  HabitCategory _categoryRowToDomain(HabitCategoryRow row) => HabitCategory(
        id: row.id,
        name: row.name,
        color: row.color,
        icon: row.icon,
        isDeleted: row.isDeleted,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  HabitCategoriesCompanion _categoryDomainToCompanion(HabitCategory category) {
    final now = DateTime.now().toUtc();
    return HabitCategoriesCompanion(
      id: Value(category.id),
      name: Value(category.name),
      color: Value(category.color),
      icon: Value(category.icon),
      isDeleted: Value(category.isDeleted),
      createdAt: Value(category.createdAt ?? now),
      updatedAt: Value(category.updatedAt ?? now),
    );
  }

  // Habits
  @override
  Stream<List<Habit>> getAllHabits() =>
      habitDao.watchAllHabits().map((rows) => rows.map(_habitRowToDomain).toList());

  @override
  Stream<List<Habit>> getActiveHabits() =>
      habitDao.watchActiveHabits().map((rows) => rows.map(_habitRowToDomain).toList());

  @override
  Stream<List<Habit>> getArchivedHabits() =>
      habitDao.watchArchivedHabits().map((rows) => rows.map(_habitRowToDomain).toList());

  @override
  Stream<List<Habit>> getPinnedHabits() =>
      habitDao.watchPinnedHabits().map((rows) => rows.map(_habitRowToDomain).toList());

  @override
  Stream<Habit?> getHabitById(String id) =>
      habitDao.watchHabitById(id).map((row) => row != null ? _habitRowToDomain(row) : null);

  @override
  Future<Habit?> getHabitByIdOnce(String id) async {
    final row = await habitDao.getHabitByIdOnce(id);
    return row != null ? _habitRowToDomain(row) : null;
  }

  @override
  Stream<List<Habit>> getHabitsByCategory(String categoryId) => habitDao
      .watchHabitsByCategory(categoryId)
      .map((rows) => rows.map(_habitRowToDomain).toList());

  @override
  Future<void> upsertHabit(Habit habit) async {
    await habitDao.upsertHabit(_habitDomainToCompanion(habit));
    await reminderScheduler.schedule(habit, catchUpIfDue: true);
  }

  @override
  Future<void> deleteHabit(Habit habit) async {
    await habitDao.deleteHabitById(habit.id, DateTime.now().toUtc());
    await reminderScheduler.cancel(habit.id);
  }

  @override
  Future<void> setPinned(String id, bool pinned) async {
    await habitDao.updatePinned(id, pinned, DateTime.now().toUtc());
  }

  @override
  Future<void> setArchived(String id, bool archived) async {
    await habitDao.updateArchived(id, archived, DateTime.now().toUtc());
    if (archived) {
      await reminderScheduler.cancel(id);
    } else {
      final habit = await getHabitByIdOnce(id);
      if (habit != null) {
        await reminderScheduler.schedule(habit, catchUpIfDue: true);
      }
    }
  }

  @override
  Future<void> seedDemoHabits() async {
    await DatabaseSeeder.seedDemoHabits(habitDao.attachedDatabase);
    await reminderScheduler.rescheduleAll();
  }

  // Logs
  @override
  Stream<List<HabitLog>> getLogsForHabit(String habitId) => habitLogDao
      .watchLogsForHabit(habitId)
      .map((rows) => rows.map(_logRowToDomain).toList());

  @override
  Future<List<HabitLog>> getLogsForHabitOnce(String habitId) async {
    final rows = await habitLogDao.getLogsForHabitOnce(habitId);
    return rows.map(_logRowToDomain).toList();
  }

  @override
  Stream<List<HabitLog>> getLogsForDate(DateTime date) => habitLogDao
      .watchLogsForDate(_dateFormatter.format(date))
      .map((rows) => rows.map(_logRowToDomain).toList());

  @override
  Future<List<HabitLog>> getLogsForDateOnce(DateTime date) async {
    final rows = await habitLogDao.getLogsForDateOnce(_dateFormatter.format(date));
    return rows.map(_logRowToDomain).toList();
  }

  @override
  Stream<List<HabitLog>> getLogsForHabitAndDate(String habitId, DateTime date) => habitLogDao
      .watchLogsForHabitAndDate(habitId, _dateFormatter.format(date))
      .map((rows) => rows.map(_logRowToDomain).toList());

  @override
  Stream<List<HabitLog>> getLogsForDateRange(DateTime startDate, DateTime endDate) => habitLogDao
      .watchLogsForDateRange(_dateFormatter.format(startDate), _dateFormatter.format(endDate))
      .map((rows) => rows.map(_logRowToDomain).toList());

  @override
  Future<List<HabitLog>> getLogsForDateRangeOnce(DateTime startDate, DateTime endDate) async {
    final rows = await habitLogDao.getLogsForDateRangeOnce(
      _dateFormatter.format(startDate),
      _dateFormatter.format(endDate),
    );
    return rows.map(_logRowToDomain).toList();
  }

  @override
  Stream<List<HabitLog>> getAllLogs() =>
      habitLogDao.watchAllLogs().map((rows) => rows.map(_logRowToDomain).toList());

  @override
  Future<List<HabitLog>> getAllLogsOnce() async {
    final rows = await habitLogDao.getAllLogsOnce();
    return rows.map(_logRowToDomain).toList();
  }

  Future<void> _rescheduleHabitRemindersIfActive(String habitId) async {
    try {
      final habit = await getHabitByIdOnce(habitId);
      if (habit != null && !habit.archived && habit.reminderTimes.isNotEmpty) {
        await reminderScheduler.schedule(habit);
      }
    } catch (_) {}
  }

  @override
  Future<void> logCheckIn({
    required String habitId,
    required DateTime date,
    required bool completed,
    double? value,
    int? durationSeconds,
    int? intervalIndex,
    String? note,
    int? energyLevel,
    String? mood,
  }) async {
    final now = DateTime.now().toUtc();
    final log = HabitLogsCompanion(
      id: Value(_uuid.v4()),
      habitId: Value(habitId),
      date: Value(_dateFormatter.format(date)),
      timestamp: Value(now),
      intervalIndex: Value(intervalIndex),
      completed: Value(completed),
      value: Value(value),
      durationSeconds: Value(durationSeconds),
      note: Value(note),
      energyLevel: Value(energyLevel),
      mood: Value(mood),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await habitLogDao.upsertLog(log);
    await _rescheduleHabitRemindersIfActive(habitId);
  }

  @override
  Future<void> updateReflection({
    required String habitId,
    required DateTime date,
    int? energyLevel,
    String? mood,
    String? note,
  }) async {
    final dateStr = _dateFormatter.format(date);
    final existingRows = await habitLogDao.getLogsForHabitAndDateOnce(habitId, dateStr);
    if (existingRows.isEmpty) {
      // Create a completed log with reflection
      await logCheckIn(
        habitId: habitId,
        date: date,
        completed: true,
        energyLevel: energyLevel,
        mood: mood,
        note: note,
      );
    } else {
      await habitLogDao.updateReflectionForHabitAndDate(
        habitId,
        dateStr,
        energyLevel: energyLevel,
        mood: mood,
        note: note,
      );
    }
  }

  @override
  Future<void> toggleBooleanCheckIn(String habitId, DateTime date) async {
    await habitDao.attachedDatabase.transaction(() async {
      final dateStr = _dateFormatter.format(date);
      final habit = await getHabitByIdOnce(habitId);
      final existingRows = await habitLogDao.getLogsForHabitAndDateOnce(habitId, dateStr);
      final existingLogs = existingRows.map(_logRowToDomain).toList();

      final wasCompleted = habit != null
          ? StreakCalculator.isHabitCompletedOnDate(habit, existingLogs)
          : existingLogs.any((l) => l.completed);

      if (wasCompleted) {
        await habitLogDao.deleteLogsForHabitAndDate(habitId, dateStr);
      } else {
        await habitLogDao.deleteLogsForHabitAndDate(habitId, dateStr);
        final now = DateTime.now().toUtc();
        if (habit != null) {
          switch (habit.targetType) {
            case HabitTargetType.boolean:
              switch (habit.frequencyType) {
                case HabitFrequencyType.timesPerDay:
                case HabitFrequencyType.subdayInterval:
                  final slots = habit.timesPerDay ?? habit.targetValue?.toInt() ?? 1;
                  final slotLogs = <HabitLogsCompanion>[];
                  for (var i = 0; i < slots; i++) {
                    slotLogs.add(
                      HabitLogsCompanion(
                        id: Value(_uuid.v4()),
                        habitId: Value(habitId),
                        date: Value(dateStr),
                        timestamp: Value(now),
                        intervalIndex: Value(i),
                        completed: const Value(true),
                        createdAt: Value(now),
                        updatedAt: Value(now),
                      ),
                    );
                  }
                  await habitLogDao.insertLogs(slotLogs);
                  break;
                default:
                  final log = HabitLogsCompanion(
                    id: Value(_uuid.v4()),
                    habitId: Value(habitId),
                    date: Value(dateStr),
                    timestamp: Value(now),
                    completed: const Value(true),
                    createdAt: Value(now),
                    updatedAt: Value(now),
                  );
                  await habitLogDao.upsertLog(log);
              }
              break;

            case HabitTargetType.numeric:
              final target = habit.targetValue ?? 1.0;
              final log = HabitLogsCompanion(
                id: Value(_uuid.v4()),
                habitId: Value(habitId),
                date: Value(dateStr),
                timestamp: Value(now),
                completed: const Value(true),
                value: Value(target),
                createdAt: Value(now),
                updatedAt: Value(now),
              );
              await habitLogDao.upsertLog(log);
              break;

            case HabitTargetType.timer:
              final targetMin = habit.targetValue ?? 25.0;
              final totalSec = (targetMin * 60).toInt();
              final log = HabitLogsCompanion(
                id: Value(_uuid.v4()),
                habitId: Value(habitId),
                date: Value(dateStr),
                timestamp: Value(now),
                completed: const Value(true),
                value: Value(targetMin),
                durationSeconds: Value(totalSec),
                createdAt: Value(now),
                updatedAt: Value(now),
              );
              await habitLogDao.upsertLog(log);
              break;
          }
        } else {
          final log = HabitLogsCompanion(
            id: Value(_uuid.v4()),
            habitId: Value(habitId),
            date: Value(dateStr),
            timestamp: Value(now),
            completed: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          );
          await habitLogDao.upsertLog(log);
        }
      }
    });
    await _rescheduleHabitRemindersIfActive(habitId);
  }

  @override
  Future<void> updateNumericValue(String habitId, DateTime date, double value) async {
    await habitDao.attachedDatabase.transaction(() async {
      final dateStr = _dateFormatter.format(date);
      final habit = await getHabitByIdOnce(habitId);
      final target = habit?.targetValue ?? 1.0;
      final isComplete = value >= target;
      final existingLogs = await habitLogDao.getLogsForHabitAndDateOnce(habitId, dateStr);
      final now = DateTime.now().toUtc();
      final durationSec =
          habit?.targetType == HabitTargetType.timer ? (value * 60).toInt() : null;

      if (existingLogs.length > 1) {
        await habitLogDao.deleteLogsForHabitAndDate(habitId, dateStr);
      }

      final log = HabitLogsCompanion(
        id: Value(existingLogs.length == 1 ? existingLogs.first.id : _uuid.v4()),
        habitId: Value(habitId),
        date: Value(dateStr),
        timestamp: Value(now),
        completed: Value(isComplete),
        value: Value(value),
        durationSeconds: Value(durationSec),
        createdAt: Value(existingLogs.isNotEmpty ? existingLogs.first.createdAt : now),
        updatedAt: Value(now),
      );
      await habitLogDao.upsertLog(log);
    });
    await _rescheduleHabitRemindersIfActive(habitId);
  }

  @override
  Future<void> addNumericDelta(String habitId, DateTime date, double delta) async {
    await habitDao.attachedDatabase.transaction(() async {
      final dateStr = _dateFormatter.format(date);
      final habit = await getHabitByIdOnce(habitId);
      final target = habit?.targetValue ?? 1.0;
      final existingLogs = await habitLogDao.getLogsForHabitAndDateOnce(habitId, dateStr);
      final currentValue = existingLogs.fold<double>(
        0.0,
        (sum, l) {
          if (l.durationSeconds != null && l.durationSeconds! > 0) {
            return sum + (l.durationSeconds! / 60.0);
          } else {
            return sum + (l.value ?? (l.completed ? target : 0.0));
          }
        },
      );
      final newValue = max(0.0, currentValue + delta);
      final isComplete = newValue >= target;
      final now = DateTime.now().toUtc();
      final durationSec =
          habit?.targetType == HabitTargetType.timer ? (newValue * 60).toInt() : null;

      if (existingLogs.length > 1) {
        await habitLogDao.deleteLogsForHabitAndDate(habitId, dateStr);
      }

      final log = HabitLogsCompanion(
        id: Value(existingLogs.length == 1 ? existingLogs.first.id : _uuid.v4()),
        habitId: Value(habitId),
        date: Value(dateStr),
        timestamp: Value(now),
        completed: Value(isComplete),
        value: Value(newValue),
        durationSeconds: Value(durationSec),
        createdAt: Value(existingLogs.isNotEmpty ? existingLogs.first.createdAt : now),
        updatedAt: Value(now),
      );
      await habitLogDao.upsertLog(log);
    });
    await _rescheduleHabitRemindersIfActive(habitId);
  }

  @override
  Future<void> toggleSlotCheckIn(String habitId, DateTime date, int slotIndex) async {
    await habitDao.attachedDatabase.transaction(() async {
      final dateStr = _dateFormatter.format(date);
      final existingLogs = await habitLogDao.getLogsForHabitAndDateOnce(habitId, dateStr);
      final slotLog = existingLogs.where((l) => l.intervalIndex == slotIndex).firstOrNull;

      if (slotLog != null && slotLog.completed) {
        await habitLogDao.deleteSlotLog(habitId, dateStr, slotIndex);
      } else {
        final now = DateTime.now().toUtc();
        final log = HabitLogsCompanion(
          id: Value(slotLog?.id ?? _uuid.v4()),
          habitId: Value(habitId),
          date: Value(dateStr),
          timestamp: Value(now),
          intervalIndex: Value(slotIndex),
          completed: const Value(true),
          createdAt: Value(slotLog?.createdAt ?? now),
          updatedAt: Value(now),
        );
        await habitLogDao.upsertLog(log);
      }
    });
    await _rescheduleHabitRemindersIfActive(habitId);
  }

  @override
  Future<void> deleteLogsForHabitAndDate(String habitId, DateTime date) async {
    await habitLogDao.deleteLogsForHabitAndDate(habitId, _dateFormatter.format(date));
    await _rescheduleHabitRemindersIfActive(habitId);
  }

  // Shields & Grace Days
  @override
  Stream<List<HabitShield>> getAllShields() =>
      habitShieldDao.watchAllShields().map((rows) => rows.map(_shieldRowToDomain).toList());

  @override
  Future<List<HabitShield>> getAllShieldsOnce() async {
    final rows = await habitShieldDao.getAllShieldsOnce();
    return rows.map(_shieldRowToDomain).toList();
  }

  @override
  Stream<List<HabitShield>> getShieldsForHabit(String habitId) => habitShieldDao
      .watchShieldsForHabit(habitId)
      .map((rows) => rows.map(_shieldRowToDomain).toList());

  @override
  Future<List<HabitShield>> getShieldsForHabitOnce(String habitId) async {
    final rows = await habitShieldDao.getShieldsForHabitOnce(habitId);
    return rows.map(_shieldRowToDomain).toList();
  }

  @override
  Stream<List<HabitShield>> getShieldsForDate(DateTime date) => habitShieldDao
      .watchShieldsForDate(_dateFormatter.format(date))
      .map((rows) => rows.map(_shieldRowToDomain).toList());

  @override
  Future<List<HabitShield>> getShieldsForDateOnce(DateTime date) async {
    final rows = await habitShieldDao.getShieldsForDateOnce(_dateFormatter.format(date));
    return rows.map(_shieldRowToDomain).toList();
  }

  @override
  Stream<List<HabitShield>> getShieldsForDateRange(DateTime startDate, DateTime endDate) =>
      habitShieldDao
          .watchShieldsForDateRange(_dateFormatter.format(startDate), _dateFormatter.format(endDate))
          .map((rows) => rows.map(_shieldRowToDomain).toList());

  @override
  Future<List<HabitShield>> getShieldsForDateRangeOnce(DateTime startDate, DateTime endDate) async {
    final rows = await habitShieldDao.getShieldsForDateRangeOnce(
      _dateFormatter.format(startDate),
      _dateFormatter.format(endDate),
    );
    return rows.map(_shieldRowToDomain).toList();
  }

  @override
  Future<bool> applyShield({
    required String habitId,
    required DateTime date,
    bool autoApplied = false,
  }) async {
    final habits = (await habitDao.getActiveHabitsOnce()).map(_habitRowToDomain).toList();
    final allLogs = await getAllLogsOnce();
    final allShields = await getAllShieldsOnce();
    final userGamification = await gamificationDao?.getUserGamificationOnce();
    final autoConsume = userGamification?.autoConsumeShields ?? true;
    final maxCapacity = userGamification?.maxShieldsCapacity ??
        ShieldBankingEngine.defaultMaxCapacity;

    final bankState = ShieldBankingEngine.calculateBankState(
      habits: habits,
      logs: allLogs,
      shields: allShields,
      maxCapacity: maxCapacity,
      autoConsumeEnabled: autoConsume,
      referenceDate: date,
    );

    if (bankState.availableShields <= 0) {
      return false;
    }

    final dateStr = _dateFormatter.format(date);
    final now = DateTime.now().toUtc();
    final companion = HabitShieldsCompanion(
      id: Value(_uuid.v4()),
      habitId: Value(habitId),
      date: Value(dateStr),
      autoApplied: Value(autoApplied),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await habitShieldDao.upsertShield(companion);
    return true;
  }

  @override
  Future<void> removeShield(String habitId, DateTime date) async {
    final dateStr = _dateFormatter.format(date);
    await habitShieldDao.deleteShield(habitId, dateStr);
  }

  @override
  Future<bool> toggleShield(String habitId, DateTime date) async {
    final isShielded = await isDateShielded(habitId, date);
    if (isShielded) {
      await removeShield(habitId, date);
      return true;
    } else {
      return await applyShield(habitId: habitId, date: date, autoApplied: false);
    }
  }

  @override
  Future<bool> isDateShielded(String habitId, DateTime date) async {
    final dateStr = _dateFormatter.format(date);
    final shield = await habitShieldDao.getShieldForHabitAndDate(habitId, dateStr);
    return shield != null;
  }

  @override
  Future<int> autoProtectMissedDays(DateTime date) async {
    final habits = (await habitDao.getActiveHabitsOnce()).map(_habitRowToDomain).toList();
    final allLogs = await getAllLogsOnce();
    final allShields = await getAllShieldsOnce();

    final userGamification = await gamificationDao?.getUserGamificationOnce();
    final autoConsume = userGamification?.autoConsumeShields ?? true;
    final maxCapacity = userGamification?.maxShieldsCapacity ?? ShieldBankingEngine.defaultMaxCapacity;

    if (!autoConsume) return 0;

    final currentBankState = ShieldBankingEngine.calculateBankState(
      habits: habits,
      logs: allLogs,
      shields: allShields,
      maxCapacity: maxCapacity,
      autoConsumeEnabled: autoConsume,
      referenceDate: date,
    );

    if (currentBankState.availableShields <= 0) return 0;

    var availableShields = currentBankState.availableShields;
    var autoAppliedCount = 0;
    final targetDate = DateTime(date.year, date.month, date.day);
    final targetDateStr = _dateFormatter.format(targetDate);
    final now = DateTime.now().toUtc();

    final logsByHabit = <String, List<HabitLog>>{};
    for (final log in allLogs) {
      logsByHabit.putIfAbsent(log.habitId, () => []).add(log);
    }

    final shieldsByHabit = <String, List<HabitShield>>{};
    for (final s in allShields) {
      shieldsByHabit.putIfAbsent(s.habitId, () => []).add(s);
    }

    final newShieldsToInsert = <HabitShieldsCompanion>[];

    for (final habit in habits) {
      if (availableShields <= 0) break;

      final isScheduled = StreakCalculator.isHabitScheduledOnDate(habit, targetDate);
      if (!isScheduled) continue;

      final habitLogs = logsByHabit[habit.id] ?? const [];
      final dayLogs = habitLogs.where((l) => l.date == targetDateStr).toList();
      final isCompleted = StreakCalculator.isHabitCompletedOnDate(habit, dayLogs);

      final habitShields = shieldsByHabit[habit.id] ?? const [];
      final isShielded = habitShields.any((s) => s.date == targetDateStr);

      if (!isCompleted && !isShielded) {
        // Check if habit had an active streak ending on yesterday
        final yesterday = targetDate.subtract(const Duration(days: 1));
        final yesterdayStreak = StreakCalculator.calculateStreak(
          habit,
          habitLogs,
          yesterday,
          habitShields,
        );

        if (yesterdayStreak.currentStreak > 0) {
          newShieldsToInsert.add(
            HabitShieldsCompanion(
              id: Value(_uuid.v4()),
              habitId: Value(habit.id),
              date: Value(targetDateStr),
              autoApplied: const Value(true),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
          shieldsByHabit.putIfAbsent(habit.id, () => []).add(
            HabitShield(
              id: 'temp',
              habitId: habit.id,
              date: targetDateStr,
              autoApplied: true,
              createdAt: now,
              updatedAt: now,
            ),
          );
          availableShields--;
          autoAppliedCount++;
        }
      }
    }

    if (newShieldsToInsert.isNotEmpty) {
      await habitShieldDao.insertShields(newShieldsToInsert);
    }

    return autoAppliedCount;
  }

  // Categories
  @override
  Stream<List<HabitCategory>> getAllCategories() => habitCategoryDao
      .watchAllCategories()
      .map((rows) => rows.map(_categoryRowToDomain).toList());

  @override
  Future<List<HabitCategory>> getAllCategoriesOnce() async {
    final rows = await habitCategoryDao.getAllCategoriesOnce();
    return rows.map(_categoryRowToDomain).toList();
  }

  @override
  Stream<HabitCategory?> getCategoryById(String id) => habitCategoryDao
      .watchCategoryById(id)
      .map((row) => row != null ? _categoryRowToDomain(row) : null);

  @override
  Future<void> upsertCategory(HabitCategory category) =>
      habitCategoryDao.upsertCategory(_categoryDomainToCompanion(category));

  @override
  Future<void> deleteCategory(HabitCategory category) =>
      habitCategoryDao.deleteCategoryById(category.id, DateTime.now().toUtc());
}
