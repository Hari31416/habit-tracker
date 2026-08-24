import 'time_window.dart';

class HabitRoutine {
  final String id;
  final String title;
  final String? description;
  final String color;
  final String? icon;
  final TimeWindow? targetTimeWindow;
  final List<String> habitIds;
  final int bonusXp;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitRoutine({
    required this.id,
    required this.title,
    this.description,
    required this.color,
    this.icon,
    this.targetTimeWindow,
    this.habitIds = const [],
    this.bonusXp = 30,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  HabitRoutine copyWith({
    String? id,
    String? title,
    String? description,
    String? color,
    String? icon,
    TimeWindow? targetTimeWindow,
    List<String>? habitIds,
    int? bonusXp,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitRoutine(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      targetTimeWindow: targetTimeWindow ?? this.targetTimeWindow,
      habitIds: habitIds ?? this.habitIds,
      bonusXp: bonusXp ?? this.bonusXp,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitRoutine &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          color == other.color &&
          icon == other.icon &&
          targetTimeWindow == other.targetTimeWindow &&
          _listEquals(habitIds, other.habitIds) &&
          bonusXp == other.bonusXp &&
          isDeleted == other.isDeleted &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      color.hashCode ^
      icon.hashCode ^
      targetTimeWindow.hashCode ^
      habitIds.length.hashCode ^
      bonusXp.hashCode ^
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
