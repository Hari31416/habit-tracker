import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/services/focus_timer_background_service.dart';

import '../ui/habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final habit = Habit(
    id: 'timer_h1',
    title: 'Deep Focus',
    color: '#8B5CF6',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.timer,
    targetValue: 25.0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  late FakeHabitRepository fakeRepo;
  late FocusTimerBackgroundService service;

  setUp(() {
    fakeRepo = FakeHabitRepository(initialHabits: [habit]);
    service = FocusTimerBackgroundService(fakeRepo);
  });

  tearDown(() {
    service.dispose();
  });

  test('start, pause, resume, adjust, and stop update background timer state',
      () {
    service.start(
      habitId: habit.id,
      habitTitle: habit.title,
      durationMinutes: 25.0,
    );

    expect(service.currentState.isRunning, isTrue);
    expect(service.currentState.totalSeconds, 1500);
    expect(service.currentState.remainingSeconds, 1500);

    service.pause();
    expect(service.currentState.isPaused, isTrue);

    service.resume();
    expect(service.currentState.isRunning, isTrue);

    service.adjustRemaining(-300); // -5 mins
    expect(service.currentState.remainingSeconds, 1200);

    service.stop();
    expect(service.currentState.isIdle, isTrue);
  });
}
