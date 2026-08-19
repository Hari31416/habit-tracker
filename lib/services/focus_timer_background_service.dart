import 'dart:async';
import 'package:flutter/services.dart';
import '../domain/repositories/habit_repository.dart';
import 'widget_sync_service.dart';

enum BackgroundTimerStatus {
  idle,
  running,
  paused,
  completed,
}

class BackgroundTimerState {
  final String? habitId;
  final String habitTitle;
  final int totalSeconds;
  final int remainingSeconds;
  final BackgroundTimerStatus status;

  const BackgroundTimerState({
    this.habitId,
    this.habitTitle = 'Focus Session',
    this.totalSeconds = 1500,
    this.remainingSeconds = 1500,
    this.status = BackgroundTimerStatus.idle,
  });

  bool get isRunning => status == BackgroundTimerStatus.running;
  bool get isPaused => status == BackgroundTimerStatus.paused;
  bool get isCompleted => status == BackgroundTimerStatus.completed;
  bool get isIdle => status == BackgroundTimerStatus.idle;

  double get progressFraction => totalSeconds > 0
      ? ((totalSeconds - remainingSeconds) / totalSeconds).clamp(0.0, 1.0)
      : 0.0;

  BackgroundTimerState copyWith({
    String? habitId,
    String? habitTitle,
    int? totalSeconds,
    int? remainingSeconds,
    BackgroundTimerStatus? status,
  }) {
    return BackgroundTimerState(
      habitId: habitId ?? this.habitId,
      habitTitle: habitTitle ?? this.habitTitle,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
    );
  }
}

class FocusTimerBackgroundService {
  final HabitRepository _repository;
  final WidgetSyncService? _widgetSyncService;

  final _stateController = StreamController<BackgroundTimerState>.broadcast();
  BackgroundTimerState _state = const BackgroundTimerState();
  Timer? _countdownTimer;

  FocusTimerBackgroundService(
    this._repository, [
    this._widgetSyncService,
  ]);

  BackgroundTimerState get currentState => _state;
  Stream<BackgroundTimerState> get stateStream => _stateController.stream;

  void start({
    required String habitId,
    required String habitTitle,
    required double durationMinutes,
  }) {
    _countdownTimer?.cancel();
    final totalSec = (durationMinutes * 60).round().clamp(60, 86400);

    _state = BackgroundTimerState(
      habitId: habitId,
      habitTitle: habitTitle,
      totalSeconds: totalSec,
      remainingSeconds: totalSec,
      status: BackgroundTimerStatus.running,
    );
    _stateController.add(_state);

    _callNativeTimer('startTimer', {
      'habitId': habitId,
      'habitTitle': habitTitle,
      'durationMinutes': durationMinutes,
    });

    _startTimerLoop();
    _syncWidget();
  }

  void pause() {
    _countdownTimer?.cancel();
    if (_state.isRunning) {
      _state = _state.copyWith(status: BackgroundTimerStatus.paused);
      _stateController.add(_state);
      _callNativeTimer('pauseTimer');
      _syncWidget();
    }
  }

  void resume() {
    if (_state.isPaused) {
      _state = _state.copyWith(status: BackgroundTimerStatus.running);
      _stateController.add(_state);
      _callNativeTimer('resumeTimer');
      _startTimerLoop();
      _syncWidget();
    }
  }

  void stop() {
    _countdownTimer?.cancel();
    _state = _state.copyWith(status: BackgroundTimerStatus.paused);
    _stateController.add(_state);
    _callNativeTimer('stopTimer');
    _syncWidget();
  }

  void reset() {
    _countdownTimer?.cancel();
    _state = _state.copyWith(
      remainingSeconds: _state.totalSeconds,
      status: BackgroundTimerStatus.idle,
    );
    _stateController.add(_state);
    _callNativeTimer('resetTimer');
    _syncWidget();
  }

  void adjustRemaining(int deltaSeconds) {
    final newRemaining =
        (_state.remainingSeconds + deltaSeconds).clamp(0, _state.totalSeconds);
    _state = _state.copyWith(remainingSeconds: newRemaining);
    _stateController.add(_state);
    _callNativeTimer('adjustTimer', {'deltaSeconds': deltaSeconds});
    _syncWidget();
  }

  void _callNativeTimer(String method, [Map<String, dynamic>? args]) {
    try {
      const channel = MethodChannel('app.phial.habits/focus_timer');
      channel.invokeMethod(method, args).catchError((_) => null);
    } catch (_) {}
  }

  void _syncWidget() {
    _widgetSyncService?.syncFocusTimerWidget(
      habitId: _state.habitId,
      habitTitle: _state.habitTitle,
      totalSeconds: _state.totalSeconds,
      remainingSeconds: _state.remainingSeconds,
      status: _state.status.name,
      progressFraction: _state.progressFraction,
    );
  }

  void _startTimerLoop() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.remainingSeconds <= 1) {
        timer.cancel();
        _onFinished();
      } else {
        _state = _state.copyWith(
          remainingSeconds: _state.remainingSeconds - 1,
        );
        _stateController.add(_state);
        if (_state.remainingSeconds % 5 == 0) {
          _syncWidget();
        }
      }
    });
  }

  Future<void> _onFinished() async {
    final habitId = _state.habitId;
    final totalSec = _state.totalSeconds;
    final totalMin = totalSec / 60.0;

    _state = _state.copyWith(
      remainingSeconds: 0,
      status: BackgroundTimerStatus.completed,
    );
    _stateController.add(_state);

    if (habitId != null && habitId.isNotEmpty) {
      await _repository.logCheckIn(
        habitId: habitId,
        date: DateTime.now(),
        completed: true,
        value: totalMin,
        durationSeconds: totalSec,
        note: 'Completed focus timer session (${totalMin.toInt()} mins)',
      );
    }

    await _widgetSyncService?.syncAllWidgets();
  }

  void dispose() {
    _countdownTimer?.cancel();
    _stateController.close();
  }
}
