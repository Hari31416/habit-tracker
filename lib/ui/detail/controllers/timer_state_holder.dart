import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../di/providers.dart';
import '../../../domain/repositories/habit_repository.dart';
import '../../common/haptics_helper.dart';

enum TimerStatus {
  idle,
  running,
  paused,
  completed,
}

class TimerState {
  final String? habitId;
  final String habitTitle;
  final int totalSeconds;
  final int remainingSeconds;
  final TimerStatus status;
  final DateTime? targetEndTime;

  const TimerState({
    this.habitId,
    this.habitTitle = '',
    this.totalSeconds = 25 * 60,
    this.remainingSeconds = 25 * 60,
    this.status = TimerStatus.idle,
    this.targetEndTime,
  });

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isCompleted => status == TimerStatus.completed;
  bool get focusModeActive =>
      status == TimerStatus.running || status == TimerStatus.paused;

  double get progress {
    if (totalSeconds > 0) {
      return ((totalSeconds - remainingSeconds) / totalSeconds)
          .clamp(0.0, 1.0);
    }
    return 0.0;
  }

  TimerState copyWith({
    String? habitId,
    String? habitTitle,
    int? totalSeconds,
    int? remainingSeconds,
    TimerStatus? status,
    DateTime? targetEndTime,
    bool clearTargetEndTime = false,
  }) {
    return TimerState(
      habitId: habitId ?? this.habitId,
      habitTitle: habitTitle ?? this.habitTitle,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
      targetEndTime: clearTargetEndTime
          ? null
          : (targetEndTime ?? this.targetEndTime),
    );
  }
}

class TimerStateHolderNotifier extends StateNotifier<TimerState> {
  static const MethodChannel _nativeChannel =
      MethodChannel('com.productivity.habits/focus_timer');

  final HabitRepository? _repository;
  Timer? _ticker;
  bool _applyingNativeEvent = false;

  TimerStateHolderNotifier([this._repository]) : super(const TimerState()) {
    _bindNativeEvents();
  }

