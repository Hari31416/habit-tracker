import 'habit_tier.dart';

class HabitLog {
  final String id;
  final String habitId;
  final String date; // ISO Date format "yyyy-MM-dd"
  final DateTime timestamp;
  final int? intervalIndex; // For subday interval or times-per-day slot index (0, 1, 2...)
  final bool completed;
  final double? value; // Recorded numeric value or minutes
  final int? durationSeconds; // Elapsed duration in seconds for timer habits
  final HabitTier? targetTier; // Mini, Base, or Elite tier
  final String? note;
  final int? energyLevel; // 1 to 5 scale
  final String? mood; // energized, happy, calm, tired, stressed, focused
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.timestamp,
    this.intervalIndex,
    required this.completed,
    this.value,
    this.durationSeconds,
    this.targetTier,
    this.note,
    this.energyLevel,
    this.mood,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  HabitLog copyWith({
    String? id,
    String? habitId,
    String? date,
    DateTime? timestamp,
    int? intervalIndex,
    bool? completed,
    double? value,
    int? durationSeconds,
    HabitTier? targetTier,
    bool clearTargetTier = false,
    String? note,
    int? energyLevel,
    String? mood,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      intervalIndex: intervalIndex ?? this.intervalIndex,
      completed: completed ?? this.completed,
      value: value ?? this.value,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      targetTier: clearTargetTier ? null : (targetTier ?? this.targetTier),
      note: note ?? this.note,
      energyLevel: energyLevel ?? this.energyLevel,
      mood: mood ?? this.mood,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
