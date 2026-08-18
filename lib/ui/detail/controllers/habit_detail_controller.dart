import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../di/providers.dart';
import '../../../domain/engines/shield_banking_engine.dart';
import '../../../domain/engines/streak_calculator.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_category.dart';
import '../../../domain/models/habit_log.dart';
import '../../../domain/models/habit_shield.dart';
import '../../../domain/models/habit_target_type.dart';
import '../../../domain/repositories/gamification_repository.dart';
import '../../../domain/repositories/habit_repository.dart';

class HabitDetailUiState {
  final Habit? habit;
  final HabitCategory? category;
  final List<HabitLog> allLogs;
  final List<HabitShield> allShields;
  final List<HabitLog> logsForSelectedDate;
  final DateTime selectedDate;
  final DateTime currentMonth;
  final StreakResult streak;
  final bool isCompletedOnSelectedDate;
  final bool isShieldedOnSelectedDate;
  final double currentValueOnSelectedDate;
  final ShieldBankState? shieldBank;
  final bool isLoading;
  final bool isDeleted;

  HabitDetailUiState({
    this.habit,
    this.category,
    this.allLogs = const [],
    this.allShields = const [],
    this.logsForSelectedDate = const [],
    DateTime? selectedDate,
    DateTime? currentMonth,
    this.streak = const StreakResult(
      currentStreak: 0,
      bestStreak: 0,
      completionRate30Days: 0,
      totalCompletions: 0,
    ),
    this.isCompletedOnSelectedDate = false,
    this.isShieldedOnSelectedDate = false,
    this.currentValueOnSelectedDate = 0.0,
    this.shieldBank,
    this.isLoading = true,
    this.isDeleted = false,
  })  : selectedDate = selectedDate ?? DateTime.now(),
        currentMonth = currentMonth ??
            DateTime(DateTime.now().year, DateTime.now().month, 1);

