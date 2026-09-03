import 'dart:convert';
import '../habit.dart';
import '../habit_category.dart';
import '../habit_frequency_type.dart';
import '../habit_log.dart';
import '../habit_routine.dart';
import '../habit_shield.dart';
import '../habit_target_type.dart';
import '../habit_tier.dart';
import '../health/health_metric_type.dart';
import '../routine_log.dart';
import '../time_window.dart';

DateTime? _parseDateTime(dynamic raw, String field) {
  if (raw == null) return null;
  if (raw is! String) {
    throw FormatException('Invalid backup: bad date for $field');
  }
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw FormatException('Invalid backup: bad date for $field');
  }
  return parsed.toUtc();
}

DateTime _parseDateTimeOrNow(dynamic raw, String field) {
  final parsed = _parseDateTime(raw, field);
  return parsed ?? DateTime.now().toUtc();
}

String _requireId(Map<String, dynamic> j, String field) {
  final v = j[field];
  if (v is! String ||
      v.isEmpty ||
      v.length > SyncEnvelope.maxIdLength) {
    throw FormatException('Invalid backup record: bad $field');
  }
  return v;
}

String _requireString(Map<String, dynamic> j, String field) {
  final v = j[field];
  if (v is! String || v.isEmpty) {
    throw FormatException('Invalid backup record: bad $field');
  }
  return v;
}

List<dynamic> _requireRecordList(Map<String, dynamic> json, String field) {
  final raw = json[field];
  if (raw == null) return const [];
  if (raw is! List) {
    throw FormatException('Invalid backup: $field must be a list');
  }
  if (raw.length > SyncEnvelope.maxRecordsPerList) {
    throw FormatException('Invalid backup: $field exceeds record limit');
  }
  return raw;
}

Map<String, dynamic> _asRecord(dynamic raw, String field) {
  if (raw is! Map<String, dynamic>) {
    throw FormatException('Invalid backup: bad record in $field');
  }
  return raw;
}

/// Top-level envelope for local backups and cloud sync snapshots.
class SyncEnvelope {
  static const int currentSchemaVersion = 1;
  static const String defaultAppVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  /// Upper bound on records per list to bound memory on crafted imports.
  static const int maxRecordsPerList = 100000;

  /// Upper bound on id / deviceId string lengths.
  static const int maxIdLength = 128;

  final int schemaVersion;
  final String appVersion;
  final DateTime exportedAt;
  final String deviceId;
  final SyncDataPayload data;

  const SyncEnvelope({
    this.schemaVersion = currentSchemaVersion,
    this.appVersion = defaultAppVersion,
    required this.exportedAt,
    required this.deviceId,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'appVersion': appVersion,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'deviceId': deviceId,
        'data': data.toJson(),
      };

  factory SyncEnvelope.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported backup schemaVersion: $schemaVersion '
        '(expected $currentSchemaVersion)',
      );
    }
    final deviceId = json['deviceId'];
    if (deviceId is! String || deviceId.isEmpty || deviceId.length > maxIdLength) {
      throw const FormatException('Invalid backup: missing or invalid deviceId');
    }
    final exportedAtRaw = json['exportedAt'];
    final exportedAt = _parseDateTime(exportedAtRaw, 'exportedAt');
    if (exportedAt == null) {
      throw const FormatException('Invalid backup: missing exportedAt');
    }
    final dataRaw = json['data'];
    if (dataRaw is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup: missing data payload');
    }
    return SyncEnvelope(
      schemaVersion: currentSchemaVersion,
      appVersion: json['appVersion'] as String? ?? defaultAppVersion,
      exportedAt: exportedAt.toUtc(),
      deviceId: deviceId,
      data: SyncDataPayload.fromJson(dataRaw),
    );
  }

  String toFormattedJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Payload containing full relational state for sync and backup.
