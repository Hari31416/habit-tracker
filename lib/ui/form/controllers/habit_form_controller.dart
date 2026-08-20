import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../di/providers.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_category.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../../domain/models/habit_target_type.dart';
import '../../../domain/models/health/health_metric_type.dart';
import '../../../domain/models/time_window.dart';
import '../../../domain/repositories/habit_repository.dart';

class HabitFormState {
  final String? habitId;
  final bool isEditMode;
  final String title;
  final String description;
  final String motivationNotes;
  final String? categoryId;
  final String color;
  final String icon;
  final HabitTargetType targetType;
  final String targetValue;
  final String unit;
  final HabitFrequencyType frequencyType;
  final Set<int> targetDaysOfWeek; // 0 = Sun, 1 = Mon ... 6 = Sat
  final int targetCountPerWeek;
  final int intervalHours;
  final int timesPerDay;
  final String timeWindowStart;
  final String timeWindowEnd;
  final List<String> reminderTimes;
  final bool pinned;
  final bool promptReflection;
  final HealthMetricType? healthMetric;
  final bool healthSyncEnabled;
  final String? titleError;
  final String? targetValueError;
  final bool isSaving;

  const HabitFormState({
    this.habitId,
    this.isEditMode = false,
    this.title = '',
    this.description = '',
    this.motivationNotes = '',
    this.categoryId,
    this.color = '#10B981',
    this.icon = 'check',
    this.targetType = HabitTargetType.boolean,
    this.targetValue = '1',
    this.unit = '',
    this.frequencyType = HabitFrequencyType.daily,
    this.targetDaysOfWeek = const {0, 1, 2, 3, 4, 5, 6},
    this.targetCountPerWeek = 3,
    this.intervalHours = 2,
    this.timesPerDay = 3,
    this.timeWindowStart = '08:00',
    this.timeWindowEnd = '20:00',
    this.reminderTimes = const [],
    this.pinned = false,
    this.promptReflection = false,
    this.healthMetric,
    this.healthSyncEnabled = false,
    this.titleError,
    this.targetValueError,
    this.isSaving = false,
  });

