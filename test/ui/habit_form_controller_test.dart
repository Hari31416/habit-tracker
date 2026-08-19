import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/models/habit.dart';
import 'package:habit_tracker/domain/models/habit_frequency_type.dart';
import 'package:habit_tracker/domain/models/habit_target_type.dart';
import 'package:habit_tracker/ui/form/controllers/habit_form_controller.dart';
import 'daily_tracker_controller_test.dart';

void main() {
  group('HabitFormController', () {
    late FakeHabitRepository repository;
    late HabitFormController controller;

    setUp(() {
      repository = FakeHabitRepository();
      controller = HabitFormController(repository);
    });

    test('Initial state has default values', () {
      final state = controller.state;
      expect(state.title, isEmpty);
      expect(state.targetType, HabitTargetType.boolean);
      expect(state.frequencyType, HabitFrequencyType.daily);
      expect(state.targetDaysOfWeek, {0, 1, 2, 3, 4, 5, 6});
      expect(state.reminderTimes, isEmpty);
      expect(state.pinned, isFalse);
      expect(state.promptReflection, isFalse);
    });

    test('Field updates update state and clear error flags', () {
      controller.onTitleChange('Morning Run');
      expect(controller.state.title, 'Morning Run');
      expect(controller.state.titleError, isNull);

      controller.onDescriptionChange('5km run');
      expect(controller.state.description, '5km run');

      controller.onMotivationChange('Cardio health');
      expect(controller.state.motivationNotes, 'Cardio health');

      controller.onColorChange('#3B82F6');
      expect(controller.state.color, '#3B82F6');

      controller.onIconChange('run');
      expect(controller.state.icon, 'run');

      controller.onTogglePinned();
      expect(controller.state.pinned, isTrue);

      controller.onTogglePromptReflection(true);
      expect(controller.state.promptReflection, isTrue);
    });

    test('Target type switches apply sensible defaults', () {
      controller.onTargetTypeChange(HabitTargetType.numeric);
      expect(controller.state.targetType, HabitTargetType.numeric);
      expect(controller.state.targetValue, '8');
      expect(controller.state.unit, 'glasses');

      controller.onTargetTypeChange(HabitTargetType.timer);
      expect(controller.state.targetType, HabitTargetType.timer);
      expect(controller.state.targetValue, '25');
      expect(controller.state.unit, 'mins');
    });

    test('Custom days toggling preserves at least one day', () {
      controller.onFrequencyTypeChange(HabitFrequencyType.customDays);
      controller.toggleDayOfWeek(0); // removes Sun
      expect(controller.state.targetDaysOfWeek.contains(0), isFalse);

      // Remove all until only 1 remains
      for (int i = 1; i <= 5; i++) {
        controller.toggleDayOfWeek(i);
      }
      expect(controller.state.targetDaysOfWeek.length, 1);
      expect(controller.state.targetDaysOfWeek.contains(6), isTrue);

      // Attempting to remove the last day (Sat = 6) is ignored
      controller.toggleDayOfWeek(6);
      expect(controller.state.targetDaysOfWeek.length, 1);
      expect(controller.state.targetDaysOfWeek.contains(6), isTrue);
    });

    test('Reminder management adds sorted, ignores duplicate, and removes', () {
      controller.addReminderTime('18:00');
      controller.addReminderTime('08:00');
      controller.addReminderTime('12:30');
      controller.addReminderTime('08:00'); // duplicate

      expect(controller.state.reminderTimes, ['08:00', '12:30', '18:00']);

      controller.removeReminderTime('12:30');
      expect(controller.state.reminderTimes, ['08:00', '18:00']);
    });

    test('Validation fails on blank title and invalid numeric target', () async {
      final success1 = await controller.saveHabit();
      expect(success1, isFalse);
      expect(controller.state.titleError, 'Title is required');

      controller.onTitleChange('Drink Water');
      controller.onTargetTypeChange(HabitTargetType.numeric);
      controller.onTargetValueChange('abc');

      final success2 = await controller.saveHabit();
      expect(success2, isFalse);
      expect(controller.state.targetValueError, 'Enter a valid positive number');
    });

    test('Save habit successfully upserts new habit into repository', () async {
      controller.onTitleChange('Read Book');
      controller.onTargetTypeChange(HabitTargetType.numeric);
      controller.onTargetValueChange('20');
      controller.onUnitChange('pages');
      controller.onTogglePromptReflection(true);

      final success = await controller.saveHabit();
      expect(success, isTrue);

      final habits = await repository.getAllActiveHabitsOnce();
      expect(habits.length, 1);
      expect(habits.first.title, 'Read Book');
      expect(habits.first.targetValue, 20.0);
      expect(habits.first.unit, 'pages');
      expect(habits.first.promptReflection, isTrue);
    });

    test('loadHabit populates state in edit mode', () async {
      final existing = Habit(
        id: 'habit-edit-1',
        title: 'Meditation',
        description: 'Mindfulness',
        color: '#8B5CF6',
        targetType: HabitTargetType.timer,
        targetValue: 15,
        unit: 'mins',
        frequencyType: HabitFrequencyType.daily,
        pinned: true,
        promptReflection: true,
        reminderTimes: const ['07:30'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.upsertHabit(existing);

      await controller.loadHabit('habit-edit-1');

      final state = controller.state;
      expect(state.habitId, 'habit-edit-1');
      expect(state.isEditMode, isTrue);
      expect(state.title, 'Meditation');
      expect(state.description, 'Mindfulness');
      expect(state.targetValue, '15');
      expect(state.pinned, isTrue);
      expect(state.promptReflection, isTrue);
      expect(state.reminderTimes, ['07:30']);
    });
  });
}
