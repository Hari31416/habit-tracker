class RoutineLog {
  final String id;
  final String routineId;
  final String date; // yyyy-MM-dd
  final DateTime completedAt;
  final List<String> completedHabitIds;
  final int xpEarned;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoutineLog({
    required this.id,
    required this.routineId,
    required this.date,
    required this.completedAt,
    this.completedHabitIds = const [],
    this.xpEarned = 0,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  RoutineLog copyWith({
    String? id,
    String? routineId,
    String? date,
    DateTime? completedAt,
    List<String>? completedHabitIds,
    int? xpEarned,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoutineLog(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
      completedHabitIds: completedHabitIds ?? this.completedHabitIds,
      xpEarned: xpEarned ?? this.xpEarned,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          routineId == other.routineId &&
          date == other.date &&
          completedAt == other.completedAt &&
          _listEquals(completedHabitIds, other.completedHabitIds) &&
          xpEarned == other.xpEarned &&
          isDeleted == other.isDeleted &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      routineId.hashCode ^
      date.hashCode ^
      completedAt.hashCode ^
      completedHabitIds.length.hashCode ^
      xpEarned.hashCode ^
      isDeleted.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
