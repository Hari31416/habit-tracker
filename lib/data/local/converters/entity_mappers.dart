import 'package:drift/drift.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_category.dart';
import '../../../domain/models/habit_log.dart';
import '../../../domain/models/habit_routine.dart';
import '../../../domain/models/habit_shield.dart';
import '../../../domain/models/routine_log.dart';
import '../app_database.dart';

extension HabitRowMapper on HabitRow {
  Habit toDomain() => Habit(
        id: id,
        title: title,
        description: description,
        color: color,
        icon: icon,
        categoryId: categoryId,
        frequencyType: frequencyType,
        targetDaysOfWeek: targetDaysOfWeek,
        targetCountPerWeek: targetCountPerWeek,
        intervalHours: intervalHours,
        timesPerDay: timesPerDay,
        timeWindow: timeWindow,
        targetType: targetType,
        targetValue: targetValue,
        miniTargetValue: miniTargetValue,
        eliteTargetValue: eliteTargetValue,
        unit: unit,
        pinned: pinned,
        reminderTimes: reminderTimes,
        motivationNotes: motivationNotes,
        archived: archived,
        promptReflection: promptReflection,
        healthMetric: healthMetric,
        healthSyncEnabled: healthSyncEnabled,
        isNegative: isNegative,
        cleanSince: cleanSince,
        isDeleted: isDeleted,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension HabitCompanionMapper on Habit {
  HabitsCompanion toCompanion() => HabitsCompanion(
        id: Value(id),
        title: Value(title),
        description: Value(description),
        color: Value(color),
        icon: Value(icon),
        categoryId: Value(categoryId),
        frequencyType: Value(frequencyType),
        targetDaysOfWeek: Value(targetDaysOfWeek),
        targetCountPerWeek: Value(targetCountPerWeek),
        intervalHours: Value(intervalHours),
        timesPerDay: Value(timesPerDay),
        timeWindow: Value(timeWindow),
        targetType: Value(targetType),
        targetValue: Value(targetValue),
        miniTargetValue: Value(miniTargetValue),
        eliteTargetValue: Value(eliteTargetValue),
        unit: Value(unit),
        pinned: Value(pinned),
        reminderTimes: Value(reminderTimes),
        motivationNotes: Value(motivationNotes),
        archived: Value(archived),
        promptReflection: Value(promptReflection),
        healthMetric: Value(healthMetric),
        healthSyncEnabled: Value(healthSyncEnabled),
        isNegative: Value(isNegative),
        cleanSince: Value(cleanSince),
        isDeleted: Value(isDeleted),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}

extension HabitLogRowMapper on HabitLogRow {
  HabitLog toDomain() => HabitLog(
        id: id,
        habitId: habitId,
        date: date,
        timestamp: timestamp,
        intervalIndex: intervalIndex,
        completed: completed,
        value: value,
        durationSeconds: durationSeconds,
        targetTier: targetTier,
        note: note,
        energyLevel: energyLevel,
        mood: mood,
        isDeleted: isDeleted,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension HabitLogCompanionMapper on HabitLog {
  HabitLogsCompanion toCompanion() => HabitLogsCompanion(
        id: Value(id),
        habitId: Value(habitId),
        date: Value(date),
        timestamp: Value(timestamp),
        intervalIndex: Value(intervalIndex),
        completed: Value(completed),
        value: Value(value),
        durationSeconds: Value(durationSeconds),
        targetTier: Value(targetTier),
        note: Value(note),
        energyLevel: Value(energyLevel),
        mood: Value(mood),
        isDeleted: Value(isDeleted),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}

extension HabitShieldRowMapper on HabitShieldRow {
  HabitShield toDomain() => HabitShield(
        id: id,
        habitId: habitId,
        date: date,
        autoApplied: autoApplied,
        isDeleted: isDeleted,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension HabitShieldCompanionMapper on HabitShield {
  HabitShieldsCompanion toCompanion() => HabitShieldsCompanion(
        id: Value(id),
        habitId: Value(habitId),
        date: Value(date),
        autoApplied: Value(autoApplied),
        isDeleted: Value(isDeleted),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}

extension HabitCategoryRowMapper on HabitCategoryRow {
  HabitCategory toDomain() => HabitCategory(
        id: id,
        name: name,
        color: color,
        icon: icon,
        isDeleted: isDeleted,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension HabitCategoryCompanionMapper on HabitCategory {
  HabitCategoriesCompanion toCompanion([DateTime? defaultTime]) {
    final now = defaultTime ?? DateTime.now().toUtc();
    return HabitCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      icon: Value(icon),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt ?? now),
      updatedAt: Value(updatedAt ?? now),
    );
  }
}

extension HabitRoutineRowMapper on HabitRoutineRow {
  HabitRoutine toDomain() => HabitRoutine(
        id: id,
        title: title,
        description: description,
        color: color,
        icon: icon,
        targetTimeWindow: targetTimeWindow,
        habitIds: habitIds,
        bonusXp: bonusXp,
        isDeleted: isDeleted,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension HabitRoutineCompanionMapper on HabitRoutine {
  HabitRoutinesCompanion toCompanion() => HabitRoutinesCompanion(
        id: Value(id),
        title: Value(title),
        description: Value(description),
        color: Value(color),
        icon: Value(icon),
        targetTimeWindow: Value(targetTimeWindow),
        habitIds: Value(habitIds),
        bonusXp: Value(bonusXp),
        isDeleted: Value(isDeleted),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}

extension RoutineLogRowMapper on RoutineLogRow {
  RoutineLog toDomain() => RoutineLog(
        id: id,
        routineId: routineId,
        date: date,
        completedAt: completedAt,
        completedHabitIds: completedHabitIds,
        xpEarned: xpEarned,
        isDeleted: isDeleted,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension RoutineLogCompanionMapper on RoutineLog {
  RoutineLogsCompanion toCompanion() => RoutineLogsCompanion(
        id: Value(id),
        routineId: Value(routineId),
        date: Value(date),
        completedAt: Value(completedAt),
        completedHabitIds: Value(completedHabitIds),
        xpEarned: Value(xpEarned),
        isDeleted: Value(isDeleted),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}
