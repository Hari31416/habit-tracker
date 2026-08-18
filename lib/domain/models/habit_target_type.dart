enum HabitTargetType {
  boolean,
  numeric,
  timer;

  String get nameValue {
    switch (this) {
      case HabitTargetType.boolean:
        return 'BOOLEAN';
      case HabitTargetType.numeric:
        return 'NUMERIC';
      case HabitTargetType.timer:
        return 'TIMER';
    }
  }

  static HabitTargetType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BOOLEAN':
        return HabitTargetType.boolean;
      case 'NUMERIC':
        return HabitTargetType.numeric;
      case 'TIMER':
        return HabitTargetType.timer;
      default:
        return HabitTargetType.boolean;
    }
  }
}
