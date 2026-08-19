import 'package:drift/drift.dart';
import '../../domain/models/habit_frequency_type.dart';
import '../../domain/models/habit_target_type.dart';
import 'app_database.dart';

class DatabaseSeeder {
  static const List<HabitCategoriesCompanion> defaultCategories = [
    HabitCategoriesCompanion(
      id: Value('cat_health_fitness'),
      name: Value('Health & Fitness'),
      color: Value('#10B981'),
      icon: Value('activity'),
    ),
    HabitCategoriesCompanion(
      id: Value('cat_mindfulness'),
      name: Value('Mindfulness'),
      color: Value('#8B5CF6'),
      icon: Value('brain'),
    ),
    HabitCategoriesCompanion(
      id: Value('cat_learning'),
      name: Value('Learning'),
      color: Value('#3B82F6'),
      icon: Value('book-open'),
    ),
    HabitCategoriesCompanion(
      id: Value('cat_productivity'),
      name: Value('Productivity'),
      color: Value('#F59E0B'),
      icon: Value('zap'),
    ),
    HabitCategoriesCompanion(
      id: Value('cat_personal'),
      name: Value('Personal'),
      color: Value('#EC4899'),
      icon: Value('heart'),
    ),
    HabitCategoriesCompanion(
      id: Value('cat_routine'),
      name: Value('Routine'),
      color: Value('#6366F1'),
      icon: Value('clock'),
    ),
  ];

  static Future<void> seedIfEmpty(AppDatabase db) async {
    try {
      await db.habitCategoryDao.insertDefaultCategories(defaultCategories);

      final existingHabits = await db.habitDao.getActiveHabitsOnce();
      if (existingHabits.isEmpty) {
        final now = DateTime.now().toUtc();
        final seedHabits = [
          HabitsCompanion(
            id: const Value('seed_habit_deep_work'),
            title: const Value('Deep Work Session'),
            description: const Value('Focus on high-leverage engineering tasks without distractions'),
            color: const Value('#3B82F6'),
            icon: const Value('zap'),
            categoryId: const Value('cat_productivity'),
            frequencyType: const Value(HabitFrequencyType.daily),
            targetType: const Value(HabitTargetType.timer),
            targetValue: const Value(45.0),
            unit: const Value('mins'),
            pinned: const Value(true),
            promptReflection: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          HabitsCompanion(
            id: const Value('seed_habit_meditation'),
            title: const Value('Morning Meditation'),
            description: const Value('10 minutes of mindfulness and breath awareness'),
            color: const Value('#8B5CF6'),
            icon: const Value('brain'),
            categoryId: const Value('cat_mindfulness'),
            frequencyType: const Value(HabitFrequencyType.daily),
            targetType: const Value(HabitTargetType.boolean),
            pinned: const Value(true),
            promptReflection: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          HabitsCompanion(
            id: const Value('seed_habit_read'),
            title: const Value('Read 20 Pages'),
            description: const Value('Non-fiction, books, or technical papers'),
            color: const Value('#10B981'),
            icon: const Value('book-open'),
            categoryId: const Value('cat_learning'),
            frequencyType: const Value(HabitFrequencyType.daily),
            targetType: const Value(HabitTargetType.numeric),
            targetValue: const Value(20.0),
            unit: const Value('pages'),
            promptReflection: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          HabitsCompanion(
            id: const Value('seed_habit_water'),
            title: const Value('Hydration Intake'),
            description: const Value('Drink 8 glasses of water throughout the day'),
            color: const Value('#0EA5E9'),
            icon: const Value('droplet'),
            categoryId: const Value('cat_health_fitness'),
            frequencyType: const Value(HabitFrequencyType.timesPerDay),
            timesPerDay: const Value(4),
            targetType: const Value(HabitTargetType.boolean),
            promptReflection: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          HabitsCompanion(
            id: const Value('seed_habit_evening_review'),
            title: const Value('Evening Reflection'),
            description: const Value('Review daily wins and plan next day priorities'),
            color: const Value('#F59E0B'),
            icon: const Value('sun'),
            categoryId: const Value('cat_personal'),
            frequencyType: const Value(HabitFrequencyType.daily),
            targetType: const Value(HabitTargetType.boolean),
            promptReflection: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        ];

        await db.habitDao.insertHabits(seedHabits);
      }
    } catch (_) {
      // Ignore on race condition / pre-existing
    }
  }
}
