enum HabitFrequencyType {
  daily,
  weekly,
  customDays,
  subdayInterval,
  timesPerDay;

  String get nameValue {
    switch (this) {
      case HabitFrequencyType.daily:
        return 'DAILY';
      case HabitFrequencyType.weekly:
        return 'WEEKLY';
      case HabitFrequencyType.customDays:
        return 'CUSTOM_DAYS';
      case HabitFrequencyType.subdayInterval:
        return 'SUBDAY_INTERVAL';
      case HabitFrequencyType.timesPerDay:
        return 'TIMES_PER_DAY';
    }
  }

  static HabitFrequencyType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DAILY':
        return HabitFrequencyType.daily;
      case 'WEEKLY':
        return HabitFrequencyType.weekly;
      case 'CUSTOM_DAYS':
        return HabitFrequencyType.customDays;
      case 'SUBDAY_INTERVAL':
        return HabitFrequencyType.subdayInterval;
      case 'TIMES_PER_DAY':
        return HabitFrequencyType.timesPerDay;
      default:
        return HabitFrequencyType.daily;
    }
  }
}
