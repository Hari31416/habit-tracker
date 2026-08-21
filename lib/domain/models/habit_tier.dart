enum HabitTier {
  none('None', 0, '#9E9E9E', 'circle_outlined'),
  mini('Mini', 5, '#F59E0B', 'local_fire_department'),
  base('Base', 20, '#10B981', 'check_circle'),
  elite('Elite', 35, '#8B5CF6', 'workspace_premium');

  final String displayName;
  final int baseXp;
  final String colorHex;
  final String iconKey;

  const HabitTier(
    this.displayName,
    this.baseXp,
    this.colorHex,
    this.iconKey,
  );

  bool isAtLeast(HabitTier other) {
    return index >= other.index;
  }

  static HabitTier fromName(String? name) {
    if (name == null) return HabitTier.none;
    return HabitTier.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => HabitTier.none,
    );
  }
}
