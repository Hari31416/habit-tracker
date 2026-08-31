import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/local/app_database.dart';
import 'package:habit_tracker/data/local/converters/entity_mappers.dart';
import 'package:habit_tracker/data/preferences/theme_preferences.dart';
import 'package:habit_tracker/data/repositories/backup_repository_impl.dart';
import 'package:habit_tracker/data/repositories/gamification_repository_impl.dart';
import 'package:habit_tracker/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/data/schedulers/no_op_habit_reminder_scheduler.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_category.dart';
import 'package:habit_tracker/domain/models/habit_log.dart';
import 'package:habit_tracker/domain/models/habit_routine.dart';
import 'package:habit_tracker/domain/models/habit_shield.dart';
import 'package:habit_tracker/domain/models/routine_log.dart';
import 'package:habit_tracker/domain/repositories/backup_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/contract_fixtures.dart';

const _goldenPath = 'test/goldens/sync/envelope_full.json';

void main() {
  late AppDatabase db;
  late HabitRepositoryImpl habitRepository;
  late BackupRepositoryImpl backupRepository;
  late GamificationRepositoryImpl gamificationRepository;
  late ThemePreferences themePreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(
      Map<String, Object>.from(kContractPreferenceSeed),
    );
    final prefs = await SharedPreferences.getInstance();
    themePreferences = ThemePreferences(prefs);

    db = AppDatabase(NativeDatabase.memory());
    habitRepository = HabitRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
    );
    backupRepository = BackupRepositoryImpl(
      db: db,
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
      themePreferences: themePreferences,
      clock: () => kContractClock,
    );
    gamificationRepository = GamificationRepositoryImpl(
      habitDao: db.habitDao,
      habitLogDao: db.habitLogDao,
      habitShieldDao: db.habitShieldDao,
      habitCategoryDao: db.habitCategoryDao,
      gamificationDao: db.gamificationDao,
      routineDao: db.routineDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('full fixture survives habit, gamification, export golden, and overwrite import',
      () async {
    await _seedContractState(db, habitRepository);

    final expectedHabit = ContractFixtures.habit();
    final expectedLog = ContractFixtures.log();
    final expectedCategory = ContractFixtures.category();
    final expectedShield = ContractFixtures.shield();
    final expectedRoutine = ContractFixtures.routine();
    final expectedRoutineLog = ContractFixtures.routineLog();

    final habitFromRepo =
        await habitRepository.getHabitByIdOnce(ContractFixtures.habitId);
    expect(habitFromRepo, isNotNull);
    _assertHabit(habitFromRepo!, expectedHabit);

    final logsFromRepo =
        await habitRepository.getLogsForHabitOnce(ContractFixtures.habitId);
    expect(logsFromRepo, hasLength(1));
    _assertLog(logsFromRepo.single, expectedLog);

    final categories = await habitRepository.getAllCategoriesOnce();
    final categoryFromRepo = categories.firstWhere(
      (c) => c.id == ContractFixtures.categoryId,
    );
    _assertCategory(categoryFromRepo, expectedCategory);

    final shields = await habitRepository.getAllShieldsOnce();
    expect(shields, hasLength(1));
    _assertShield(shields.single, expectedShield);

    final routineRows = await db.routineDao.getAllRoutinesIncludingDeleted();
    expect(routineRows, hasLength(1));
    _assertRoutine(routineRows.single.toDomain(), expectedRoutine);

    final routineLogRows = await db.routineDao.getAllRoutineLogsIncludingDeleted();
    expect(routineLogRows, hasLength(1));
    _assertRoutineLog(routineLogRows.single.toDomain(), expectedRoutineLog);

    final habitRows = await db.habitDao.getAllHabitsIncludingDeleted();
    final mappedHabit = gamificationRepository.habitFromRow(
      habitRows.firstWhere((r) => r.id == ContractFixtures.habitId),
    );
    _assertHabit(mappedHabit, expectedHabit);

    final logRows = await db.habitLogDao.getAllLogsIncludingDeleted();
    final mappedLog = gamificationRepository.logFromRow(
      logRows.firstWhere((r) => r.id == ContractFixtures.logId),
    );
    _assertLog(mappedLog, expectedLog);

    // Verify companion roundtrip for new tables via entity_mappers
    final routineCompanion = expectedRoutine.toCompanion();
    expect(routineCompanion.id.value, expectedRoutine.id);
    expect(routineCompanion.habitIds.value, expectedRoutine.habitIds);
    final routineLogCompanion = expectedRoutineLog.toCompanion();
    expect(routineLogCompanion.id.value, expectedRoutineLog.id);
    expect(routineLogCompanion.xpEarned.value, expectedRoutineLog.xpEarned);

    final exported = await backupRepository.exportBackupJson(
      deviceId: kContractDeviceId,
    );
    final decoded = jsonDecode(exported) as Map<String, dynamic>;
    _stabilizeComputedTimestamps(decoded);
    _assertEnvelopeKeys(decoded);
    _assertGolden(decoded);

    final restoreDb = AppDatabase(NativeDatabase.memory());
    addTearDown(restoreDb.close);
    SharedPreferences.setMockInitialValues({});
    final restorePrefs = ThemePreferences(await SharedPreferences.getInstance());
    final restoreHabits = HabitRepositoryImpl(
      habitDao: restoreDb.habitDao,
      habitLogDao: restoreDb.habitLogDao,
      habitShieldDao: restoreDb.habitShieldDao,
      habitCategoryDao: restoreDb.habitCategoryDao,
      gamificationDao: restoreDb.gamificationDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
    );
    final restoreBackup = BackupRepositoryImpl(
      db: restoreDb,
      habitDao: restoreDb.habitDao,
      habitLogDao: restoreDb.habitLogDao,
      habitShieldDao: restoreDb.habitShieldDao,
      habitCategoryDao: restoreDb.habitCategoryDao,
      gamificationDao: restoreDb.gamificationDao,
      reminderScheduler: const NoOpHabitReminderScheduler(),
      themePreferences: restorePrefs,
      clock: () => kContractClock,
    );
    final restoreGamification = GamificationRepositoryImpl(
      habitDao: restoreDb.habitDao,
      habitLogDao: restoreDb.habitLogDao,
      habitShieldDao: restoreDb.habitShieldDao,
      habitCategoryDao: restoreDb.habitCategoryDao,
      gamificationDao: restoreDb.gamificationDao,
      routineDao: restoreDb.routineDao,
    );

    await restoreBackup.executeImport(exported, mode: ImportMode.overwrite);

    final restoredHabit =
        await restoreHabits.getHabitByIdOnce(ContractFixtures.habitId);
    expect(restoredHabit, isNotNull);
    _assertHabit(restoredHabit!, expectedHabit);

    final restoredLogs =
        await restoreHabits.getLogsForHabitOnce(ContractFixtures.habitId);
    expect(restoredLogs, hasLength(1));
    _assertLog(restoredLogs.single, expectedLog);

    final restoredCategory = (await restoreHabits.getAllCategoriesOnce())
        .firstWhere((c) => c.id == ContractFixtures.categoryId);
    _assertCategory(restoredCategory, expectedCategory);

    final restoredShields = await restoreHabits.getAllShieldsOnce();
    expect(restoredShields, hasLength(1));
    _assertShield(restoredShields.single, expectedShield);

    final restoredRoutineRows = await restoreDb.routineDao.getAllRoutinesIncludingDeleted();
    expect(restoredRoutineRows, hasLength(1));
    _assertRoutine(restoredRoutineRows.single.toDomain(), expectedRoutine);

    final restoredRoutineLogRows = await restoreDb.routineDao.getAllRoutineLogsIncludingDeleted();
    expect(restoredRoutineLogRows, hasLength(1));
    _assertRoutineLog(restoredRoutineLogRows.single.toDomain(), expectedRoutineLog);

    final restoredHabitRows =
        await restoreDb.habitDao.getAllHabitsIncludingDeleted();
    _assertHabit(
      restoreGamification.habitFromRow(
        restoredHabitRows.firstWhere((r) => r.id == ContractFixtures.habitId),
      ),
      expectedHabit,
    );
    final restoredLogRows =
        await restoreDb.habitLogDao.getAllLogsIncludingDeleted();
    _assertLog(
      restoreGamification.logFromRow(
        restoredLogRows.firstWhere((r) => r.id == ContractFixtures.logId),
      ),
      expectedLog,
    );

    expect(restorePrefs.loadUserName(), 'ContractUser');
    expect(restorePrefs.loadThemeMode().name, 'dark');
    expect(restorePrefs.loadFocusDndEnabled(), isTrue);
    expect(restorePrefs.loadAmbientSoundType(), 'rain');
    expect(restorePrefs.loadAmbientSoundVolume(), 0.42);
  });
}