class SyncDataPayload {
  final List<HabitCategory> categories;
  final List<Habit> habits;
  final List<HabitLog> logs;
  final List<HabitShield> shields;
  final List<HabitRoutine> routines;
  final List<RoutineLog> routineLogs;
  final SyncUserGamification gamification;
  final List<SyncAchievement> achievements;
  final Map<String, dynamic> preferences;

  const SyncDataPayload({
    this.categories = const [],
    this.habits = const [],
    this.logs = const [],
    this.shields = const [],
    this.routines = const [],
    this.routineLogs = const [],
    this.gamification = const SyncUserGamification(),
    this.achievements = const [],
    this.preferences = const {},
  });

  Map<String, dynamic> toJson() => {
        'categories': categories.map(_categoryToJson).toList(),
        'habits': habits.map(_habitToJson).toList(),
        'logs': logs.map(_logToJson).toList(),
        'shields': shields.map(_shieldToJson).toList(),
        if (routines.isNotEmpty) 'routines': routines.map(_routineToJson).toList(),
        if (routineLogs.isNotEmpty) 'routineLogs': routineLogs.map(_routineLogToJson).toList(),
        'gamification': gamification.toJson(),
        'achievements': achievements.map((a) => a.toJson()).toList(),
        'preferences': preferences,
      };

  factory SyncDataPayload.fromJson(Map<String, dynamic> json) {
    final rawCats = _requireRecordList(json, 'categories');
    final rawHabits = _requireRecordList(json, 'habits');
    final rawLogs = _requireRecordList(json, 'logs');
    final rawShields = _requireRecordList(json, 'shields');
    final rawRoutines = _requireRecordList(json, 'routines');
    final rawRoutineLogs = _requireRecordList(json, 'routineLogs');
    final rawAch = _requireRecordList(json, 'achievements');

    return SyncDataPayload(
      categories: rawCats
          .map((c) => _categoryFromJson(_asRecord(c, 'categories')))
          .toList(),
      habits: rawHabits
          .map((h) => _habitFromJson(_asRecord(h, 'habits')))
          .toList(),
      logs: rawLogs
          .map((l) => _logFromJson(_asRecord(l, 'logs')))
          .toList(),
      shields: rawShields
          .map((s) => _shieldFromJson(_asRecord(s, 'shields')))
          .toList(),
      routines: rawRoutines
          .map((r) => _routineFromJson(_asRecord(r, 'routines')))
          .toList(),
      routineLogs: rawRoutineLogs
          .map((rl) => _routineLogFromJson(_asRecord(rl, 'routineLogs')))
          .toList(),
      gamification: json['gamification'] != null
          ? SyncUserGamification.fromJson(
              _asRecord(json['gamification'], 'gamification'))
          : const SyncUserGamification(),
      achievements: rawAch
          .map((a) => SyncAchievement.fromJson(_asRecord(a, 'achievements')))
          .toList(),
      preferences: (json['preferences'] as Map<String, dynamic>?) ?? {},
    );
  }

  static Map<String, dynamic> _categoryToJson(HabitCategory c) => {
        'id': c.id,
        'name': c.name,
        'color': c.color,
        'icon': c.icon,
        'isDeleted': c.isDeleted,
        'createdAt': c.createdAt?.toUtc().toIso8601String(),
        'updatedAt': c.updatedAt?.toUtc().toIso8601String(),
      };

  static HabitCategory _categoryFromJson(Map<String, dynamic> j) => HabitCategory(
        id: _requireId(j, 'id'),
        name: _requireString(j, 'name'),
        color: _requireString(j, 'color'),
        icon: j['icon'] as String?,
        isDeleted: j['isDeleted'] as bool? ?? false,
        createdAt: _parseDateTime(j['createdAt'], 'createdAt'),
        updatedAt: _parseDateTime(j['updatedAt'], 'updatedAt'),
      );

