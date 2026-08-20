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

  /// Parses a deep-link URI or named route string into a valid route name.
  ///
  /// Maps:
  /// - `app://habits/daily` -> `daily`
  /// - `app://habits/matrix` -> `matrix`
  /// - `app://habits/analytics` -> `analytics`
  /// - `app://habits/badges` -> `badges`
  /// - `app://habits/detail/{id}` -> `detail/{id}` (or `daily` if id is empty)
  /// - `app://habits/focus_timer/{id}` -> `focus_timer/{id}` (or `daily` if id is empty)
  /// - Unknown or malformed URIs -> `daily`
  static String fromUri(String? uriString) {
    if (uriString == null || uriString.trim().isEmpty) {
      return daily;
    }
    final clean = uriString.trim();

    if (clean.startsWith('phial://habits/')) {
      final subPath = clean.replaceFirst('phial://habits/', '');
      return _normalizeSubPath(subPath);
    }
    if (clean.startsWith('phial://habits')) {
      return daily;
    }
    if (clean.startsWith('app://habits/')) {
      final subPath = clean.replaceFirst('app://habits/', '');
      return _normalizeSubPath(subPath);
    }
    if (clean.startsWith('app://habits')) {
      return daily;
    }
    if (clean.startsWith('/')) {
      return _normalizeSubPath(clean.substring(1));
    }
    return _normalizeSubPath(clean);
  }

  static String _normalizeSubPath(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) {
      return daily;
    }
    final first = segments[0];
    if (first == daily) return daily;
    if (first == addHabit || first == 'create' || first == 'add') return addHabit;
    if (first == matrix) return matrix;
    if (first == analytics) return analytics;
    if (first == badges) return badges;
    if (first == detail) {
      if (segments.length > 1 && segments[1].trim().isNotEmpty) {
        return detailRoute(segments[1].trim());
      }
      return daily;
    }
    if (first == focusTimer) {
      if (segments.length > 1 && segments[1].trim().isNotEmpty) {
        return focusTimerRoute(segments[1].trim());
      }
      return daily;
    }
    return daily;
  }
}
