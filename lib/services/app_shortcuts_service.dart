import '../domain/models/habit.dart';
import '../domain/repositories/habit_repository.dart';

class ShortcutItemData {
  final String id;
  final String title;
  final String deepLinkUri;
  final String icon;

  const ShortcutItemData({
    required this.id,
    required this.title,
    required this.deepLinkUri,
    required this.icon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShortcutItemData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}

class AppShortcutsService {
  final HabitRepository _repository;

  List<ShortcutItemData> _currentShortcuts = [];

  AppShortcutsService(this._repository);

  List<ShortcutItemData> get currentShortcuts =>
      List.unmodifiable(_currentShortcuts);

  Future<void> updateDynamicShortcuts() async {
    final activeHabits = await _repository.getActiveHabits().first;

    // Priority: 1. Pinned habits first, 2. Alphabetical
    final sorted = List<Habit>.from(activeHabits)
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return a.title.compareTo(b.title);
      });

    final topHabits = sorted.take(3);

    _currentShortcuts = topHabits.map((habit) {
      return ShortcutItemData(
        id: 'shortcut_${habit.id}',
        title: habit.title,
        deepLinkUri: 'app://habits/detail/${habit.id}',
        icon: habit.icon ?? 'check',
      );
    }).toList();
  }
}
