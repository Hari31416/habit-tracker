import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/dynamic_step_engine.dart';

void main() {
  test('getDynamicStepConfig_milliliters_returnsCorrectSteps', () {
    final large = DynamicStepEngine.getDynamicStepConfig(2000.0, 'ml');
    expect(large.primaryStep, 250.0);
    expect(large.quickAddValues, [250.0, 500.0, 1000.0]);

    final medium = DynamicStepEngine.getDynamicStepConfig(500.0, 'ml');
    expect(medium.primaryStep, 50.0);
    expect(medium.quickAddValues, [100.0, 250.0]);

    final small = DynamicStepEngine.getDynamicStepConfig(100.0, 'ml');
    expect(small.primaryStep, 10.0);
    expect(small.quickAddValues, [25.0, 50.0]);
  });

  test('getDynamicStepConfig_steps_returnsCorrectSteps', () {
    final large = DynamicStepEngine.getDynamicStepConfig(10000.0, 'steps');
    expect(large.primaryStep, 500.0);
    expect(large.quickAddValues, [1000.0, 2500.0, 5000.0]);

    final medium = DynamicStepEngine.getDynamicStepConfig(3000.0, 'steps');
    expect(medium.primaryStep, 200.0);
    expect(medium.quickAddValues, [500.0, 1000.0]);
  });

  test('getDynamicStepConfig_calories_returnsCorrectSteps', () {
    final large = DynamicStepEngine.getDynamicStepConfig(2000.0, 'kcal');
    expect(large.primaryStep, 100.0);
    expect(large.quickAddValues, [250.0, 500.0]);

    final small = DynamicStepEngine.getDynamicStepConfig(500.0, 'cal');
    expect(small.primaryStep, 50.0);
    expect(small.quickAddValues, [100.0, 200.0]);
  });

  test('getDynamicStepConfig_generalNumeric_scalesWithTarget', () {
    final small = DynamicStepEngine.getDynamicStepConfig(5.0, 'pages');
    expect(small.primaryStep, 1.0);
    expect(small.quickAddValues, [1.0, 2.0]);

    final mid = DynamicStepEngine.getDynamicStepConfig(100.0, 'pages');
    expect(mid.primaryStep, 5.0);
    expect(mid.quickAddValues, [10.0, 25.0]);

    final big = DynamicStepEngine.getDynamicStepConfig(500.0, 'words');
    expect(big.primaryStep, 10.0);
    expect(big.quickAddValues, [25.0, 50.0, 100.0]);
  });

  test('getDynamicTimerConfig_returnsCorrectSteps', () {
    final quick = DynamicStepEngine.getDynamicTimerConfig(15.0);
    expect(quick.primaryStep, 1.0);
    expect(quick.quickAddValues, [2.0, 5.0, 10.0]);

    final pomodoro = DynamicStepEngine.getDynamicTimerConfig(25.0);
    expect(pomodoro.primaryStep, 5.0);
    expect(pomodoro.quickAddValues, [5.0, 10.0, 15.0]);

    final longSession = DynamicStepEngine.getDynamicTimerConfig(90.0);
    expect(longSession.primaryStep, 15.0);
    expect(longSession.quickAddValues, [15.0, 30.0, 60.0]);
  });
}