  static Map<String, dynamic> _habitToJson(Habit h) => {
        'id': h.id,
        'title': h.title,
        'description': h.description,
        'color': h.color,
        'icon': h.icon,
        'categoryId': h.categoryId,
        'frequencyType': h.frequencyType.name,
        'targetDaysOfWeek': h.targetDaysOfWeek,
        'targetCountPerWeek': h.targetCountPerWeek,
        'intervalHours': h.intervalHours,
        'timesPerDay': h.timesPerDay,
        'timeWindow': h.timeWindow != null
            ? {'startTime': h.timeWindow!.startTime, 'endTime': h.timeWindow!.endTime}
            : null,
        'targetType': h.targetType.name,
        'targetValue': h.targetValue,
        'miniTargetValue': h.miniTargetValue,
        'eliteTargetValue': h.eliteTargetValue,
        'unit': h.unit,
        'pinned': h.pinned,
        'reminderTimes': h.reminderTimes,
        'motivationNotes': h.motivationNotes,
        'archived': h.archived,
        'promptReflection': h.promptReflection,
        'healthMetric': h.healthMetric?.id,
        'healthSyncEnabled': h.healthSyncEnabled,
        'isNegative': h.isNegative,
        'cleanSince': h.cleanSince?.toUtc().toIso8601String(),
        'isDeleted': h.isDeleted,
        'createdAt': h.createdAt.toUtc().toIso8601String(),
        'updatedAt': h.updatedAt.toUtc().toIso8601String(),
      };

  static Habit _habitFromJson(Map<String, dynamic> j) {
    return Habit(
      id: _requireId(j, 'id'),
      title: _requireString(j, 'title'),
      description: j['description'] as String?,
      color: _requireString(j, 'color'),
      icon: j['icon'] as String?,
      categoryId: j['categoryId'] as String?,
      frequencyType: HabitFrequencyType.values.firstWhere(
        (f) => f.name == (j['frequencyType'] as String?),
        orElse: () => HabitFrequencyType.daily,
      ),
      targetDaysOfWeek: (j['targetDaysOfWeek'] as List<dynamic>?)?.cast<int>(),
      targetCountPerWeek: j['targetCountPerWeek'] as int?,
      intervalHours: j['intervalHours'] as int?,
      timesPerDay: j['timesPerDay'] as int?,
      timeWindow: j['timeWindow'] is Map<String, dynamic>
          ? TimeWindow(
              startTime:
                  (j['timeWindow'] as Map<String, dynamic>)['startTime'] as String? ?? '08:00',
              endTime:
                  (j['timeWindow'] as Map<String, dynamic>)['endTime'] as String? ?? '20:00',
            )
          : null,
      targetType: HabitTargetType.values.firstWhere(
        (t) => t.name == (j['targetType'] as String?),
        orElse: () => HabitTargetType.boolean,
      ),
      targetValue: (j['targetValue'] as num?)?.toDouble(),
      miniTargetValue: (j['miniTargetValue'] as num?)?.toDouble(),
      eliteTargetValue: (j['eliteTargetValue'] as num?)?.toDouble(),
      unit: j['unit'] as String?,
      pinned: j['pinned'] as bool? ?? false,
      reminderTimes: (j['reminderTimes'] as List<dynamic>?)?.cast<String>() ?? const [],
      motivationNotes: j['motivationNotes'] as String?,
      archived: j['archived'] as bool? ?? false,
      promptReflection: j['promptReflection'] as bool? ?? false,
      healthMetric: HealthMetricType.fromId(j['healthMetric'] as String?),
      healthSyncEnabled: j['healthSyncEnabled'] as bool? ?? false,
      isNegative: j['isNegative'] as bool? ?? false,
      cleanSince: _parseDateTime(j['cleanSince'], 'cleanSince'),
      isDeleted: j['isDeleted'] as bool? ?? false,
      createdAt: _parseDateTimeOrNow(j['createdAt'], 'createdAt'),
      updatedAt: _parseDateTimeOrNow(j['updatedAt'], 'updatedAt'),
    );
  }