  void _bindNativeEvents() {
    _nativeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNativeTimerEvent' && call.arguments is Map) {
        applyNativeState(Map<String, dynamic>.from(call.arguments as Map));
      }
    });
  }

  /// Applies pause/resume/stop/complete from the native notification service.
  void applyNativeState(Map<String, dynamic> payload) {
    final rawStatus = payload['status'] as String? ?? 'Ready';
    final habitId = payload['habitId'] as String?;
    final habitTitle = payload['habitTitle'] as String?;
    final totalSeconds = (payload['totalSeconds'] as num?)?.toInt();
    final remainingSeconds = (payload['remainingSeconds'] as num?)?.toInt();

    final mapped = switch (rawStatus) {
      'Running' => TimerStatus.running,
      'Paused' => TimerStatus.paused,
      'Done' => TimerStatus.completed,
      _ => TimerStatus.idle,
    };

    _applyingNativeEvent = true;
    try {
      if (mapped == TimerStatus.idle) {
        if (state.focusModeActive || state.isCompleted) {
          _ticker?.cancel();
          state = const TimerState();
        }
        return;
      }

      _ticker?.cancel();

      final remaining = remainingSeconds ?? state.remainingSeconds;
      final total = totalSeconds ?? state.totalSeconds;
      final endTime = mapped == TimerStatus.running
          ? DateTime.now().add(Duration(seconds: remaining))
          : null;

      state = TimerState(
        habitId: habitId ?? state.habitId,
        habitTitle: habitTitle ?? state.habitTitle,
        totalSeconds: total,
        remainingSeconds: remaining,
        status: mapped,
        targetEndTime: endTime,
      );

      if (mapped == TimerStatus.running) {
        _startTicker();
      }
    } finally {
      _applyingNativeEvent = false;
    }
  }

  Future<void> syncFromNative() async {
    try {
      final raw = await _nativeChannel.invokeMethod<String>('getTimerState');
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        applyNativeState(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  void start(String habitId, String habitTitle, double durationMinutes) {
    _ticker?.cancel();
    final totalSec = (durationMinutes * 60).toInt().clamp(60, 24 * 3600);
    final endTime = DateTime.now().add(Duration(seconds: totalSec));

    state = TimerState(
      habitId: habitId,
      habitTitle: habitTitle,
      totalSeconds: totalSec,
      remainingSeconds: totalSec,
      status: TimerStatus.running,
      targetEndTime: endTime,
    );

    _callNativeTimer('startTimer', {
      'habitId': habitId,
      'habitTitle': habitTitle,
      'durationMinutes': durationMinutes,
    });

    _startTicker();
  }

  void resume() {
    if (state.isPaused) {
      _ticker?.cancel();
      final endTime = DateTime.now().add(Duration(seconds: state.remainingSeconds));
      state = state.copyWith(
        status: TimerStatus.running,
        targetEndTime: endTime,
      );
      if (!_applyingNativeEvent) {
        _callNativeTimer('resumeTimer');
      }
      _startTicker();
    }
  }

  void pause() {
    if (state.isRunning) {
      _ticker?.cancel();
      state = state.copyWith(
        status: TimerStatus.paused,
        clearTargetEndTime: true,
      );
      if (!_applyingNativeEvent) {
        _callNativeTimer('pauseTimer');
      }
    }
  }

  void reset() {
    _ticker?.cancel();
    state = state.copyWith(
      remainingSeconds: state.totalSeconds,
      status: TimerStatus.idle,
      clearTargetEndTime: true,
    );
    if (!_applyingNativeEvent) {
      _callNativeTimer('stopTimer');
    }
  }

  void stop() {
    _ticker?.cancel();
    state = const TimerState();
    if (!_applyingNativeEvent) {
      _callNativeTimer('stopTimer');
    }
  }

  void tick(int remainingSec) {
    if (remainingSec <= 0) {
      _ticker?.cancel();
      state = state.copyWith(
        remainingSeconds: 0,
        status: TimerStatus.completed,
        clearTargetEndTime: true,
      );
      _onTimerCompleted();
    } else {
      state = state.copyWith(remainingSeconds: remainingSec);
    }
  }

  void adjustRemaining(int deltaSeconds) {
    final newRemaining =
        (state.remainingSeconds + deltaSeconds).clamp(0, 24 * 3600);
    final newTotal = state.totalSeconds < newRemaining
        ? newRemaining
        : state.totalSeconds;

    final newEndTime = state.isRunning
        ? DateTime.now().add(Duration(seconds: newRemaining))
        : null;

    _callNativeTimer('adjustTimer', {'deltaSeconds': deltaSeconds});

    if (newRemaining <= 0) {
      _ticker?.cancel();
      state = state.copyWith(
        remainingSeconds: 0,
        totalSeconds: newTotal,
        status: TimerStatus.completed,
        clearTargetEndTime: true,
      );
      _onTimerCompleted();
    } else {
      state = state.copyWith(
        remainingSeconds: newRemaining,
        totalSeconds: newTotal,
        targetEndTime: newEndTime,
      );
    }
  }

  void _callNativeTimer(String method, [Map<String, dynamic>? args]) {
    if (_applyingNativeEvent) return;
    try {
      _nativeChannel.invokeMethod(method, args).catchError((_) => null);
    } catch (_) {}
  }

  void setRemainingMinutes(int minutes) {
    final sec = (minutes * 60).clamp(60, 24 * 3600);
    final isRunning = state.isRunning;
    final newEndTime =
        isRunning ? DateTime.now().add(Duration(seconds: sec)) : null;

    state = state.copyWith(
      remainingSeconds: sec,
      totalSeconds: sec,
      status: isRunning ? TimerStatus.running : TimerStatus.idle,
      targetEndTime: newEndTime,
    );
  }

  void complete() {
    _ticker?.cancel();
    state = state.copyWith(
      remainingSeconds: 0,
      status: TimerStatus.completed,
      clearTargetEndTime: true,
    );
    _onTimerCompleted();
  }

  void setDuration(String habitId, String habitTitle, double durationMinutes) {
    _ticker?.cancel();
    final sec = (durationMinutes * 60).toInt().clamp(60, 24 * 3600);
    state = TimerState(
      habitId: habitId,
      habitTitle: habitTitle,
      totalSeconds: sec,
      remainingSeconds: sec,
      status: TimerStatus.idle,
    );
  }

  void recalculateOnResume() {
    if (state.isRunning && state.targetEndTime != null) {
      final now = DateTime.now();
      final diff = state.targetEndTime!.difference(now).inSeconds;
      tick(diff);
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.targetEndTime != null) {
        final diff = state.targetEndTime!.difference(DateTime.now()).inSeconds;
        tick(diff);
      } else {
        tick(state.remainingSeconds - 1);
      }
    });
  }

  void _onTimerCompleted() {
    final habitId = state.habitId;
    final totalSec = state.totalSeconds;
    final totalMin = totalSec / 60.0;

    if (habitId != null && habitId.isNotEmpty && _repository != null) {
      _repository.logCheckIn(
        habitId: habitId,
        date: DateTime.now(),
        completed: true,
        value: totalMin,
        durationSeconds: totalSec,
        note: 'Completed focus timer session (${totalMin.toInt()} mins)',
      );
    }

    try {
      HapticsHelper.performHeavyConfirmationHaptic();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

// Global Singleton for non-Riverpod access and direct parity with TimerStateHolder
class TimerStateHolder {
  static TimerState _state = const TimerState();
  static final List<void Function(TimerState)> _listeners = [];
  static Timer? _ticker;
  static HabitRepository? repository;

  static TimerState get timerState => _state;

  static void addListener(void Function(TimerState) listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function(TimerState) listener) {
    _listeners.remove(listener);
  }

  static void _updateState(TimerState newState) {
    _state = newState;
    for (final listener in List.of(_listeners)) {
      listener(_state);
    }
  }

  static void start(String habitId, String habitTitle, double durationMinutes) {
    _ticker?.cancel();
    final totalSec = (durationMinutes * 60).toInt().clamp(60, 24 * 3600);
    final endTime = DateTime.now().add(Duration(seconds: totalSec));

    _updateState(TimerState(
      habitId: habitId,
      habitTitle: habitTitle,
      totalSeconds: totalSec,
      remainingSeconds: totalSec,
      status: TimerStatus.running,
      targetEndTime: endTime,
    ));

    _callNativeStaticTimer('startTimer', {
      'habitId': habitId,
      'habitTitle': habitTitle,
      'durationMinutes': durationMinutes,
    });

    _startTicker();
  }

  static void resume() {
    if (_state.isPaused) {
      _ticker?.cancel();
      final endTime = DateTime.now().add(Duration(seconds: _state.remainingSeconds));
      _updateState(_state.copyWith(
        status: TimerStatus.running,
        targetEndTime: endTime,
      ));
      _callNativeStaticTimer('resumeTimer');
      _startTicker();
    }
  }

  static void pause() {
    if (_state.isRunning) {
      _ticker?.cancel();
      _updateState(_state.copyWith(
        status: TimerStatus.paused,
        clearTargetEndTime: true,
      ));
      _callNativeStaticTimer('pauseTimer');
    }
  }

  static void reset() {
    _ticker?.cancel();
    _updateState(_state.copyWith(
      remainingSeconds: _state.totalSeconds,
      status: TimerStatus.idle,
      clearTargetEndTime: true,
    ));
    _callNativeStaticTimer('stopTimer');
  }

  static void stop() {
    _ticker?.cancel();
    _updateState(const TimerState());
    _callNativeStaticTimer('stopTimer');
  }

  static void tick(int remainingSec) {
    if (remainingSec <= 0) {
      _ticker?.cancel();
      _updateState(_state.copyWith(
        remainingSeconds: 0,
        status: TimerStatus.completed,
        clearTargetEndTime: true,
      ));
      _onTimerCompleted();
    } else {
      _updateState(_state.copyWith(remainingSeconds: remainingSec));
    }
  }

  static void adjustRemaining(int deltaSeconds) {
    final newRemaining =
        (_state.remainingSeconds + deltaSeconds).clamp(0, 24 * 3600);
    final newTotal = _state.totalSeconds < newRemaining
        ? newRemaining
        : _state.totalSeconds;

    final newEndTime = _state.isRunning
        ? DateTime.now().add(Duration(seconds: newRemaining))
        : null;

    _callNativeStaticTimer('adjustTimer', {'deltaSeconds': deltaSeconds});

    if (newRemaining <= 0) {
      _ticker?.cancel();
      _updateState(_state.copyWith(
        remainingSeconds: 0,
        totalSeconds: newTotal,
        status: TimerStatus.completed,
        clearTargetEndTime: true,
      ));
      _onTimerCompleted();
    } else {
      _updateState(_state.copyWith(
        remainingSeconds: newRemaining,
        totalSeconds: newTotal,
        targetEndTime: newEndTime,
      ));
    }
  }

  static void applyNativeState(Map<String, dynamic> payload) {
    final rawStatus = payload['status'] as String? ?? 'Ready';
    final habitId = payload['habitId'] as String?;
    final habitTitle = payload['habitTitle'] as String?;
    final totalSeconds = (payload['totalSeconds'] as num?)?.toInt();
    final remainingSeconds = (payload['remainingSeconds'] as num?)?.toInt();

    final mapped = switch (rawStatus) {
      'Running' => TimerStatus.running,
      'Paused' => TimerStatus.paused,
      'Done' => TimerStatus.completed,
      _ => TimerStatus.idle,
    };

    if (mapped == TimerStatus.idle) {
      if (_state.focusModeActive || _state.isCompleted) {
        _ticker?.cancel();
        _updateState(const TimerState());
      }
      return;
    }

    _ticker?.cancel();

    final remaining = remainingSeconds ?? _state.remainingSeconds;
    final total = totalSeconds ?? _state.totalSeconds;
    final endTime = mapped == TimerStatus.running
        ? DateTime.now().add(Duration(seconds: remaining))
        : null;

    _updateState(TimerState(
      habitId: habitId ?? _state.habitId,
      habitTitle: habitTitle ?? _state.habitTitle,
      totalSeconds: total,
      remainingSeconds: remaining,
      status: mapped,
      targetEndTime: endTime,
    ));

    if (mapped == TimerStatus.running) {
      _startTicker();
    }
  }

  static void _callNativeStaticTimer(String method, [Map<String, dynamic>? args]) {
    try {
      const channel = MethodChannel('com.productivity.habits/focus_timer');
      channel.invokeMethod(method, args).catchError((_) => null);
    } catch (_) {}
  }

  static void setRemainingMinutes(int minutes) {
    final sec = (minutes * 60).clamp(60, 24 * 3600);
    final isRunning = _state.isRunning;
    final newEndTime =
        isRunning ? DateTime.now().add(Duration(seconds: sec)) : null;

    _updateState(_state.copyWith(
      remainingSeconds: sec,
      totalSeconds: sec,
      status: isRunning ? TimerStatus.running : TimerStatus.idle,
      targetEndTime: newEndTime,
    ));
  }

  static void complete() {
    _ticker?.cancel();
    _updateState(_state.copyWith(
      remainingSeconds: 0,
      status: TimerStatus.completed,
      clearTargetEndTime: true,
    ));
    _onTimerCompleted();
  }

  static void setDuration(String habitId, String habitTitle, double durationMinutes) {
    _ticker?.cancel();
    final sec = (durationMinutes * 60).toInt().clamp(60, 24 * 3600);
    _updateState(TimerState(
      habitId: habitId,
      habitTitle: habitTitle,
      totalSeconds: sec,
      remainingSeconds: sec,
      status: TimerStatus.idle,
    ));
  }

  static void recalculateOnResume() {
    if (_state.isRunning && _state.targetEndTime != null) {
      final now = DateTime.now();
      final diff = _state.targetEndTime!.difference(now).inSeconds;
      tick(diff);
    }
  }

  static void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.targetEndTime != null) {
        final diff = _state.targetEndTime!.difference(DateTime.now()).inSeconds;
        tick(diff);
      } else {
        tick(_state.remainingSeconds - 1);
      }
    });
  }

  static void _onTimerCompleted() {
    final habitId = _state.habitId;
    final totalSec = _state.totalSeconds;
    final totalMin = totalSec / 60.0;

    if (habitId != null && habitId.isNotEmpty && repository != null) {
      repository!.logCheckIn(
        habitId: habitId,
        date: DateTime.now(),
        completed: true,
        value: totalMin,
        durationSeconds: totalSec,
        note: 'Completed focus timer session (${totalMin.toInt()} mins)',
      );
    }

    try {
      HapticsHelper.performHeavyConfirmationHaptic();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}

// Riverpod provider for reactive UI subscription
final timerStateHolderProvider =
    StateNotifierProvider<TimerStateHolderNotifier, TimerState>((ref) {
  final repo = ref.watch(habitRepositoryProvider);
  TimerStateHolder.repository = repo;
  final notifier = TimerStateHolderNotifier(repo);
  return notifier;
});
