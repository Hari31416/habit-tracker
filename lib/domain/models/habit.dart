import 'habit_frequency_type.dart';
import 'habit_target_type.dart';
import 'habit_tier.dart';
import 'health/health_metric_type.dart';
import 'time_window.dart';

class Habit {
  final String id;
  final String title;
  final String? description;
  final String color;
  final String? icon;
  final String? categoryId;
  final HabitFrequencyType frequencyType;
  final List<int>? targetDaysOfWeek; // 0 = Sunday, 1 = Monday, ... 6 = Saturday
  final int? targetCountPerWeek;
  final int? intervalHours;
  final int? timesPerDay;
  final TimeWindow? timeWindow;
  final HabitTargetType targetType;
  final double? targetValue;
  final double? miniTargetValue;
  final double? eliteTargetValue;
  final String? unit;
  final bool pinned;
  final List<String> reminderTimes;
  final String? motivationNotes;
  final bool archived;
  final bool promptReflection;
  final HealthMetricType? healthMetric;
  final bool healthSyncEnabled;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Habit({
    required this.id,
    required this.title,
    this.description,
    required this.color,
    this.icon,
    this.categoryId,
    required this.frequencyType,
    this.targetDaysOfWeek,
    this.targetCountPerWeek,
    this.intervalHours,
    this.timesPerDay,
    this.timeWindow,
    required this.targetType,
    this.targetValue,
    this.miniTargetValue,
    this.eliteTargetValue,
    this.unit,
    this.pinned = false,
    this.reminderTimes = const [],
    this.motivationNotes,
    this.archived = false,
    this.promptReflection = false,
    this.healthMetric,
    this.healthSyncEnabled = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasElasticTiers =>
      miniTargetValue != null || eliteTargetValue != null;

  double get effectiveBaseTarget =>
      targetValue ?? (targetType == HabitTargetType.boolean ? 1.0 : 0.0);

  HabitTier evaluateTierForValue(double value) {
    if (eliteTargetValue != null && value >= eliteTargetValue!) {
      return HabitTier.elite;
    }
    if (targetValue != null && value >= targetValue!) {
      return HabitTier.base;
    }
    if (miniTargetValue != null && value >= miniTargetValue!) {
      return HabitTier.mini;
    }
    if (!hasElasticTiers && targetValue != null && value >= targetValue!) {
      return HabitTier.base;
    }
    if (!hasElasticTiers && targetValue == null && value > 0) {
      return HabitTier.base;
    }
    return HabitTier.none;
  }

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    String? color,
    String? icon,
    String? categoryId,
    HabitFrequencyType? frequencyType,
    List<int>? targetDaysOfWeek,
    int? targetCountPerWeek,
    int? intervalHours,
    int? timesPerDay,
    TimeWindow? timeWindow,
    HabitTargetType? targetType,
    double? targetValue,
    double? miniTargetValue,
    bool clearMiniTarget = false,
    double? eliteTargetValue,
    bool clearEliteTarget = false,
    String? unit,
    bool? pinned,
    List<String>? reminderTimes,
    String? motivationNotes,
    bool? archived,
    bool? promptReflection,
    HealthMetricType? healthMetric,
    bool? healthSyncEnabled,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      categoryId: categoryId ?? this.categoryId,
      frequencyType: frequencyType ?? this.frequencyType,
      targetDaysOfWeek: targetDaysOfWeek ?? this.targetDaysOfWeek,
      targetCountPerWeek: targetCountPerWeek ?? this.targetCountPerWeek,
      intervalHours: intervalHours ?? this.intervalHours,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      timeWindow: timeWindow ?? this.timeWindow,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      miniTargetValue:
          clearMiniTarget ? null : (miniTargetValue ?? this.miniTargetValue),
      eliteTargetValue:
          clearEliteTarget ? null : (eliteTargetValue ?? this.eliteTargetValue),
      unit: unit ?? this.unit,
      pinned: pinned ?? this.pinned,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      motivationNotes: motivationNotes ?? this.motivationNotes,
      archived: archived ?? this.archived,
      promptReflection: promptReflection ?? this.promptReflection,
      healthMetric: healthMetric ?? this.healthMetric,
      healthSyncEnabled: healthSyncEnabled ?? this.healthSyncEnabled,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
