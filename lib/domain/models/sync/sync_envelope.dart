import 'dart:convert';
import '../habit.dart';
import '../habit_category.dart';
import '../habit_frequency_type.dart';
import '../habit_log.dart';
import '../habit_shield.dart';
import '../habit_target_type.dart';
import '../health/health_metric_type.dart';
import '../time_window.dart';

/// Top-level envelope for local backups and cloud sync snapshots.
class SyncEnvelope {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String appVersion;
  final DateTime exportedAt;
  final String deviceId;
  final SyncDataPayload data;

  const SyncEnvelope({
    this.schemaVersion = currentSchemaVersion,
    required this.appVersion,
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
    return SyncEnvelope(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      appVersion: json['appVersion'] as String? ?? '0.10.0',
      exportedAt: json['exportedAt'] != null
          ? DateTime.parse(json['exportedAt'] as String).toUtc()
          : DateTime.now().toUtc(),
      deviceId: json['deviceId'] as String? ?? 'unknown',
      data: SyncDataPayload.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? {},
      ),
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
  final SyncUserGamification gamification;
  final List<SyncAchievement> achievements;
  final Map<String, dynamic> preferences;

  const SyncDataPayload({
    this.categories = const [],
    this.habits = const [],
    this.logs = const [],
    this.shields = const [],
    this.gamification = const SyncUserGamification(),
    this.achievements = const [],
    this.preferences = const {},
  });

  Map<String, dynamic> toJson() => {
        'categories': categories.map(_categoryToJson).toList(),
        'habits': habits.map(_habitToJson).toList(),
        'logs': logs.map(_logToJson).toList(),
        'shields': shields.map(_shieldToJson).toList(),
        'gamification': gamification.toJson(),
        'achievements': achievements.map((a) => a.toJson()).toList(),
        'preferences': preferences,
      };

  factory SyncDataPayload.fromJson(Map<String, dynamic> json) {
    final rawCats = (json['categories'] as List<dynamic>?) ?? [];
    final rawHabits = (json['habits'] as List<dynamic>?) ?? [];
    final rawLogs = (json['logs'] as List<dynamic>?) ?? [];
    final rawShields = (json['shields'] as List<dynamic>?) ?? [];
    final rawAch = (json['achievements'] as List<dynamic>?) ?? [];

    return SyncDataPayload(
      categories: rawCats
          .map((c) => _categoryFromJson(c as Map<String, dynamic>))
          .toList(),
      habits: rawHabits
          .map((h) => _habitFromJson(h as Map<String, dynamic>))
          .toList(),
      logs: rawLogs
          .map((l) => _logFromJson(l as Map<String, dynamic>))
          .toList(),
      shields: rawShields
          .map((s) => _shieldFromJson(s as Map<String, dynamic>))
          .toList(),
      gamification: json['gamification'] != null
          ? SyncUserGamification.fromJson(
              json['gamification'] as Map<String, dynamic>)
          : const SyncUserGamification(),
      achievements: rawAch
          .map((a) => SyncAchievement.fromJson(a as Map<String, dynamic>))
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
        id: j['id'] as String,
        name: j['name'] as String,
        color: j['color'] as String,
        icon: j['icon'] as String?,
        isDeleted: j['isDeleted'] as bool? ?? false,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String).toUtc()
            : null,
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'] as String).toUtc()
            : null,
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
        'unit': h.unit,
        'pinned': h.pinned,
        'reminderTimes': h.reminderTimes,
        'motivationNotes': h.motivationNotes,
        'archived': h.archived,
        'promptReflection': h.promptReflection,
        'healthMetric': h.healthMetric?.id,
        'healthSyncEnabled': h.healthSyncEnabled,
        'isDeleted': h.isDeleted,
        'createdAt': h.createdAt.toUtc().toIso8601String(),
        'updatedAt': h.updatedAt.toUtc().toIso8601String(),
      };

  static Habit _habitFromJson(Map<String, dynamic> j) {
    return Habit(
      id: j['id'] as String,
      title: j['title'] as String,
      description: j['description'] as String?,
      color: j['color'] as String,
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
      unit: j['unit'] as String?,
      pinned: j['pinned'] as bool? ?? false,
      reminderTimes: (j['reminderTimes'] as List<dynamic>?)?.cast<String>() ?? const [],
      motivationNotes: j['motivationNotes'] as String?,
      archived: j['archived'] as bool? ?? false,
      promptReflection: j['promptReflection'] as bool? ?? false,
      healthMetric: HealthMetricType.fromId(j['healthMetric'] as String?),
      healthSyncEnabled: j['healthSyncEnabled'] as bool? ?? false,
      isDeleted: j['isDeleted'] as bool? ?? false,
      createdAt: j['createdAt'] != null
          ? DateTime.parse(j['createdAt'] as String).toUtc()
          : DateTime.now().toUtc(),
      updatedAt: j['updatedAt'] != null
          ? DateTime.parse(j['updatedAt'] as String).toUtc()
          : DateTime.now().toUtc(),
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
        'note': l.note,
        'energyLevel': l.energyLevel,
        'mood': l.mood,
        'isDeleted': l.isDeleted,
        'createdAt': l.createdAt.toUtc().toIso8601String(),
        'updatedAt': l.updatedAt.toUtc().toIso8601String(),
      };

  static HabitLog _logFromJson(Map<String, dynamic> j) {
    return HabitLog(
      id: j['id'] as String,
      habitId: j['habitId'] as String,
      date: j['date'] as String,
      timestamp: j['timestamp'] != null
          ? DateTime.parse(j['timestamp'] as String).toUtc()
          : DateTime.now().toUtc(),
      intervalIndex: j['intervalIndex'] as int?,
      completed: j['completed'] as bool? ?? false,
      value: (j['value'] as num?)?.toDouble(),
      durationSeconds: j['durationSeconds'] as int?,
      note: j['note'] as String?,
      energyLevel: j['energyLevel'] as int?,
      mood: j['mood'] as String?,
      isDeleted: j['isDeleted'] as bool? ?? false,
      createdAt: j['createdAt'] != null
          ? DateTime.parse(j['createdAt'] as String).toUtc()
          : DateTime.now().toUtc(),
      updatedAt: j['updatedAt'] != null
          ? DateTime.parse(j['updatedAt'] as String).toUtc()
          : DateTime.now().toUtc(),
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
      id: j['id'] as String,
      habitId: j['habitId'] as String,
      date: j['date'] as String,
      autoApplied: j['autoApplied'] as bool? ?? false,
      isDeleted: j['isDeleted'] as bool? ?? false,
      createdAt: j['createdAt'] != null
          ? DateTime.parse(j['createdAt'] as String).toUtc()
          : DateTime.now().toUtc(),
      updatedAt: j['updatedAt'] != null
          ? DateTime.parse(j['updatedAt'] as String).toUtc()
          : DateTime.now().toUtc(),
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
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'] as String).toUtc()
            : null,
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
        id: j['id'] as String,
        unlockedAt: j['unlockedAt'] != null
            ? DateTime.parse(j['unlockedAt'] as String).toUtc()
            : DateTime.now().toUtc(),
        progress: j['progress'] as int? ?? 0,
        notified: j['notified'] as bool? ?? false,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String).toUtc()
            : null,
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'] as String).toUtc()
            : null,
      );
}