Future<void> _seedContractState(
  AppDatabase db,
  HabitRepositoryImpl habitRepository,
) async {
  await habitRepository.upsertCategory(ContractFixtures.category());
  await habitRepository.upsertHabit(ContractFixtures.habit());
  final routine = ContractFixtures.routine();
  await db.routineDao.upsertRoutine(routine.toCompanion());
  final routineLog = ContractFixtures.routineLog();
  await db.routineDao.upsertRoutineLog(routineLog.toCompanion());

  final log = ContractFixtures.log();
  await db.habitLogDao.upsertLog(
    HabitLogsCompanion(
      id: Value(log.id),
      habitId: Value(log.habitId),
      date: Value(log.date),
      timestamp: Value(log.timestamp),
      intervalIndex: Value(log.intervalIndex),
      completed: Value(log.completed),
      value: Value(log.value),
      durationSeconds: Value(log.durationSeconds),
      targetTier: Value(log.targetTier),
      note: Value(log.note),
      energyLevel: Value(log.energyLevel),
      mood: Value(log.mood),
      isDeleted: Value(log.isDeleted),
      createdAt: Value(log.createdAt),
      updatedAt: Value(log.updatedAt),
    ),
  );

  final shield = ContractFixtures.shield();
  await db.habitShieldDao.upsertShield(
    HabitShieldsCompanion(
      id: Value(shield.id),
      habitId: Value(shield.habitId),
      date: Value(shield.date),
      autoApplied: Value(shield.autoApplied),
      isDeleted: Value(shield.isDeleted),
      createdAt: Value(shield.createdAt),
      updatedAt: Value(shield.updatedAt),
    ),
  );

  final achievement = ContractFixtures.achievement();
  await db.gamificationDao.upsertAchievement(
    AchievementsCompanion(
      id: Value(achievement.id),
      unlockedAt: Value(achievement.unlockedAt),
      progress: Value(achievement.progress),
      notified: Value(achievement.notified),
      createdAt: Value(achievement.createdAt ?? kContractCreatedAt),
      updatedAt: Value(achievement.updatedAt ?? kContractUpdatedAt),
    ),
  );

  await db.gamificationDao.upsertUserGamification(
    UserGamificationCompanion(
      id: const Value('user_gamification'),
      lastCelebratedLevel: const Value(ContractFixtures.lastCelebratedLevel),
      maxShieldsCapacity: const Value(ContractFixtures.maxShieldsCapacity),
      autoConsumeShields: const Value(ContractFixtures.autoConsumeShields),
      updatedAt: Value(kContractUpdatedAt),
    ),
  );
}

