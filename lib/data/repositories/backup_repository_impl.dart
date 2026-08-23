import 'dart:convert';
import 'package:drift/drift.dart';

import '../../domain/models/sync/sync_envelope.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/schedulers/habit_reminder_scheduler.dart';
import '../../domain/sync/sync_merge_engine.dart';
import '../local/app_database.dart';
import '../local/converters/entity_mappers.dart';
import '../local/daos/gamification_dao.dart';
import '../local/daos/habit_category_dao.dart';
import '../local/daos/habit_dao.dart';
import '../local/daos/habit_log_dao.dart';
import '../local/daos/habit_shield_dao.dart';
import '../preferences/theme_mode.dart';
import '../preferences/theme_preferences.dart';

class BackupRepositoryImpl implements BackupRepository {
  final AppDatabase db;
  final HabitDao habitDao;
  final HabitLogDao habitLogDao;
  final HabitShieldDao habitShieldDao;
  final HabitCategoryDao habitCategoryDao;
  final GamificationDao gamificationDao;
  final HabitReminderScheduler reminderScheduler;
  final ThemePreferences? themePreferences;
  final DateTime Function()? clock;

  BackupRepositoryImpl({
    required this.db,
    required this.habitDao,
    required this.habitLogDao,
    required this.habitShieldDao,
    required this.habitCategoryDao,
    required this.gamificationDao,
    required this.reminderScheduler,
    this.themePreferences,
    this.clock,
  });

  DateTime get _now => (clock != null ? clock!() : DateTime.now()).toUtc();

  Future<SyncDataPayload> _extractLocalPayload() async {
    final catRows = await habitCategoryDao.getAllCategoriesIncludingDeleted();
    final habitRows = await habitDao.getAllHabitsIncludingDeleted();
    final logRows = await habitLogDao.getAllLogsIncludingDeleted();
    final shieldRows = await habitShieldDao.getAllShieldsIncludingDeleted();
    final userGam = await gamificationDao.getUserGamificationOnce();
    final achRows = await gamificationDao.getAllAchievementsOnce();

    final preferences = <String, dynamic>{
      'userName': themePreferences?.loadUserName() ?? '',
      'themeMode': themePreferences?.loadThemeMode().name ?? 'system',
      'focusDndEnabled': themePreferences?.loadFocusDndEnabled() ?? false,
      'ambientSoundType': themePreferences?.loadAmbientSoundType() ?? 'none',
      'ambientSoundVolume': themePreferences?.loadAmbientSoundVolume() ?? 0.7,
    };

    final localCategories = catRows.map((r) => r.toDomain()).toList();
    final localHabits = habitRows.map((r) => r.toDomain()).toList();
    final localLogs = logRows.map((r) => r.toDomain()).toList();
    final localShields = shieldRows.map((r) => r.toDomain()).toList();
    final localAchievements = achRows
        .map(
          (a) => SyncAchievement(
            id: a.id,
            unlockedAt: a.unlockedAt,
            progress: a.progress,
            notified: a.notified,
            createdAt: a.createdAt,
            updatedAt: a.updatedAt,
          ),
        )
        .toList();

    // Recompute fact-based XP, Level, and celebration milestones
    final selfMerge = SyncMergeEngine.merge(
      local: SyncDataPayload(
        categories: localCategories,
        habits: localHabits,
        logs: localLogs,
        shields: localShields,
        gamification: userGam != null
            ? SyncUserGamification(
                totalXp: userGam.totalXp,
                currentLevel: userGam.currentLevel,
                lastCelebratedLevel: userGam.lastCelebratedLevel,
                maxShieldsCapacity: userGam.maxShieldsCapacity,
                autoConsumeShields: userGam.autoConsumeShields,
                updatedAt: userGam.updatedAt,
              )
            : const SyncUserGamification(),
        achievements: localAchievements,
      ),
      remote: const SyncDataPayload(),
      clock: clock,
    );

    final computedGam = selfMerge.mergedPayload.gamification;

    return SyncDataPayload(
      categories: localCategories,
      habits: localHabits,
      logs: localLogs,
      shields: localShields,
      gamification: computedGam,
      achievements: selfMerge.mergedPayload.achievements,
      preferences: preferences,
    );
  }

