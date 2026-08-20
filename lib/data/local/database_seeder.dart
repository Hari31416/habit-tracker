import 'package:drift/drift.dart';
import '../../domain/models/habit_frequency_type.dart';
import '../../domain/models/habit_target_type.dart';
import 'app_database.dart';

class DatabaseSeeder {
  static final DateTime _seedEpoch = DateTime.utc(2026, 1, 1);

  static final List<HabitCategoriesCompanion> defaultCategories = [
    HabitCategoriesCompanion(
      id: const Value('cat_health_fitness'),
      name: const Value('Health & Fitness'),
      color: const Value('#10B981'),
      icon: const Value('activity'),
      isDeleted: const Value(false),
      createdAt: Value(_seedEpoch),
      updatedAt: Value(_seedEpoch),
    ),
    HabitCategoriesCompanion(
      id: const Value('cat_mindfulness'),
      name: const Value('Mindfulness'),
      color: const Value('#8B5CF6'),
      icon: const Value('brain'),
      isDeleted: const Value(false),
      createdAt: Value(_seedEpoch),
      updatedAt: Value(_seedEpoch),
    ),
    HabitCategoriesCompanion(
      id: const Value('cat_learning'),
      name: const Value('Learning'),
      color: const Value('#3B82F6'),
      icon: const Value('book-open'),
      isDeleted: const Value(false),
      createdAt: Value(_seedEpoch),
      updatedAt: Value(_seedEpoch),
    ),
    HabitCategoriesCompanion(
      id: const Value('cat_productivity'),
      name: const Value('Productivity'),
      color: const Value('#F59E0B'),
      icon: const Value('zap'),
      isDeleted: const Value(false),
      createdAt: Value(_seedEpoch),
      updatedAt: Value(_seedEpoch),
    ),
    HabitCategoriesCompanion(
      id: const Value('cat_personal'),
      name: const Value('Personal'),
      color: const Value('#EC4899'),
      icon: const Value('heart'),
      isDeleted: const Value(false),
      createdAt: Value(_seedEpoch),
      updatedAt: Value(_seedEpoch),
    ),
    HabitCategoriesCompanion(
      id: const Value('cat_routine'),
      name: const Value('Routine'),
      color: const Value('#6366F1'),
      icon: const Value('clock'),
      isDeleted: const Value(false),
      createdAt: Value(_seedEpoch),
      updatedAt: Value(_seedEpoch),
    ),
  ];

  static Future<void> seedIfEmpty(AppDatabase db) async {
    try {
      await db.habitCategoryDao.insertDefaultCategories(defaultCategories);
    } catch (_) {
      // Ignore on race condition / pre-existing
    }
  }

  static Future<void> seedDemoHabits(AppDatabase db) async {
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
      // Ignore on race condition
    }
  }
}