/// Merge evaluates new unlocks with `DateTime.now()`. Pin those to the contract clock.
void _stabilizeComputedTimestamps(Map<String, dynamic> decoded) {
  final data = decoded['data'] as Map<String, dynamic>;
  final achievements =
      (data['achievements'] as List).cast<Map<String, dynamic>>();
  final fixtureUnlock = kContractAchievementUnlockedAt.toUtc().toIso8601String();
  final clock = kContractClock.toUtc().toIso8601String();
  for (final achievement in achievements) {
    if (achievement['unlockedAt'] != fixtureUnlock) {
      achievement['unlockedAt'] = clock;
    }
  }
}

void _assertEnvelopeKeys(Map<String, dynamic> decoded) {
  final data = decoded['data'] as Map<String, dynamic>;
  final habits = (data['habits'] as List).cast<Map<String, dynamic>>();
  final habitJson = habits.firstWhere(
    (h) => h['id'] == ContractFixtures.habitId,
  );
  expect(habitJson.keys.toSet(), equals(kHabitJsonKeys.toSet()));

  final logs = (data['logs'] as List).cast<Map<String, dynamic>>();
  final logJson = logs.firstWhere((l) => l['id'] == ContractFixtures.logId);
  expect(logJson.keys.toSet(), equals(kLogJsonKeys.toSet()));

  final categories = (data['categories'] as List).cast<Map<String, dynamic>>();
  final categoryJson = categories.firstWhere(
    (c) => c['id'] == ContractFixtures.categoryId,
  );
  expect(categoryJson.keys.toSet(), equals(kCategoryJsonKeys.toSet()));

  final shields = (data['shields'] as List).cast<Map<String, dynamic>>();
  final shieldJson = shields.firstWhere(
    (s) => s['id'] == ContractFixtures.shieldId,
  );
  expect(shieldJson.keys.toSet(), equals(kShieldJsonKeys.toSet()));

  final routines = (data['routines'] as List).cast<Map<String, dynamic>>();
  final routineJson = routines.firstWhere((r) => r['id'] == ContractFixtures.routineId);
  expect(routineJson.keys.toSet(), equals(kRoutineJsonKeys.toSet()));
  expect(routineJson['targetTimeWindow'], isA<Map<String, dynamic>>());
  final routineLogs = (data['routineLogs'] as List).cast<Map<String, dynamic>>();
  final routineLogJson = routineLogs.firstWhere((r) => r['id'] == ContractFixtures.routineLogId);
  expect(routineLogJson.keys.toSet(), equals(kRoutineLogJsonKeys.toSet()));

  final gamification = data['gamification'] as Map<String, dynamic>;
  expect(gamification.keys.toSet(), equals(kGamificationJsonKeys.toSet()));

  final achievements = (data['achievements'] as List).cast<Map<String, dynamic>>();
  for (final achievement in achievements) {
    expect(achievement.keys.toSet(), equals(kAchievementJsonKeys.toSet()));
  }
}

