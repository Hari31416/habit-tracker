import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../di/providers.dart';
import '../../domain/engines/streak_calculator.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_frequency_type.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/models/habit_routine.dart';
import '../../domain/models/habit_target_type.dart';
import '../../domain/models/routine_log.dart';
import '../common/color_utils.dart';
import '../common/habit_icon_registry.dart';
import '../common/haptics_helper.dart';

class RoutinePlayerScreen extends ConsumerStatefulWidget {
  final String routineId;
  final DateTime? targetDate;
  final VoidCallback onBack;

  const RoutinePlayerScreen({
    super.key,
    required this.routineId,
    this.targetDate,
    required this.onBack,
  });

  @override
  ConsumerState<RoutinePlayerScreen> createState() => _RoutinePlayerScreenState();
}

class _RoutinePlayerScreenState extends ConsumerState<RoutinePlayerScreen>
    with TickerProviderStateMixin {
  int _currentStepIndex = 0;
  final Set<String> _completedStepHabitIds = {};
  final Map<String, double> _numericValues = {};
  final Map<String, int> _timerSeconds = {};
  final Map<String, String> _reflectionNotes = {};

  DateTime get _effectiveDate => widget.targetDate ?? DateTime.now();

  // Timer state for timer-type habits
  Timer? _stepTimer;
  bool _isTimerRunning = false;
  int _timerRemainingSeconds = 0;
  int _timerTotalSeconds = 0;
  String? _timerHabitId;

  // Transition overlay state
  bool _isTransitioning = false;
  int _transitionCountdown = 3;
  Timer? _transitionTimer;

  // Completion State
  bool _isRoutineCompleted = false;
  RoutineLog? _awardedRoutineLog;

  @override
  void initState() {
    super.initState();
    // Distraction-free immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _transitionTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _initTimerForHabit(Habit habit) {
    _stepTimer?.cancel();
    _isTimerRunning = false;
    _timerHabitId = habit.id;
    final targetMins = (habit.targetValue ?? 25.0).toInt();
    _timerTotalSeconds = max(1, targetMins * 60);
    _timerRemainingSeconds = _timerSeconds[habit.id] ?? _timerTotalSeconds;
  }

  void _toggleStepTimer() {
    if (_isTimerRunning) {
      _stepTimer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      HapticsHelper.selectionClick();
      setState(() => _isTimerRunning = true);
      _stepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_timerRemainingSeconds > 0) {
          setState(() {
            _timerRemainingSeconds--;
          });
        } else {
          t.cancel();
          setState(() => _isTimerRunning = false);
          HapticsHelper.mediumImpact();
        }
      });
    }
  }

  void _adjustTimer(int deltaSeconds) {
    HapticsHelper.selectionClick();
    setState(() {
      _timerRemainingSeconds = max(0, _timerRemainingSeconds + deltaSeconds);
      if (_timerRemainingSeconds > _timerTotalSeconds) {
        _timerTotalSeconds = _timerRemainingSeconds;
      }
    });
  }

  void _resetTimer() {
    HapticsHelper.selectionClick();
    _stepTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerRemainingSeconds = _timerTotalSeconds;
    });
  }

  Future<void> _completeCurrentStep(Habit habit, List<Habit> chainHabits, HabitRoutine routine) async {
    HapticsHelper.mediumImpact();
    _stepTimer?.cancel();
    _isTimerRunning = false;

    _completedStepHabitIds.add(habit.id);

    final habitRepo = ref.read(habitRepositoryProvider);
    final note = _reflectionNotes[habit.id];
    final effectiveDate = _effectiveDate;

    switch (habit.targetType) {
      case HabitTargetType.boolean:
        switch (habit.frequencyType) {
          case HabitFrequencyType.timesPerDay:
          case HabitFrequencyType.subdayInterval:
            final dateStr = DateFormat('yyyy-MM-dd').format(effectiveDate);
            final allLogs = ref.read(allLogsStreamProvider).value ?? const [];
            final habitLogs = allLogs.where((l) => l.habitId == habit.id && l.date == dateStr).toList();
            final completedSlots = habitLogs
                .where((l) => l.completed && l.intervalIndex != null)
                .map((l) => l.intervalIndex!)
                .toSet();
            final totalSlots = habit.timesPerDay ?? habit.targetValue?.toInt() ?? 1;

            var targetSlotIndex = 0;
            for (var i = 0; i < totalSlots; i++) {
              if (!completedSlots.contains(i)) {
                targetSlotIndex = i;
                break;
              }
            }

            await habitRepo.logCheckIn(
              habitId: habit.id,
              date: effectiveDate,
              completed: true,
              intervalIndex: targetSlotIndex,
              note: note,
            );
            break;
          default:
            await habitRepo.logCheckIn(
              habitId: habit.id,
              date: effectiveDate,
              completed: true,
              note: note,
            );
        }
        break;

      case HabitTargetType.numeric:
        final dateStr = DateFormat('yyyy-MM-dd').format(effectiveDate);
        final allLogs = ref.read(allLogsStreamProvider).value ?? const [];
        final habitLogs = allLogs.where((l) => l.habitId == habit.id && l.date == dateStr).toList();
        final existingVal = habitLogs.fold<double>(0.0, (s, l) => s + (l.value ?? 0.0));
        final target = habit.targetValue ?? 10.0;

        final numVal = _numericValues[habit.id] ?? (existingVal > 0 ? existingVal : min(target, 5.0));
        await habitRepo.updateNumericValue(
          habit.id,
          effectiveDate,
          numVal,
        );
        if (note != null && note.isNotEmpty) {
          await habitRepo.updateReflection(
            habitId: habit.id,
            date: effectiveDate,
            note: note,
          );
        }
        break;

      case HabitTargetType.timer:
        final elapsed = _timerTotalSeconds - _timerRemainingSeconds;
        final targetMin = habit.targetValue ?? 25.0;
        final durationSecs = elapsed > 0 ? elapsed : (targetMin * 60).round();
        await habitRepo.logCheckIn(
          habitId: habit.id,
          date: effectiveDate,
          completed: true,
          durationSeconds: durationSecs,
          value: durationSecs / 60.0,
          note: note,
        );
        break;
    }

    if (_currentStepIndex < chainHabits.length - 1) {
      // Show transition cue before next step
      _startTransitionCue(chainHabits);
    } else {
      // Final step completed! Complete the entire routine
      await _finishRoutine(routine, chainHabits);
    }
  }

  void _startTransitionCue(List<Habit> chainHabits) {
    _transitionTimer?.cancel();
    setState(() {
      _isTransitioning = true;
      _transitionCountdown = 3;
    });

    _transitionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_transitionCountdown > 1) {
        setState(() {
          _transitionCountdown--;
        });
      } else {
        t.cancel();
        _advanceToNextStep(chainHabits);
      }
    });
  }

  void _advanceToNextStep(List<Habit> chainHabits) {
    _transitionTimer?.cancel();
    if (_currentStepIndex < chainHabits.length - 1) {
      setState(() {
        _isTransitioning = false;
        _currentStepIndex++;
        final nextHabit = chainHabits[_currentStepIndex];
        if (nextHabit.targetType == HabitTargetType.timer) {
          _initTimerForHabit(nextHabit);
        }
      });
    }
  }

  Future<void> _finishRoutine(HabitRoutine routine, List<Habit> chainHabits) async {
    final targetDateStr = DateFormat('yyyy-MM-dd').format(_effectiveDate);
    final routineRepo = ref.read(routineRepositoryProvider);

    final routineLog = await routineRepo.completeRoutine(
      routineId: routine.id,
      date: targetDateStr,
      completedHabitIds: _completedStepHabitIds.toList(),
    );

    HapticsHelper.celebrate();
    if (mounted) {
      setState(() {
        _isTransitioning = false;
        _isRoutineCompleted = true;
        _awardedRoutineLog = routineLog;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routinesAsync = ref.watch(activeRoutinesStreamProvider);
    final habitsAsync = ref.watch(activeHabitsStreamProvider);

    final allRoutines = routinesAsync.value ?? const [];
    final allHabits = habitsAsync.value ?? const [];
    final habitMap = {for (final h in allHabits) h.id: h};

    final routine = allRoutines.firstWhere(
      (r) => r.id == widget.routineId,
      orElse: () => HabitRoutine(
        id: widget.routineId,
        title: 'Routine Flow',
        color: '#3B82F6',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final chainHabits = routine.habitIds
        .map((id) => habitMap[id])
        .whereType<Habit>()
        .toList();

    if (_isRoutineCompleted) {
      return _buildCelebrationScreen(context, routine, chainHabits);
    }

    if (chainHabits.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 48),
              const SizedBox(height: 16),
              const Text('No habits configured in this stack.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: widget.onBack,
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentStep = _currentStepIndex.clamp(0, chainHabits.length - 1);
    final currentHabit = chainHabits[currentStep];

    final logsAsync = ref.watch(allLogsStreamProvider);
    final allLogs = logsAsync.value ?? const [];
    final dateStr = DateFormat('yyyy-MM-dd').format(_effectiveDate);
    final todayLogs = allLogs.where((l) => l.date == dateStr).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Top Navigation & Step Indicator
                  _buildHeader(context, routine, chainHabits, currentStep),

                  // Main Interactive Stage
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildStepContextCard(context, routine, chainHabits, currentStep, currentHabit),
                          const SizedBox(height: 24),
                          _buildHabitInteractiveStage(context, currentHabit, todayLogs),
                          const SizedBox(height: 20),
                          _buildReflectionInput(context, currentHabit),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  _buildBottomBar(context, routine, chainHabits, currentStep, currentHabit),
                ],
              ),

              // Step Transition Overlay
              if (_isTransitioning)
                _buildTransitionOverlay(context, chainHabits, currentStep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    HabitRoutine routine,
    List<Habit> chainHabits,
    int currentStep,
  ) {
    final theme = Theme.of(context);
    final routineColor = ColorUtils.fromHex(routine.color);

    final effectiveDate = _effectiveDate;
    final now = DateTime.now();
    final isToday = effectiveDate.year == now.year &&
        effectiveDate.month == now.month &&
        effectiveDate.day == now.day;
    final stepSubtitle = isToday
        ? 'Step ${currentStep + 1} of ${chainHabits.length}'
        : 'Step ${currentStep + 1} of ${chainHabits.length} • ${DateFormat('EEE, MMM d').format(effectiveDate)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Semantics(
                identifier: 'btn_player_close',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _confirmExit(context),
                  tooltip: 'Exit Routine Flow',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stepSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      '+${routine.bonusXp} XP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Step Progress Bar
          LinearProgressIndicator(
            value: (currentStep + 1) / chainHabits.length,
            backgroundColor: routineColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(routineColor),
            borderRadius: BorderRadius.circular(4),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildStepContextCard(
    BuildContext context,
    HabitRoutine routine,
    List<Habit> chainHabits,
    int currentStep,
    Habit habit,
  ) {
    final theme = Theme.of(context);
    final habitColor = ColorUtils.fromHex(habit.color);

    String sequenceSubtitle;
    if (currentStep == 0) {
      sequenceSubtitle = chainHabits.length > 1
          ? 'First step in the stack. Up next: ${chainHabits[1].title}'
          : 'Trigger habit';
    } else {
      final prev = chainHabits[currentStep - 1].title;
      sequenceSubtitle = currentStep < chainHabits.length - 1
          ? 'After $prev → Next: ${chainHabits[currentStep + 1].title}'
          : 'After $prev (Final step!)';
    }

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: habitColor.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: habitColor.withValues(alpha: 0.4), width: 2),
          ),
          child: Icon(
            HabitIconRegistry.getIcon(habit.icon),
            color: habitColor,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          habit.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          sequenceSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (habit.motivationNotes != null && habit.motivationNotes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"${habit.motivationNotes}"',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHabitInteractiveStage(
    BuildContext context,
    Habit habit,
    List<HabitLog> todayLogs,
  ) {
    switch (habit.targetType) {
      case HabitTargetType.timer:
        return _buildTimerHabitStage(context, habit);
      case HabitTargetType.numeric:
        return _buildNumericHabitStage(context, habit, todayLogs);
      case HabitTargetType.boolean:
        return _buildBooleanHabitStage(context, habit, todayLogs);
    }
  }

  Widget _buildTimerHabitStage(BuildContext context, Habit habit) {
    final theme = Theme.of(context);
    final habitColor = ColorUtils.fromHex(habit.color);

    if (_timerHabitId != habit.id || _timerTotalSeconds == 0) {
      _timerHabitId = habit.id;
      final targetMins = (habit.targetValue ?? 25.0).toInt();
      _timerTotalSeconds = max(1, targetMins * 60);
      _timerRemainingSeconds = _timerSeconds[habit.id] ?? _timerTotalSeconds;
    }

    final mins = _timerRemainingSeconds ~/ 60;
    final secs = _timerRemainingSeconds % 60;
    final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    final progress = _timerTotalSeconds > 0
        ? (1.0 - (_timerRemainingSeconds / _timerTotalSeconds)).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: habitColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(habitColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isTimerRunning
                        ? 'In Flow State'
                        : (_timerRemainingSeconds == 0 ? 'Goal Reached' : 'Ready'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Timer Controls
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              identifier: 'btn_timer_minus',
              button: true,
              child: IconButton.filledTonal(
                iconSize: 20,
                onPressed: () => _adjustTimer(-60),
                icon: const Text('-1m', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                tooltip: '-1 Minute',
              ),
            ),
            Semantics(
              identifier: 'btn_timer_toggle',
              button: true,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: habitColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _toggleStepTimer,
                icon: Icon(_isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(
                  _isTimerRunning ? 'Pause' : 'Start Timer',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Semantics(
              identifier: 'btn_timer_plus',
              button: true,
              child: IconButton.filledTonal(
                iconSize: 20,
                onPressed: () => _adjustTimer(60),
                icon: const Text('+1m', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                tooltip: '+1 Minute',
              ),
            ),
            Semantics(
              identifier: 'btn_timer_reset',
              button: true,
              child: IconButton.filledTonal(
                iconSize: 20,
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'Reset Timer',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumericHabitStage(
    BuildContext context,
    Habit habit,
    List<HabitLog> todayLogs,
  ) {
    final theme = Theme.of(context);
    final habitColor = ColorUtils.fromHex(habit.color);
    final target = habit.targetValue ?? 10.0;
    final habitLogs = todayLogs.where((l) => l.habitId == habit.id).toList();
    final existingVal = habitLogs.fold<double>(0.0, (s, l) => s + (l.value ?? 0.0));
    final defaultInitial = existingVal > 0 ? existingVal : min(target, 5.0);
    final currentVal = _numericValues[habit.id] ?? defaultInitial;
    final unit = habit.unit ?? 'units';
    final progressFraction = target > 0 ? (currentVal / target).clamp(0.0, 1.0) : 1.0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                '${currentVal.toStringAsFixed(currentVal.truncateToDouble() == currentVal ? 0 : 1)} / ${target.toStringAsFixed(target.truncateToDouble() == target ? 0 : 1)} $unit',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progressFraction,
                backgroundColor: habitColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(habitColor),
                borderRadius: BorderRadius.circular(6),
                minHeight: 8,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      HapticsHelper.selectionClick();
                      setState(() {
                        _numericValues[habit.id] = max(0.0, currentVal - 1.0);
                      });
                    },
                    icon: const Icon(Icons.remove),
                    tooltip: '-1 $unit',
                  ),
                  Semantics(
                    identifier: 'btn_numeric_plus_5',
                    button: true,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () {
                        HapticsHelper.selectionClick();
                        setState(() {
                          _numericValues[habit.id] = currentVal + 5.0;
                        });
                      },
                      child: const Text('+5'),
                    ),
                  ),
                  Semantics(
                    identifier: 'btn_numeric_fill',
                    button: true,
                    child: FilledButton.tonal(
                      onPressed: () {
                        HapticsHelper.selectionClick();
                        setState(() {
                          _numericValues[habit.id] = target;
                        });
                      },
                      child: Text('Fill (${target.truncateToDouble() == target ? target.toInt() : target})'),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      HapticsHelper.selectionClick();
                      setState(() {
                        _numericValues[habit.id] = currentVal + 1.0;
                      });
                    },
                    icon: const Icon(Icons.add),
                    tooltip: '+1 $unit',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBooleanHabitStage(
    BuildContext context,
    Habit habit,
    List<HabitLog> todayLogs,
  ) {
    final theme = Theme.of(context);
    final habitColor = ColorUtils.fromHex(habit.color);
    final isMultiSlot = habit.frequencyType == HabitFrequencyType.timesPerDay ||
        habit.frequencyType == HabitFrequencyType.subdayInterval;
    final totalSlots = habit.timesPerDay ?? habit.targetValue?.toInt() ?? 1;

    final habitLogs = todayLogs.where((l) => l.habitId == habit.id).toList();
    final completedSlots = habitLogs
        .where((l) => l.completed && l.intervalIndex != null)
        .map((l) => l.intervalIndex!)
        .toSet();

    final isDone = _completedStepHabitIds.contains(habit.id) ||
        StreakCalculator.isHabitStepSatisfiedForRoutine(habit, habitLogs);

    var nextSlot = 0;
    if (isMultiSlot) {
      for (var i = 0; i < totalSlots; i++) {
        if (!completedSlots.contains(i)) {
          nextSlot = i;
          break;
        }
      }
    }

    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: isDone ? Colors.green.withValues(alpha: 0.15) : habitColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? Colors.green : habitColor,
              width: 3,
            ),
          ),
          child: Center(
            child: Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 64,
              color: isDone ? Colors.green : habitColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isDone ? 'Habit Step Finished' : 'Perform this habit now',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDone ? Colors.green : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (isMultiSlot && totalSlots > 1) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: habitColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Logging Check-in #${nextSlot + 1} of $totalSlots',
              style: theme.textTheme.labelMedium?.copyWith(
                color: habitColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daily Target: ${habit.timesPerDay} check-ins',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReflectionInput(BuildContext context, Habit habit) {
    final theme = Theme.of(context);
    return TextField(
      onChanged: (val) => _reflectionNotes[habit.id] = val,
      decoration: InputDecoration(
        hintText: 'Add a 1-line reflection note (optional)...',
        prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    HabitRoutine routine,
    List<Habit> chainHabits,
    int currentStep,
    Habit habit,
  ) {
    final theme = Theme.of(context);
    final isLastStep = currentStep == chainHabits.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Semantics(
              identifier: 'btn_step_previous',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Previous Step',
                onPressed: () {
                  HapticsHelper.selectionClick();
                  _stepTimer?.cancel();
                  setState(() {
                    _isTimerRunning = false;
                    _currentStepIndex--;
                    final prevHabit = chainHabits[_currentStepIndex];
                    if (prevHabit.targetType == HabitTargetType.timer) {
                      _initTimerForHabit(prevHabit);
                    }
                  });
                },
              ),
            ),
          Semantics(
            identifier: 'btn_step_skip',
            button: true,
            child: TextButton(
              onPressed: () {
                HapticsHelper.selectionClick();
                _stepTimer?.cancel();
                if (!isLastStep) {
                  setState(() {
                    _isTimerRunning = false;
                    _currentStepIndex++;
                    final nextHabit = chainHabits[_currentStepIndex];
                    if (nextHabit.targetType == HabitTargetType.timer) {
                      _initTimerForHabit(nextHabit);
                    }
                  });
                } else {
                  _finishRoutine(routine, chainHabits);
                }
              },
              child: const Text('Skip Step'),
            ),
          ),
          const Spacer(),
          Semantics(
            identifier: 'btn_step_complete',
            button: true,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _completeCurrentStep(habit, chainHabits, routine),
              icon: Icon(isLastStep ? Icons.emoji_events_rounded : Icons.check_rounded),
              label: Text(
                isLastStep ? 'Complete Stack' : 'Done & Next',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionOverlay(
    BuildContext context,
    List<Habit> chainHabits,
    int currentStep,
  ) {
    final theme = Theme.of(context);
    final nextHabit = currentStep < chainHabits.length - 1 ? chainHabits[currentStep + 1] : null;

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 56, color: Colors.green),
              const SizedBox(height: 12),
              Text(
                'Step Complete!',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (nextHabit != null) ...[
                Text(
                  'Up next in the chain: ${nextHabit.title}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Semantics(
                identifier: 'btn_step_continue',
                button: true,
                child: FilledButton(
                  onPressed: () => _advanceToNextStep(chainHabits),
                  child: Text('Continue ($_transitionCountdown s)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationScreen(
    BuildContext context,
    HabitRoutine routine,
    List<Habit> chainHabits,
  ) {
    final theme = Theme.of(context);
    final bonusXp = _awardedRoutineLog?.xpEarned ?? routine.bonusXp;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 52,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Stack Completed!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You completed all steps in "${routine.title}" sequentially.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Bonus XP Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, color: Colors.amber, size: 28),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '+$bonusXp XP Bonus',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          Text(
                            'Routine Completion Bonus',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Semantics(
                  identifier: 'btn_routine_finish',
                  button: true,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    if (_completedStepHabitIds.isEmpty) {
      widget.onBack();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Routine Flow?'),
        content: const Text(
          'Completed steps have been saved for today. You can resume the remaining steps anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onBack();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
