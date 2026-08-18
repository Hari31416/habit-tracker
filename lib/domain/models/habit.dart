import 'habit_frequency_type.dart';
import 'habit_target_type.dart';
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
  final String? unit;
  final bool pinned;
  final List<String> reminderTimes;
  final String? motivationNotes;
  final bool archived;
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
    this.unit,
    this.pinned = false,
    this.reminderTimes = const [],
    this.motivationNotes,
    this.archived = false,
    required this.createdAt,
    required this.updatedAt,
  });

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
    String? unit,
    bool? pinned,
    List<String>? reminderTimes,
    String? motivationNotes,
    bool? archived,
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
      unit: unit ?? this.unit,
      pinned: pinned ?? this.pinned,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      motivationNotes: motivationNotes ?? this.motivationNotes,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