void _assertGolden(Map<String, dynamic> decoded) {
  final encoded = _encodeCanonical(decoded);
  final file = File(_goldenPath);
  if (!file.existsSync()) {
    file.createSync(recursive: true);
    file.writeAsStringSync('$encoded\n');
    fail('Wrote new golden at $_goldenPath. Re-run this test.');
  }
  expect(
    encoded,
    equals(file.readAsStringSync().replaceAll('\r\n', '\n').trimRight()),
  );
}

String _encodeCanonical(Object? value) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(_canonicalize(value)).trimRight();
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return {
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is List) {
    final items = value.map(_canonicalize).toList();
    if (items.isNotEmpty &&
        items.first is Map &&
        (items.first as Map).containsKey('id')) {
      items.sort((a, b) {
        final aId = (a as Map)['id'].toString();
        final bId = (b as Map)['id'].toString();
        return aId.compareTo(bId);
      });
    }
    return items;
  }
  return value;
}

void _assertHabit(Habit actual, Habit expected) {
  expect(actual.id, expected.id);
  expect(actual.title, expected.title);
  expect(actual.description, expected.description);
  expect(actual.color, expected.color);
  expect(actual.icon, expected.icon);
  expect(actual.categoryId, expected.categoryId);
  expect(actual.frequencyType, expected.frequencyType);
  expect(actual.targetDaysOfWeek, expected.targetDaysOfWeek);
  expect(actual.targetCountPerWeek, expected.targetCountPerWeek);
  expect(actual.intervalHours, expected.intervalHours);
  expect(actual.timesPerDay, expected.timesPerDay);
  expect(actual.timeWindow, expected.timeWindow);
  expect(actual.targetType, expected.targetType);
  expect(actual.targetValue, expected.targetValue);
  expect(actual.miniTargetValue, expected.miniTargetValue);
  expect(actual.eliteTargetValue, expected.eliteTargetValue);
  expect(actual.unit, expected.unit);
  expect(actual.pinned, expected.pinned);
  expect(actual.reminderTimes, expected.reminderTimes);
  expect(actual.motivationNotes, expected.motivationNotes);
  expect(actual.archived, expected.archived);
  expect(actual.promptReflection, expected.promptReflection);
  expect(actual.healthMetric, expected.healthMetric);
  expect(actual.healthSyncEnabled, expected.healthSyncEnabled);
  expect(actual.isNegative, expected.isNegative);
  _assertUtc(actual.cleanSince, expected.cleanSince, name: 'habit.cleanSince');
  expect(actual.isDeleted, expected.isDeleted);
  _assertUtc(actual.createdAt, expected.createdAt, name: 'habit.createdAt');
  _assertUtc(actual.updatedAt, expected.updatedAt, name: 'habit.updatedAt');
}

