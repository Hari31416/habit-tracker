import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/analytics/controllers/analytics_controller.dart';

import 'habit_detail_controller_test.dart' show FakeHabitRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final habit1 = Habit(
    id: 'analytics_habit_1',
    title: 'Morning Meditation',
    color: '#8B5CF6',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.boolean,
    createdAt: now,
    updatedAt: now,
  );

  final habit2 = Habit(
    id: 'analytics_habit_2',
    title: 'Drink Water',
    color: '#06B6D4',
    frequencyType: HabitFrequencyType.daily,
    targetType: HabitTargetType.numeric,
    targetValue: 2000.0,
    unit: 'ml',
    createdAt: now,
    updatedAt: now,
  );

  late FakeHabitRepository fakeRepository;
  late AnalyticsController controller;

  setUp(() {
    fakeRepository = FakeHabitRepository(
      initialHabits: [habit1, habit2],
    );
    controller = AnalyticsController(fakeRepository);
  });

  tearDown(() {
    controller.dispose();
  });

  test('initial state loads top KPIs and trend data points', () async {
    await Future.delayed(const Duration(milliseconds: 50));
    final state = controller.state;

    expect(state.isLoading, isFalse);
    expect(state.scheduledTodayCount, 2);
    expect(state.completedTodayCount, 0);
    expect(state.trendRange, TrendRange.sevenDays);
    expect(state.trendDataPoints.length, 7);
    expect(state.heatmapMonth.year, today.year);
    expect(state.heatmapMonth.month, today.month);
    expect(state.heatmapData.isNotEmpty, isTrue);
  });

  test('switching trend range updates data points count', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    controller.setTrendRange(TrendRange.thirtyDays);
    await Future.delayed(const Duration(milliseconds: 50));

    final state = controller.state;
    expect(state.trendRange, TrendRange.thirtyDays);
    expect(state.trendDataPoints.length, 30);
  });

  test('heatmap month navigation updates month state', () async {
    final currentMonth = DateTime(today.year, today.month, 1);

    controller.previousHeatmapMonth();
    expect(
      controller.heatmapMonth,
      DateTime(currentMonth.year, currentMonth.month - 1, 1),
    );

    controller.nextHeatmapMonth();
    expect(controller.heatmapMonth, currentMonth);
  });

  test(
      'completed habits on today updates completedTodayCount and consistency',
      () async {
    await fakeRepository.toggleBooleanCheckIn('analytics_habit_1', today);
    await Future.delayed(const Duration(milliseconds: 50));

    final state = controller.state;
    expect(state.completedTodayCount, 1);
    expect(state.scheduledTodayCount, 2);
  });
}
