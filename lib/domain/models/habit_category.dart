class HabitCategory {
  final String id;
  final String name;
  final String color;
  final String? icon;

  const HabitCategory({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
  });

  HabitCategory copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
  }) {
    return HabitCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
