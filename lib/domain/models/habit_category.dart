class HabitCategory {
  final String id;
  final String name;
  final String color;
  final String? icon;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HabitCategory({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  HabitCategory copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