  @override
  Future<SyncEnvelope> createSnapshot({String? deviceId}) async {
    final payload = await _extractLocalPayload();
    return SyncEnvelope(
      exportedAt: _now,
      deviceId: deviceId ?? 'phial_device',
      data: payload,
    );
  }

  @override
  Future<String> exportBackupJson({String? deviceId}) async {
    final envelope = await createSnapshot(deviceId: deviceId);
    return envelope.toFormattedJson();
  }

  @override
  Future<MergeResult> previewImport(String jsonString) async {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final envelope = SyncEnvelope.fromJson(jsonMap);
    final local = await _extractLocalPayload();
    return SyncMergeEngine.merge(local: local, remote: envelope.data, clock: clock);
  }

  Future<void> _restorePreferences(Map<String, dynamic> prefs, {required bool isOverwrite}) async {
    if (prefs.isEmpty || themePreferences == null) return;
    if (prefs.containsKey('userName') && prefs['userName'] is String) {
      final name = prefs['userName'] as String;
      if (name.isNotEmpty || isOverwrite) {
        await themePreferences!.setUserName(name);
      }
    }
    if (prefs.containsKey('themeMode') && prefs['themeMode'] is String) {
      try {
        final modeEnum = AppThemeMode.values.firstWhere(
          (e) => e.name == prefs['themeMode'],
        );
        await themePreferences!.setThemeMode(modeEnum);
      } catch (_) {}
    }
    if (prefs.containsKey('focusDndEnabled') && prefs['focusDndEnabled'] is bool) {
      await themePreferences!.setFocusDndEnabled(prefs['focusDndEnabled'] as bool);
    }
    if (prefs.containsKey('ambientSoundType') && prefs['ambientSoundType'] is String) {
      await themePreferences!.setAmbientSoundType(prefs['ambientSoundType'] as String);
    }
    if (prefs.containsKey('ambientSoundVolume') && prefs['ambientSoundVolume'] is num) {
      await themePreferences!.setAmbientSoundVolume((prefs['ambientSoundVolume'] as num).toDouble());
    }
  }

