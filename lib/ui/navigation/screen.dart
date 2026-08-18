abstract class Screen {
  final String route;
  const Screen(this.route);

  static const String daily = 'daily';
  static const String matrix = 'matrix';
  static const String analytics = 'analytics';
  static const String detail = 'detail';
  static const String badges = 'badges';
  static const String focusTimer = 'focus_timer';
  static const String addHabit = 'add_habit';
  static const String editHabit = 'edit_habit';

  static String detailRoute(String habitId) => 'detail/$habitId';
  static String focusTimerRoute(String habitId) => 'focus_timer/$habitId';
  static String editHabitRoute(String habitId) => 'edit_habit/$habitId';
}