  static Map<String, dynamic> _logToJson(HabitLog l) => {
        'id': l.id,
        'habitId': l.habitId,
        'date': l.date,
        'timestamp': l.timestamp.toUtc().toIso8601String(),
        'intervalIndex': l.intervalIndex,
        'completed': l.completed,
        'value': l.value,
        'durationSeconds': l.durationSeconds,
        'targetTier': l.targetTier?.name,
        'note': l.note,
        'energyLevel': l.energyLevel,
        'mood': l.mood,
        'isDeleted': l.isDeleted,
        'createdAt': l.createdAt.toUtc().toIso8601String(),
        'updatedAt': l.updatedAt.toUtc().toIso8601String(),
      };

  static HabitLog _logFromJson(Map<String, dynamic> j) {
    return HabitLog(
      id: _requireId(j, 'id'),
      habitId: _requireId(j, 'habitId'),
      date: _requireString(j, 'date'),
      timestamp: _parseDateTimeOrNow(j['timestamp'], 'timestamp'),
      intervalIndex: j['intervalIndex'] as int?,
      completed: j['completed'] as bool? ?? false,
      value: (j['value'] as num?)?.toDouble(),
      durationSeconds: j['durationSeconds'] as int?,
      targetTier: j['targetTier'] != null
          ? HabitTier.fromName(j['targetTier'] as String)
          : null,
      note: j['note'] as String?,
      energyLevel: j['energyLevel'] as int?,
      mood: j['mood'] as String?,
      isDeleted: j['isDeleted'] as bool? ?? false,
      createdAt: _parseDateTimeOrNow(j['createdAt'], 'createdAt'),
      updatedAt: _parseDateTimeOrNow(j['updatedAt'], 'updatedAt'),
    );
  }

  static Map<String, dynamic> _shieldToJson(HabitShield s) => {
        'id': s.id,
        'habitId': s.habitId,
        'date': s.date,
        'autoApplied': s.autoApplied,
        'isDeleted': s.isDeleted,
        'createdAt': s.createdAt.toUtc().toIso8601String(),
        'updatedAt': s.updatedAt.toUtc().toIso8601String(),
      };

  static HabitShield _shieldFromJson(Map<String, dynamic> j) {
    return HabitShield(
      id: _requireId(j, 'id'),
      habitId: _requireId(j, 'habitId'),
      date: _requireString(j, 'date'),
      autoApplied: j['autoApplied'] as bool? ?? false,
      isDeleted: j['isDeleted'] as bool? ?? false,
      createdAt: _parseDateTimeOrNow(j['createdAt'], 'createdAt'),
      updatedAt: _parseDateTimeOrNow(j['updatedAt'], 'updatedAt'),
    );
  }

  static Map<String, dynamic> _routineToJson(HabitRoutine r) => {
        'id': r.id,
        'title': r.title,
        'description': r.description,
        'color': r.color,
        'icon': r.icon,
        'targetTimeWindow': r.targetTimeWindow != null
            ? {
                'startTime': r.targetTimeWindow!.startTime,
                'endTime': r.targetTimeWindow!.endTime,
              }
            : null,
        'habitIds': r.habitIds,
        'bonusXp': r.bonusXp,
        'isDeleted': r.isDeleted,
        'createdAt': r.createdAt.toUtc().toIso8601String(),
        'updatedAt': r.updatedAt.toUtc().toIso8601String(),
      };

