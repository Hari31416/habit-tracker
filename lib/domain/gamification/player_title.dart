enum PlayerTitle {
  novice('Novice', 1, 'Beginning the journey of habit mastery'),
  apprentice('Apprentice', 5, 'Building steady discipline and consistency'),
  pathfinder('Pathfinder', 10, 'Navigating advanced routines and long streaks'),
  grandmaster('Grandmaster', 20, 'A true master of personal growth and unbreakable habits');

  final String displayName;
  final int minLevel;
  final String description;

  const PlayerTitle(this.displayName, this.minLevel, this.description);

  static PlayerTitle fromLevel(int level) {
    PlayerTitle matched = PlayerTitle.novice;
    for (final title in PlayerTitle.values) {
      if (title.minLevel <= level) {
        if (title.minLevel >= matched.minLevel) {
          matched = title;
        }
      }
    }
    return matched;
  }

  static PlayerTitle? nextTitle(int level) {
    final current = fromLevel(level);
    final all = List<PlayerTitle>.from(PlayerTitle.values)
      ..sort((a, b) => a.minLevel.compareTo(b.minLevel));
    final currentIndex = all.indexOf(current);
    if (currentIndex >= 0 && currentIndex < all.length - 1) {
      return all[currentIndex + 1];
    }
    return null;
  }
}