void _assertLog(HabitLog actual, HabitLog expected) {
  expect(actual.id, expected.id);
  expect(actual.habitId, expected.habitId);
  expect(actual.date, expected.date);
  _assertUtc(actual.timestamp, expected.timestamp, name: 'log.timestamp');
  expect(actual.intervalIndex, expected.intervalIndex);
  expect(actual.completed, expected.completed);
  expect(actual.value, expected.value);
  expect(actual.durationSeconds, expected.durationSeconds);
  expect(actual.targetTier, expected.targetTier);
  expect(actual.note, expected.note);
  expect(actual.energyLevel, expected.energyLevel);
  expect(actual.mood, expected.mood);
  expect(actual.isDeleted, expected.isDeleted);
  _assertUtc(actual.createdAt, expected.createdAt, name: 'log.createdAt');
  _assertUtc(actual.updatedAt, expected.updatedAt, name: 'log.updatedAt');
}

void _assertCategory(HabitCategory actual, HabitCategory expected) {
  expect(actual.id, expected.id);
  expect(actual.name, expected.name);
  expect(actual.color, expected.color);
  expect(actual.icon, expected.icon);
  expect(actual.isDeleted, expected.isDeleted);
  _assertUtc(actual.createdAt, expected.createdAt, name: 'category.createdAt');
  _assertUtc(actual.updatedAt, expected.updatedAt, name: 'category.updatedAt');
}

void _assertShield(HabitShield actual, HabitShield expected) {
  expect(actual.id, expected.id);
  expect(actual.habitId, expected.habitId);
  expect(actual.date, expected.date);
  expect(actual.autoApplied, expected.autoApplied);
  expect(actual.isDeleted, expected.isDeleted);
  _assertUtc(actual.createdAt, expected.createdAt, name: 'shield.createdAt');
  _assertUtc(actual.updatedAt, expected.updatedAt, name: 'shield.updatedAt');
}

void _assertRoutine(HabitRoutine actual, HabitRoutine expected) {
  expect(actual.id, expected.id);
  expect(actual.title, expected.title);
  expect(actual.description, expected.description);
  expect(actual.color, expected.color);
  expect(actual.icon, expected.icon);
  expect(actual.targetTimeWindow, expected.targetTimeWindow);
  expect(actual.habitIds, expected.habitIds);
  expect(actual.bonusXp, expected.bonusXp);
  expect(actual.isDeleted, expected.isDeleted);
  _assertUtc(actual.createdAt, expected.createdAt, name: 'routine.createdAt');
  _assertUtc(actual.updatedAt, expected.updatedAt, name: 'routine.updatedAt');
}

void _assertRoutineLog(RoutineLog actual, RoutineLog expected) {
  expect(actual.id, expected.id);
  expect(actual.routineId, expected.routineId);
  expect(actual.date, expected.date);
  _assertUtc(actual.completedAt, expected.completedAt, name: 'routineLog.completedAt');
  expect(actual.completedHabitIds, expected.completedHabitIds);
  expect(actual.xpEarned, expected.xpEarned);
  expect(actual.isDeleted, expected.isDeleted);
  _assertUtc(actual.createdAt, expected.createdAt, name: 'routineLog.createdAt');
  _assertUtc(actual.updatedAt, expected.updatedAt, name: 'routineLog.updatedAt');
}

void _assertUtc(DateTime? actual, DateTime? expected, {required String name}) {
  if (expected == null) {
    expect(actual, isNull, reason: name);
    return;
  }
  expect(actual, isNotNull, reason: name);
  expect(
    actual!.toUtc().millisecondsSinceEpoch,
    expected.toUtc().millisecondsSinceEpoch,
    reason: name,
  );
}