  static HabitRoutine _routineFromJson(Map<String, dynamic> j) {
    TimeWindow? tw;
    if (j['targetTimeWindow'] != null) {
      final twMap = _asRecord(j['targetTimeWindow'], 'targetTimeWindow');
      final start = twMap['startTime'];
      final end = twMap['endTime'];
      if (start is! String || end is! String) {
        throw const FormatException('Invalid backup record: bad targetTimeWindow');
      }
      tw = TimeWindow(startTime: start, endTime: end);
    }
    return HabitRoutine(
      id: _requireId(j, 'id'),
      title: _requireString(j, 'title'),
      description: j['description'] as String?,
      color: _requireString(j, 'color'),
      icon: j['icon'] as String?,
      targetTimeWindow: tw,
      habitIds: (j['habitIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      bonusXp: j['bonusXp'] as int? ?? 30,
      isDeleted: j['isDeleted'] as bool? ?? false,
      createdAt: _parseDateTimeOrNow(j['createdAt'], 'createdAt'),
      updatedAt: _parseDateTimeOrNow(j['updatedAt'], 'updatedAt'),
    );
  }

  static Map<String, dynamic> _routineLogToJson(RoutineLog l) => {
        'id': l.id,
        'routineId': l.routineId,
        'date': l.date,
        'completedAt': l.completedAt.toUtc().toIso8601String(),
        'completedHabitIds': l.completedHabitIds,
        'xpEarned': l.xpEarned,
        'isDeleted': l.isDeleted,
        'createdAt': l.createdAt.toUtc().toIso8601String(),
        'updatedAt': l.updatedAt.toUtc().toIso8601String(),
      };

  static RoutineLog _routineLogFromJson(Map<String, dynamic> j) {
    return RoutineLog(
      id: _requireId(j, 'id'),
      routineId: _requireId(j, 'routineId'),
      date: _requireString(j, 'date'),
      completedAt: _parseDateTimeOrNow(j['completedAt'], 'completedAt'),
      completedHabitIds:
          (j['completedHabitIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      xpEarned: j['xpEarned'] as int? ?? 0,
      isDeleted: j['isDeleted'] as bool? ?? false,
      createdAt: _parseDateTimeOrNow(j['createdAt'], 'createdAt'),
      updatedAt: _parseDateTimeOrNow(j['updatedAt'], 'updatedAt'),
    );
  }
}

class SyncUserGamification {
  final int totalXp;
  final int currentLevel;
  final int lastCelebratedLevel;
  final int maxShieldsCapacity;
  final bool autoConsumeShields;
  final DateTime? updatedAt;

  const SyncUserGamification({
    this.totalXp = 0,
    this.currentLevel = 1,
    this.lastCelebratedLevel = 1,
    this.maxShieldsCapacity = 3,
    this.autoConsumeShields = true,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'currentLevel': currentLevel,
        'lastCelebratedLevel': lastCelebratedLevel,
        'maxShieldsCapacity': maxShieldsCapacity,
        'autoConsumeShields': autoConsumeShields,
        'updatedAt': updatedAt?.toUtc().toIso8601String(),
      };

  factory SyncUserGamification.fromJson(Map<String, dynamic> j) =>
      SyncUserGamification(
        totalXp: j['totalXp'] as int? ?? 0,
        currentLevel: j['currentLevel'] as int? ?? 1,
        lastCelebratedLevel: j['lastCelebratedLevel'] as int? ?? 1,
        maxShieldsCapacity: j['maxShieldsCapacity'] as int? ?? 3,
        autoConsumeShields: j['autoConsumeShields'] as bool? ?? true,
        updatedAt: _parseDateTime(j['updatedAt'], 'updatedAt'),
      );
}

class SyncAchievement {
  final String id;
  final DateTime unlockedAt;
  final int progress;
  final bool notified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SyncAchievement({
    required this.id,
    required this.unlockedAt,
    required this.progress,
    this.notified = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'unlockedAt': unlockedAt.toUtc().toIso8601String(),
        'progress': progress,
        'notified': notified,
        'createdAt': createdAt?.toUtc().toIso8601String(),
        'updatedAt': updatedAt?.toUtc().toIso8601String(),
      };

  factory SyncAchievement.fromJson(Map<String, dynamic> j) => SyncAchievement(
        id: _requireId(j, 'id'),
        unlockedAt: _parseDateTimeOrNow(j['unlockedAt'], 'unlockedAt'),
        progress: j['progress'] as int? ?? 0,
        notified: j['notified'] as bool? ?? false,
        createdAt: _parseDateTime(j['createdAt'], 'createdAt'),
        updatedAt: _parseDateTime(j['updatedAt'], 'updatedAt'),
      );
}