  @override
  Future<MergeStats> executeImport(String jsonString, {required ImportMode mode}) async {
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final envelope = SyncEnvelope.fromJson(jsonMap);

    if (mode == ImportMode.overwrite) {
      final payload = envelope.data;
      await db.transaction(() async {
        await db.habitLogs.deleteAll();
        await db.habitShields.deleteAll();
        await db.habits.deleteAll();
        await db.habitCategories.deleteAll();
        await db.achievements.deleteAll();
        await db.userGamification.deleteAll();

        await db.batch((b) {
          b.insertAll(db.habitCategories, payload.categories.map((c) => c.toCompanion(_now)).toList());
          b.insertAll(db.habits, payload.habits.map((h) => h.toCompanion()).toList());
          b.insertAll(db.habitLogs, payload.logs.map((l) => l.toCompanion()).toList());
          b.insertAll(db.habitShields, payload.shields.map((s) => s.toCompanion()).toList());
          b.insertAll(
            db.achievements,
            payload.achievements.map((a) => AchievementsCompanion(
                  id: Value(a.id),
                  unlockedAt: Value(a.unlockedAt),
                  progress: Value(a.progress),
                  notified: Value(a.notified),
                  createdAt: Value(a.createdAt ?? _now),
                  updatedAt: Value(a.updatedAt ?? _now),
                )).toList(),
          );
        });

        await db.userGamification.insertOne(
          UserGamificationCompanion(
            id: const Value('user_gamification'),
            totalXp: Value(payload.gamification.totalXp),
            currentLevel: Value(payload.gamification.currentLevel),
            lastCelebratedLevel: Value(payload.gamification.lastCelebratedLevel),
            maxShieldsCapacity: Value(payload.gamification.maxShieldsCapacity),
            autoConsumeShields: Value(payload.gamification.autoConsumeShields),
            updatedAt: Value(payload.gamification.updatedAt ?? _now),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });

      await _restorePreferences(envelope.data.preferences, isOverwrite: true);
      await reminderScheduler.rescheduleAll();

      return MergeStats(
        habitsAdded: payload.habits.where((h) => !h.isDeleted).length,
        logsMerged: payload.logs.where((l) => !l.isDeleted).length,
        shieldsMerged: payload.shields.where((s) => !s.isDeleted).length,
        categoriesAdded: payload.categories.where((c) => !c.isDeleted).length,
        totalXp: payload.gamification.totalXp,
        level: payload.gamification.currentLevel,
      );
    } else {
      // Merge mode
      final local = await _extractLocalPayload();
      final mergeResult = SyncMergeEngine.merge(local: local, remote: envelope.data, clock: clock);
      final payload = mergeResult.mergedPayload;

      await db.transaction(() async {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(
            db.habitCategories,
            payload.categories.map((c) => c.toCompanion(_now)).toList(),
          );
          b.insertAllOnConflictUpdate(
            db.habits,
            payload.habits.map((h) => h.toCompanion()).toList(),
          );
          b.insertAllOnConflictUpdate(
            db.habitLogs,
            payload.logs.map((l) => l.toCompanion()).toList(),
          );
          b.insertAllOnConflictUpdate(
            db.habitShields,
            payload.shields.map((s) => s.toCompanion()).toList(),
          );
          b.insertAllOnConflictUpdate(
            db.achievements,
            payload.achievements.map((a) => AchievementsCompanion(
                  id: Value(a.id),
                  unlockedAt: Value(a.unlockedAt),
                  progress: Value(a.progress),
                  notified: Value(a.notified),
                  createdAt: Value(a.createdAt ?? _now),
                  updatedAt: Value(a.updatedAt ?? _now),
                )).toList(),
          );
        });

        await db.userGamification.insertOne(
          UserGamificationCompanion(
            id: const Value('user_gamification'),
            totalXp: Value(payload.gamification.totalXp),
            currentLevel: Value(payload.gamification.currentLevel),
            lastCelebratedLevel: Value(payload.gamification.lastCelebratedLevel),
            maxShieldsCapacity: Value(payload.gamification.maxShieldsCapacity),
            autoConsumeShields: Value(payload.gamification.autoConsumeShields),
            updatedAt: Value(payload.gamification.updatedAt ?? _now),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });

      await _restorePreferences(envelope.data.preferences, isOverwrite: false);
      await reminderScheduler.rescheduleAll();
      return mergeResult.stats;
    }
  }

  @override
  Future<String> exportHabitsCsv() async {
    final habits = await habitDao.getActiveHabitsOnce();
    final categories = await habitCategoryDao.getAllCategoriesOnce();
    final categoryMap = {for (var c in categories) c.id: c.name};

    final buffer = StringBuffer();
    buffer.writeln('id,title,category,frequency,targetType,targetValue,unit,pinned,archived,createdAt');

    for (final h in habits) {
      final catName = (h.categoryId != null ? categoryMap[h.categoryId] : '') ?? '';
      final titleEscaped = '"${h.title.replaceAll('"', '""')}"';
      buffer.writeln(
        '${h.id},$titleEscaped,"$catName",${h.frequencyType.name},${h.targetType.name},${h.targetValue ?? ''},"${h.unit ?? ''}",${h.pinned},${h.archived},${h.createdAt.toIso8601String()}',
      );
    }

    return buffer.toString();
  }

  @override
  Future<String> exportLogsCsv() async {
    final logs = await habitLogDao.getAllLogsOnce();
    final habits = await habitDao.getAllHabitsIncludingDeleted();
    final habitMap = {for (var h in habits) h.id: h.title};

    final buffer = StringBuffer();
    buffer.writeln('id,habitId,habitTitle,date,timestamp,intervalIndex,completed,value,durationSeconds,energyLevel,mood,note');

    for (final l in logs) {
      final habitTitle = habitMap[l.habitId] ?? '';
      final titleEscaped = '"${habitTitle.replaceAll('"', '""')}"';
      final noteEscaped = '"${(l.note ?? '').replaceAll('"', '""')}"';
      buffer.writeln(
        '${l.id},${l.habitId},$titleEscaped,${l.date},${l.timestamp.toIso8601String()},${l.intervalIndex ?? ''},${l.completed},${l.value ?? ''},${l.durationSeconds ?? ''},${l.energyLevel ?? ''},"${l.mood ?? ''}",$noteEscaped',
      );
    }

    return buffer.toString();
  }
}