  HabitDetailUiState copyWith({
    Habit? habit,
    HabitCategory? category,
    List<HabitLog>? allLogs,
    List<HabitShield>? allShields,
    List<HabitLog>? logsForSelectedDate,
    DateTime? selectedDate,
    DateTime? currentMonth,
    StreakResult? streak,
    bool? isCompletedOnSelectedDate,
    bool? isShieldedOnSelectedDate,
    double? currentValueOnSelectedDate,
    ShieldBankState? shieldBank,
    bool? isLoading,
    bool? isDeleted,
    bool clearHabit = false,
  }) {
    return HabitDetailUiState(
      habit: clearHabit ? null : (habit ?? this.habit),
      category: category ?? this.category,
      allLogs: allLogs ?? this.allLogs,
      allShields: allShields ?? this.allShields,
      logsForSelectedDate: logsForSelectedDate ?? this.logsForSelectedDate,
      selectedDate: selectedDate ?? this.selectedDate,
      currentMonth: currentMonth ?? this.currentMonth,
      streak: streak ?? this.streak,
      isCompletedOnSelectedDate:
          isCompletedOnSelectedDate ?? this.isCompletedOnSelectedDate,
      isShieldedOnSelectedDate:
          isShieldedOnSelectedDate ?? this.isShieldedOnSelectedDate,
      currentValueOnSelectedDate:
          currentValueOnSelectedDate ?? this.currentValueOnSelectedDate,
      shieldBank: shieldBank ?? this.shieldBank,
      isLoading: isLoading ?? this.isLoading,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class HabitDetailController extends StateNotifier<HabitDetailUiState> {
  final String habitId;
  final HabitRepository repository;
  final GamificationRepository? gamificationRepository;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  StreamSubscription? _habitSubscription;
  StreamSubscription? _logsSubscription;
  StreamSubscription? _shieldsSubscription;
  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _shieldBankSubscription;

  Habit? _currentHabit;
  List<HabitLog> _currentLogs = [];
  List<HabitShield> _currentShields = [];
  List<HabitCategory> _currentCategories = [];
  ShieldBankState? _currentShieldBank;

  final StreamController<void> _navigateBackController =
      StreamController<void>.broadcast();
  Stream<void> get navigateBackEvent => _navigateBackController.stream;

  HabitDetailController({
    required this.habitId,
    required this.repository,
    this.gamificationRepository,
  }) : super(HabitDetailUiState(isLoading: true)) {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _habitSubscription = repository.getHabitById(habitId).listen((habit) {
      _currentHabit = habit;
      _recomputeState();
    });

    _logsSubscription = repository.getLogsForHabit(habitId).listen((logs) {
      _currentLogs = logs;
      _recomputeState();
    });

    _shieldsSubscription = repository.getShieldsForHabit(habitId).listen((shields) {
      _currentShields = shields;
      _recomputeState();
    });

    _categoriesSubscription = repository.getAllCategories().listen((categories) {
      _currentCategories = categories;
      _recomputeState();
    });

    _shieldBankSubscription = gamificationRepository?.getShieldBankState().listen((bank) {
      _currentShieldBank = bank;
      _recomputeState();
    });
  }

  void _recomputeState() {
    final habit = _currentHabit;
    if (habit == null) {
      state = state.copyWith(
        clearHabit: true,
        isLoading: false,
        isDeleted: true,
      );
      return;
    }

    final category = _currentCategories
        .where((c) => c.id == habit.categoryId)
        .firstOrNull;

    final dateStr = _dateFormatter.format(state.selectedDate);
    final logsOnDate =
        _currentLogs.where((log) => log.date == dateStr).toList();
    final isCompleted =
        StreakCalculator.isHabitCompletedOnDate(habit, logsOnDate);
    final isShielded = _currentShields.any((s) => s.date == dateStr);

    final currentValue = _calculateCurrentValue(habit, logsOnDate, isCompleted);
    final streak = StreakCalculator.calculateStreak(
      habit,
      _currentLogs,
      DateTime.now(),
      _currentShields,
    );

    state = HabitDetailUiState(
      habit: habit,
      category: category,
      allLogs: _currentLogs,
      allShields: _currentShields,
      logsForSelectedDate: logsOnDate,
      selectedDate: state.selectedDate,
      currentMonth: state.currentMonth,
      streak: streak,
      isCompletedOnSelectedDate: isCompleted,
      isShieldedOnSelectedDate: isShielded,
      currentValueOnSelectedDate: currentValue,
      shieldBank: _currentShieldBank,
      isLoading: false,
      isDeleted: false,
    );
  }

  double _calculateCurrentValue(
    Habit habit,
    List<HabitLog> logsOnDate,
    bool isCompleted,
  ) {
    switch (habit.targetType) {
      case HabitTargetType.boolean:
        return isCompleted ? 1.0 : 0.0;
      case HabitTargetType.numeric:
        return logsOnDate.fold<double>(
          0.0,
          (sum, log) =>
              sum +
              (log.value ??
                  (log.completed ? (habit.targetValue ?? 1.0) : 0.0)),
        );
      case HabitTargetType.timer:
        return logsOnDate.fold<double>(
          0.0,
          (sum, log) {
            if (log.durationSeconds != null && log.durationSeconds! > 0) {
              return sum + (log.durationSeconds! / 60.0);
            } else {
              return sum +
                  (log.value ??
                      (log.completed ? (habit.targetValue ?? 25.0) : 0.0));
            }
          },
        );
    }
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    _recomputeState();
  }

  void previousMonth() {
    final current = state.currentMonth;
    final prevMonth = DateTime(current.year, current.month - 1, 1);
    state = state.copyWith(currentMonth: prevMonth);
  }

  void nextMonth() {
    final current = state.currentMonth;
    final nextMonth = DateTime(current.year, current.month + 1, 1);
    state = state.copyWith(currentMonth: nextMonth);
  }

  Future<void> setPinned(bool pinned) async {
    await repository.setPinned(habitId, pinned);
  }

  Future<void> setArchived(bool archived) async {
    await repository.setArchived(habitId, archived);
  }

  Future<void> deleteHabit() async {
    final habit = await repository.getHabitByIdOnce(habitId);
    if (habit != null) {
      await repository.deleteHabit(habit);
      _navigateBackController.add(null);
    }
  }

  Future<void> set10DotProgress(double targetValueForDot) async {
    await repository.updateNumericValue(
      habitId,
      state.selectedDate,
      targetValueForDot,
    );
  }

  Future<void> addNumericDelta(double delta) async {
    await repository.addNumericDelta(
      habitId,
      state.selectedDate,
      delta,
    );
  }

  Future<void> updateNumericValue(double value) async {
    await repository.updateNumericValue(
      habitId,
      state.selectedDate,
      value,
    );
  }

  Future<void> toggleSlot(int slotIndex) async {
    await repository.toggleSlotCheckIn(
      habitId,
      state.selectedDate,
      slotIndex,
    );
  }

  Future<void> toggleCheckInForDate(DateTime date) async {
    await repository.toggleBooleanCheckIn(habitId, date);
  }

  Future<void> toggleShieldForSelectedDate() async {
    await repository.toggleShield(habitId, state.selectedDate);
  }

  Future<void> toggleReminder(String time) async {
    final habit = await repository.getHabitByIdOnce(habitId);
    if (habit == null) return;

    final updatedReminders = habit.reminderTimes.contains(time)
        ? habit.reminderTimes.where((t) => t != time).toList()
        : [...habit.reminderTimes, time]
      ..sort();

    await repository.upsertHabit(
      habit.copyWith(reminderTimes: updatedReminders),
    );
  }

  @override
  void dispose() {
    _habitSubscription?.cancel();
    _logsSubscription?.cancel();
    _shieldsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _shieldBankSubscription?.cancel();
    _navigateBackController.close();
    super.dispose();
  }
}

final habitDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<HabitDetailController, HabitDetailUiState, String>((ref, habitId) {
  final repo = ref.watch(habitRepositoryProvider);
  final gamificationRepo = ref.watch(gamificationRepositoryProvider);
  return HabitDetailController(
    habitId: habitId,
    repository: repo,
    gamificationRepository: gamificationRepo,
  );
});
