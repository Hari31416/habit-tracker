class HabitShield {
  final String id;
  final String habitId;
  final String date; // ISO Date format "yyyy-MM-dd"
  final bool autoApplied;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitShield({
    required this.id,
    required this.habitId,
    required this.date,
    this.autoApplied = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  HabitShield copyWith({
    String? id,
    String? habitId,
    String? date,
    bool? autoApplied,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitShield(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      autoApplied: autoApplied ?? this.autoApplied,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitShield &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          habitId == other.habitId &&
          date == other.date &&
          autoApplied == other.autoApplied &&
          isDeleted == other.isDeleted;

  @override
  int get hashCode =>
      id.hashCode ^ habitId.hashCode ^ date.hashCode ^ autoApplied.hashCode ^ isDeleted.hashCode;
}
