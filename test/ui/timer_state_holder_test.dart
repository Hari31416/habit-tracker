import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/ui/detail/controllers/timer_state_holder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TimerStateHolder.stop();
  });

  test('start initializes timer state with running status', () {
    TimerStateHolder.start('habit_1', 'Focus Work', 25.0);

    final state = TimerStateHolder.timerState;
    expect(state.habitId, 'habit_1');
    expect(state.habitTitle, 'Focus Work');
    expect(state.totalSeconds, 25 * 60);
    expect(state.remainingSeconds, 25 * 60);
    expect(state.status, TimerStatus.running);
    expect(state.isRunning, isTrue);
  });

  test('pause and resume toggle status appropriately', () {
    TimerStateHolder.start('habit_1', 'Focus Work', 25.0);
    TimerStateHolder.pause();

    expect(TimerStateHolder.timerState.status, TimerStatus.paused);
    expect(TimerStateHolder.timerState.isPaused, isTrue);

    TimerStateHolder.resume();
    expect(TimerStateHolder.timerState.status, TimerStatus.running);
  });

  test('adjustRemaining adds and subtracts delta seconds', () {
    TimerStateHolder.start('habit_1', 'Focus Work', 25.0);
    TimerStateHolder.adjustRemaining(300); // +5m

    expect(TimerStateHolder.timerState.remainingSeconds, 30 * 60);

    TimerStateHolder.adjustRemaining(-600); // -10m
    expect(TimerStateHolder.timerState.remainingSeconds, 20 * 60);
  });

  test('tick updates remaining seconds and completes when zero', () {
    TimerStateHolder.start('habit_1', 'Focus Work', 10.0);
    TimerStateHolder.tick(50);

    expect(TimerStateHolder.timerState.remainingSeconds, 50);
    expect(TimerStateHolder.timerState.status, TimerStatus.running);

    TimerStateHolder.tick(0);
    expect(TimerStateHolder.timerState.remainingSeconds, 0);
    expect(TimerStateHolder.timerState.status, TimerStatus.completed);
    expect(TimerStateHolder.timerState.isCompleted, isTrue);
  });

  test('reset restores remaining seconds to total seconds and sets status to IDLE', () {
    TimerStateHolder.start('habit_1', 'Focus Work', 25.0);
    TimerStateHolder.tick(60);
    TimerStateHolder.reset();

    final state = TimerStateHolder.timerState;
    expect(state.remainingSeconds, 25 * 60);
    expect(state.status, TimerStatus.idle);
  });

  test('setDuration sets total and remaining seconds with IDLE status', () {
    TimerStateHolder.setDuration('habit_1', 'Focus Work', 5.0);

    final state = TimerStateHolder.timerState;
    expect(state.habitId, 'habit_1');
    expect(state.totalSeconds, 5 * 60);
    expect(state.remainingSeconds, 5 * 60);
    expect(state.status, TimerStatus.idle);
  });

  test('setRemainingMinutes updates duration and preserves IDLE status when not running', () {
    TimerStateHolder.setDuration('habit_1', 'Focus Work', 10.0);
    TimerStateHolder.setRemainingMinutes(15);

    final state = TimerStateHolder.timerState;
    expect(state.totalSeconds, 15 * 60);
    expect(state.remainingSeconds, 15 * 60);
    expect(state.status, TimerStatus.idle);
  });

  test('focusModeActive is true when running or paused and false otherwise', () {
    // IDLE state
    expect(TimerStateHolder.timerState.focusModeActive, isFalse);

    // RUNNING state
    TimerStateHolder.start('habit_1', 'Focus Work', 25.0);
    expect(TimerStateHolder.timerState.focusModeActive, isTrue);

    // PAUSED state
    TimerStateHolder.pause();
    expect(TimerStateHolder.timerState.focusModeActive, isTrue);

    // COMPLETED state
    TimerStateHolder.tick(0);
    expect(TimerStateHolder.timerState.focusModeActive, isFalse);

    // After stop
    TimerStateHolder.stop();
    expect(TimerStateHolder.timerState.focusModeActive, isFalse);
  });
}
