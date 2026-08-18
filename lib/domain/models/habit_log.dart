class HabitLog {
  final String id;
  final String habitId;
  final String date; // ISO Date format "yyyy-MM-dd"
  final DateTime timestamp;
  final int? intervalIndex; // For subday interval or times-per-day slot index (0, 1, 2...)
  final bool completed;
  final double? value; // Recorded numeric value or minutes
  final int? durationSeconds; // Elapsed duration in seconds for timer habits
  final String? note;
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
    this.note,
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
    String? note,
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
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
