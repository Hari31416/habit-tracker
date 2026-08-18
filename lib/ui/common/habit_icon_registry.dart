import 'package:flutter/material.dart';

class HabitIconItem {
  final String key;
  final String label;
  final IconData icon;

  const HabitIconItem({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class HabitIconRegistry {
  static const Map<String, IconData> iconsMap = {
    // Default category icons
    'activity': Icons.directions_run,
    'brain': Icons.psychology,
    'book-open': Icons.menu_book,
    'book': Icons.book,
    'zap': Icons.bolt,
    'heart': Icons.favorite,
    'clock': Icons.schedule,

    // Badges and gamification icons
    'flame': Icons.local_fire_department,
    'shield': Icons.shield,
    'award': Icons.emoji_events,
    'trophy': Icons.emoji_events,
    'crown': Icons.auto_awesome,
    'medal': Icons.military_tech,
    'layers': Icons.layers,
    'compass': Icons.explore,
    'calendar': Icons.calendar_month,
    'trending_up': Icons.trending_up,
    'briefcase': Icons.work,
    'check_circle': Icons.check_circle,

    // Common habit icons
    'check': Icons.check_circle,
    'star': Icons.star,
    'target': Icons.track_changes,
    'droplet': Icons.water_drop,
    'water': Icons.water_drop,
    'footprints': Icons.directions_walk,
    'walk': Icons.directions_walk,
    'run': Icons.directions_run,
    'dumbbell': Icons.fitness_center,
    'fitness': Icons.fitness_center,
    'moon': Icons.bedtime,
    'sun': Icons.wb_sunny,
    'coffee': Icons.local_cafe,
    'code': Icons.code,
    'sparkles': Icons.auto_awesome,
    'smile': Icons.sentiment_satisfied,
    'music': Icons.music_note,
    'edit': Icons.edit,
    'work': Icons.work,
  };

  static const List<HabitIconItem> availableIcons = [
    HabitIconItem(key: 'activity', label: 'Activity', icon: Icons.directions_run),
    HabitIconItem(key: 'brain', label: 'Mindfulness', icon: Icons.psychology),
    HabitIconItem(key: 'book-open', label: 'Reading', icon: Icons.menu_book),
    HabitIconItem(key: 'zap', label: 'Productivity', icon: Icons.bolt),
    HabitIconItem(key: 'heart', label: 'Health / Heart', icon: Icons.favorite),
    HabitIconItem(key: 'clock', label: 'Routine / Time', icon: Icons.schedule),
    HabitIconItem(key: 'droplet', label: 'Hydration', icon: Icons.water_drop),
    HabitIconItem(key: 'dumbbell', label: 'Fitness', icon: Icons.fitness_center),
    HabitIconItem(key: 'footprints', label: 'Walking / Steps', icon: Icons.directions_walk),
    HabitIconItem(key: 'moon', label: 'Sleep / Night', icon: Icons.bedtime),
    HabitIconItem(key: 'sun', label: 'Morning', icon: Icons.wb_sunny),
    HabitIconItem(key: 'coffee', label: 'Break / Focus', icon: Icons.local_cafe),
    HabitIconItem(key: 'code', label: 'Coding / Tech', icon: Icons.code),
    HabitIconItem(key: 'target', label: 'Target / Goals', icon: Icons.track_changes),
    HabitIconItem(key: 'sparkles', label: 'Motivation', icon: Icons.auto_awesome),
    HabitIconItem(key: 'star', label: 'Star / Priority', icon: Icons.star),
    HabitIconItem(key: 'music', label: 'Music / Art', icon: Icons.music_note),
    HabitIconItem(key: 'smile', label: 'Mood / Well-being', icon: Icons.sentiment_satisfied),
    HabitIconItem(key: 'edit', label: 'Writing / Journal', icon: Icons.edit),
    HabitIconItem(key: 'work', label: 'Work / Projects', icon: Icons.work),
  ];

  static IconData getIcon(String? key) {
    if (key == null || key.trim().isEmpty) {
      return Icons.check_circle;
    }
    final normalized = key.toLowerCase().trim();
    return iconsMap[normalized] ?? Icons.check_circle;
  }
}