  HabitFormState copyWith({
    String? habitId,
    bool? isEditMode,
    String? title,
    String? description,
    String? motivationNotes,
    String? categoryId,
    bool clearCategory = false,
    String? color,
    String? icon,
    HabitTargetType? targetType,
    String? targetValue,
    String? unit,
    HabitFrequencyType? frequencyType,
    Set<int>? targetDaysOfWeek,
    int? targetCountPerWeek,
    int? intervalHours,
    int? timesPerDay,
    String? timeWindowStart,
    String? timeWindowEnd,
    List<String>? reminderTimes,
    bool? pinned,
    bool? promptReflection,
    HealthMetricType? healthMetric,
    bool clearHealthMetric = false,
    bool? healthSyncEnabled,
    String? titleError,
    bool clearTitleError = false,
    String? targetValueError,
    bool clearTargetValueError = false,
    bool? isSaving,
  }) {
    return HabitFormState(
      habitId: habitId ?? this.habitId,
      isEditMode: isEditMode ?? this.isEditMode,
      title: title ?? this.title,
      description: description ?? this.description,
      motivationNotes: motivationNotes ?? this.motivationNotes,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      color: color ?? this.color,
      icon: icon ?? this.icon,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      frequencyType: frequencyType ?? this.frequencyType,
      targetDaysOfWeek: targetDaysOfWeek ?? this.targetDaysOfWeek,
      targetCountPerWeek: targetCountPerWeek ?? this.targetCountPerWeek,
      intervalHours: intervalHours ?? this.intervalHours,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      timeWindowStart: timeWindowStart ?? this.timeWindowStart,
      timeWindowEnd: timeWindowEnd ?? this.timeWindowEnd,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      pinned: pinned ?? this.pinned,
      promptReflection: promptReflection ?? this.promptReflection,
      healthMetric: clearHealthMetric ? null : (healthMetric ?? this.healthMetric),
      healthSyncEnabled: healthSyncEnabled ?? this.healthSyncEnabled,
      titleError: clearTitleError ? null : (titleError ?? this.titleError),
      targetValueError: clearTargetValueError
          ? null
          : (targetValueError ?? this.targetValueError),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class HabitFormController extends StateNotifier<HabitFormState> {
  final HabitRepository _repository;

  HabitFormController(this._repository) : super(const HabitFormState());

  Future<void> loadHabit(String habitId) async {
    final habit = await _repository.getHabitByIdOnce(habitId);
    if (habit == null) return;

    final targetValStr = habit.targetValue != null
        ? (habit.targetValue! % 1.0 == 0.0
            ? habit.targetValue!.toInt().toString()
            : habit.targetValue!.toString())
        : '1';

    state = HabitFormState(
      habitId: habit.id,
      isEditMode: true,
      title: habit.title,
      description: habit.description ?? '',
      motivationNotes: habit.motivationNotes ?? '',
      categoryId: habit.categoryId,
      color: habit.color,
      icon: habit.icon ?? 'check',
      targetType: habit.targetType,
      targetValue: targetValStr,
      unit: habit.unit ?? '',
      frequencyType: habit.frequencyType,
      targetDaysOfWeek:
          habit.targetDaysOfWeek?.toSet() ?? const {0, 1, 2, 3, 4, 5, 6},
      targetCountPerWeek: habit.targetCountPerWeek ?? 3,
      intervalHours: habit.intervalHours ?? 2,
      timesPerDay: habit.timesPerDay ?? 3,
      timeWindowStart: habit.timeWindow?.startTime ?? '08:00',
      timeWindowEnd: habit.timeWindow?.endTime ?? '20:00',
      reminderTimes: habit.reminderTimes,
      pinned: habit.pinned,
      promptReflection: habit.promptReflection,
      healthMetric: habit.healthMetric,
      healthSyncEnabled: habit.healthSyncEnabled,
    );
  }

  void resetForm() {
    state = const HabitFormState();
  }

  void onTitleChange(String title) {
    state = state.copyWith(title: title, clearTitleError: true);
  }

  void onDescriptionChange(String desc) {
    state = state.copyWith(description: desc);
  }

  void onMotivationChange(String notes) {
    state = state.copyWith(motivationNotes: notes);
  }

  void onCategoryChange(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categoryId: categoryId);
    }
  }

  void onColorChange(String colorHex) {
    state = state.copyWith(color: colorHex);
  }

  void onIconChange(String iconKey) {
    state = state.copyWith(icon: iconKey);
  }

  void onTargetTypeChange(HabitTargetType type) {
    String defaultTarget;
    String defaultUnit;

    switch (type) {
      case HabitTargetType.boolean:
        defaultTarget = '1';
        defaultUnit = '';
        break;
      case HabitTargetType.numeric:
        defaultTarget = '8';
        defaultUnit = 'glasses';
        break;
      case HabitTargetType.timer:
        defaultTarget = '25';
        defaultUnit = 'mins';
        break;
    }

    state = state.copyWith(
      targetType: type,
      targetValue: defaultTarget,
      unit: defaultUnit,
      clearTargetValueError: true,
    );
  }

  void onTargetValueChange(String value) {
    state = state.copyWith(targetValue: value, clearTargetValueError: true);
  }

  void onUnitChange(String unit) {
    state = state.copyWith(unit: unit);
  }

  void onFrequencyTypeChange(HabitFrequencyType type) {
    state = state.copyWith(frequencyType: type);
  }

  void toggleDayOfWeek(int dayIndex) {
    final updatedDays = Set<int>.from(state.targetDaysOfWeek);
    if (updatedDays.contains(dayIndex)) {
      if (updatedDays.length > 1) {
        updatedDays.remove(dayIndex);
      }
    } else {
      updatedDays.add(dayIndex);
    }
    state = state.copyWith(targetDaysOfWeek: updatedDays);
  }

  void onTargetCountPerWeekChange(int count) {
    state = state.copyWith(targetCountPerWeek: count.clamp(1, 6));
  }

  void onIntervalHoursChange(int hours) {
    state = state.copyWith(intervalHours: hours.clamp(1, 12));
  }

  void onTimesPerDayChange(int count) {
    state = state.copyWith(timesPerDay: count.clamp(1, 12));
  }

  void onTimeWindowChange(String start, String end) {
    state = state.copyWith(timeWindowStart: start, timeWindowEnd: end);
  }

  void addReminderTime(String time) {
    if (!state.reminderTimes.contains(time)) {
      final updated = List<String>.from(state.reminderTimes)..add(time);
      updated.sort();
      state = state.copyWith(reminderTimes: updated);
    }
  }

  void removeReminderTime(String time) {
    final updated = List<String>.from(state.reminderTimes)..remove(time);
    state = state.copyWith(reminderTimes: updated);
  }

  void onTogglePinned() {
    state = state.copyWith(pinned: !state.pinned);
  }

  void onTogglePromptReflection(bool value) {
    state = state.copyWith(promptReflection: value);
  }

  void onHealthMetricChange(HealthMetricType? metric) {
    if (metric == null) {
      state = state.copyWith(
        clearHealthMetric: true,
        healthSyncEnabled: false,
      );
    } else {
      final defaultTarget = metric.defaultTargetValue % 1.0 == 0.0
          ? metric.defaultTargetValue.toInt().toString()
          : metric.defaultTargetValue.toString();

      state = state.copyWith(
        healthMetric: metric,
        healthSyncEnabled: true,
        targetType: metric.defaultTargetType,
        targetValue: defaultTarget,
        unit: metric.defaultUnit,
        icon: metric.iconKey,
        clearTargetValueError: true,
      );
    }
  }

  void onToggleHealthSync(bool enabled) {
    state = state.copyWith(healthSyncEnabled: enabled);
  }

  Future<bool> saveHabit() async {
    if (state.title.trim().isEmpty) {
      state = state.copyWith(titleError: 'Title is required');
      return false;
    }

    final targetValParsed = double.tryParse(state.targetValue);
    if (state.targetType != HabitTargetType.boolean &&
        (targetValParsed == null || targetValParsed <= 0)) {
      state = state.copyWith(
          targetValueError: 'Enter a valid positive number');
      return false;
    }

    state = state.copyWith(isSaving: true);
    try {
      final now = DateTime.now();
      Habit? existingHabit;
      if (state.habitId != null) {
        existingHabit = await _repository.getHabitByIdOnce(state.habitId!);
      }

      final habit = Habit(
        id: state.habitId ?? const Uuid().v4(),
        title: state.title.trim(),
        description: state.description.trim().isEmpty
            ? null
            : state.description.trim(),
        color: state.color,
        icon: state.icon,
        categoryId: state.categoryId,
        frequencyType: state.frequencyType,
        targetDaysOfWeek:
            state.frequencyType == HabitFrequencyType.customDays
                ? (state.targetDaysOfWeek.toList()..sort())
                : null,
        targetCountPerWeek:
            state.frequencyType == HabitFrequencyType.weekly
                ? state.targetCountPerWeek
                : null,
        intervalHours:
            state.frequencyType == HabitFrequencyType.subdayInterval
                ? state.intervalHours
                : null,
        timesPerDay:
            state.frequencyType == HabitFrequencyType.timesPerDay
                ? state.timesPerDay
                : null,
        timeWindow: (state.frequencyType ==
                    HabitFrequencyType.subdayInterval ||
                state.frequencyType == HabitFrequencyType.timesPerDay)
            ? TimeWindow(
                startTime: state.timeWindowStart,
                endTime: state.timeWindowEnd,
              )
            : null,
        targetType: state.targetType,
        targetValue: state.targetType == HabitTargetType.boolean
            ? 1.0
            : (targetValParsed ?? 1.0),
        unit: state.targetType == HabitTargetType.boolean
            ? null
            : (state.unit.trim().isEmpty ? null : state.unit.trim()),
        pinned: state.pinned,
        reminderTimes: state.reminderTimes,
        motivationNotes: state.motivationNotes.trim().isEmpty
            ? null
            : state.motivationNotes.trim(),
        archived: existingHabit?.archived ?? false,
        promptReflection: state.promptReflection,
        healthMetric: state.healthMetric,
        healthSyncEnabled: state.healthSyncEnabled && state.healthMetric != null,
        createdAt: existingHabit?.createdAt ?? now,
        updatedAt: now,
      );

      await _repository.upsertHabit(habit);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }
}

final habitFormControllerProvider =
    StateNotifierProvider<HabitFormController, HabitFormState>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return HabitFormController(repository);
});

final categoriesStreamProvider =
    StreamProvider.autoDispose<List<HabitCategory>>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return repository.getAllCategories();
});
