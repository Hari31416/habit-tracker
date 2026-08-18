import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/habit_frequency_type.dart';
import '../../../domain/models/habit_target_type.dart';
import '../common/color_utils.dart';
import '../common/habit_icon_registry.dart';
import '../common/haptics_helper.dart';
import '../theme/app_colors.dart';
import 'controllers/habit_form_controller.dart';

class HabitFormBottomSheet extends ConsumerStatefulWidget {
  final String? habitIdToEdit;
  final VoidCallback onDismiss;

  const HabitFormBottomSheet({
    super.key,
    this.habitIdToEdit,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    String? habitIdToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitFormBottomSheet(
        habitIdToEdit: habitIdToEdit,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  ConsumerState<HabitFormBottomSheet> createState() =>
      _HabitFormBottomSheetState();
}

class _HabitFormBottomSheetState extends ConsumerState<HabitFormBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _motivationController;
  late final TextEditingController _targetValueController;
  late final TextEditingController _unitController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _motivationController = TextEditingController();
    _targetValueController = TextEditingController();
    _unitController = TextEditingController();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(habitFormControllerProvider.notifier);
      if (widget.habitIdToEdit != null) {
        controller.loadHabit(widget.habitIdToEdit!).then((_) {
          _syncControllersWithState();
        });
      } else {
        controller.resetForm();
        _syncControllersWithState();
      }
    });
  }

  void _syncControllersWithState() {
    final state = ref.read(habitFormControllerProvider);
    _titleController.text = state.title;
    _descriptionController.text = state.description;
    _motivationController.text = state.motivationNotes;
    _targetValueController.text = state.targetValue;
    _unitController.text = state.unit;
    _startTimeController.text = state.timeWindowStart;
    _endTimeController.text = state.timeWindowEnd;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _motivationController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      final timeStr = '$hourStr:$minuteStr';
      ref.read(habitFormControllerProvider.notifier).addReminderTime(timeStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(habitFormControllerProvider);
    final controller = ref.read(habitFormControllerProvider.notifier);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categories = categoriesAsync.value ?? const [];

    final accentColor = ColorUtils.parseHexColor(formState.color);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sheet Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formState.isEditMode ? 'Edit Habit' : 'New Habit',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    formState.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: formState.pinned
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                  tooltip: 'Pin habit',
                  onPressed: () {
                    HapticsHelper.performLightHaptic();
                    controller.onTogglePinned();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Basic Info Section
            TextField(
              controller: _titleController,
              onChanged: controller.onTitleChange,
              decoration: InputDecoration(
                labelText: 'Habit Title *',
                errorText: formState.titleError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _descriptionController,
              onChanged: controller.onDescriptionChange,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _motivationController,
              onChanged: controller.onMotivationChange,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Motivation / Why this habit? (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Selection
            Text(
              'Category',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = formState.categoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat.name),
                      onSelected: (_) {
                        HapticsHelper.performLightHaptic();
                        controller.onCategoryChange(
                          isSelected ? null : cat.id,
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Color Palette (8 presets)
            Text(
              'Accent Color',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: kHabitPresetColors.map((hex) {
                final color = ColorUtils.parseHexColor(hex);
                final isSelected =
                    formState.color.toLowerCase() == hex.toLowerCase();

                return InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticsHelper.performLightHaptic();
                    controller.onColorChange(hex);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Icon Picker (20 icons)
            Text(
              'Icon',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: HabitIconRegistry.availableIcons.map((item) {
                  final isSelected =
                      formState.icon.toLowerCase() == item.key.toLowerCase();
                  final currentColor = accentColor;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: isSelected
                          ? currentColor.withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: isSelected
                            ? BorderSide(color: currentColor, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticsHelper.performLightHaptic();
                          controller.onIconChange(item.key);
                        },
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Center(
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: isSelected
                                  ? currentColor
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Target Type Selector
            Text(
              'Target Type',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<HabitTargetType>(
              segments: const [
                ButtonSegment(
                  value: HabitTargetType.boolean,
                  label: Text('Yes / No'),
                ),
                ButtonSegment(
                  value: HabitTargetType.numeric,
                  label: Text('Numeric'),
                ),
                ButtonSegment(
                  value: HabitTargetType.timer,
                  label: Text('Timer'),
                ),
              ],
              selected: {formState.targetType},
              onSelectionChanged: (selection) {
                HapticsHelper.performLightHaptic();
                final chosen = selection.first;
                controller.onTargetTypeChange(chosen);
                _targetValueController.text =
                    ref.read(habitFormControllerProvider).targetValue;
                _unitController.text =
                    ref.read(habitFormControllerProvider).unit;
              },
            ),
            const SizedBox(height: 12),

            // Target Type Specific Controls
            if (formState.targetType == HabitTargetType.numeric) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetValueController,
                      onChanged: controller.onTargetValueChange,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Target Goal *',
                        errorText: formState.targetValueError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _unitController,
                      onChanged: controller.onUnitChange,
                      decoration: InputDecoration(
                        labelText: 'Unit (e.g. ml, steps)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Unit presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'glasses',
                    'steps',
                    'pages',
                    'ml',
                    'km',
                    'cal',
                  ].map((u) {
                    final isSelected = formState.unit.toLowerCase() == u;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(u),
                        onSelected: (_) {
                          HapticsHelper.performLightHaptic();
                          controller.onUnitChange(u);
                          _unitController.text = u;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else if (formState.targetType == HabitTargetType.timer) ...[
              TextField(
                controller: _targetValueController,
                onChanged: controller.onTargetValueChange,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target Duration (Minutes) *',
                  errorText: formState.targetValueError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Duration presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['15', '25', '30', '45', '60'].map((mins) {
                    final isSelected = formState.targetValue == mins;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text('$mins mins'),
                        onSelected: (_) {
                          HapticsHelper.performLightHaptic();
                          controller.onTargetValueChange(mins);
                          _targetValueController.text = mins;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 3. Frequency Rules
            Text(
              'Frequency',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HabitFrequencyType.values.map((freq) {
                String label;
                switch (freq) {
                  case HabitFrequencyType.daily:
                    label = 'Everyday';
                    break;
                  case HabitFrequencyType.customDays:
                    label = 'Specific Days';
                    break;
                  case HabitFrequencyType.weekly:
                    label = 'Times Per Week';
                    break;
                  case HabitFrequencyType.subdayInterval:
                    label = 'Interval (Hours)';
                    break;
                  case HabitFrequencyType.timesPerDay:
                    label = 'Times Per Day';
                    break;
                }

                return FilterChip(
                  selected: formState.frequencyType == freq,
                  label: Text(label),
                  onSelected: (_) {
                    HapticsHelper.performLightHaptic();
                    controller.onFrequencyTypeChange(freq);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            if (formState.frequencyType == HabitFrequencyType.customDays) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final dayLetter = entry.value;
                  final isSelected =
                      formState.targetDaysOfWeek.contains(index);

                  return InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticsHelper.performLightHaptic();
                      controller.toggleDayOfWeek(index);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? accentColor
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          dayLetter,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else if (formState.frequencyType == HabitFrequencyType.weekly) ...[
              Text(
                'Target: ${formState.targetCountPerWeek} days / week',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: formState.targetCountPerWeek.toDouble(),
                min: 1,
                max: 6,
                divisions: 5,
                onChanged: (val) {
                  controller.onTargetCountPerWeekChange(val.toInt());
                },
              ),
            ] else if (formState.frequencyType ==
                HabitFrequencyType.subdayInterval) ...[
              Text(
                'Interval: Every ${formState.intervalHours} hours',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: formState.intervalHours.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                onChanged: (val) {
                  controller.onIntervalHoursChange(val.toInt());
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startTimeController,
                      onChanged: (v) => controller.onTimeWindowChange(
                        v,
                        formState.timeWindowEnd,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _endTimeController,
                      onChanged: (v) => controller.onTimeWindowChange(
                        formState.timeWindowStart,
                        v,
                      ),
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (formState.frequencyType ==
                HabitFrequencyType.timesPerDay) ...[
              Text(
                'Times per day: ${formState.timesPerDay}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: formState.timesPerDay.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                onChanged: (val) {
                  controller.onTimesPerDayChange(val.toInt());
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startTimeController,
                      onChanged: (v) => controller.onTimeWindowChange(
                        v,
                        formState.timeWindowEnd,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _endTimeController,
                      onChanged: (v) => controller.onTimeWindowChange(
                        formState.timeWindowStart,
                        v,
                      ),
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // 4. Reminders Section
            Text(
              'Reminders',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Quick reminder presets + Custom button
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...[
                    ('Morning', '08:00'),
                    ('Midday', '12:30'),
                    ('Evening', '18:00'),
                    ('Night', '21:30'),
                  ].map((preset) {
                    final label = preset.$1;
                    final time = preset.$2;
                    final isAdded = formState.reminderTimes.contains(time);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isAdded,
                        label: Text('$label ($time)'),
                        onSelected: (_) {
                          HapticsHelper.performLightHaptic();
                          if (isAdded) {
                            controller.removeReminderTime(time);
                          } else {
                            controller.addReminderTime(time);
                          }
                        },
                      ),
                    );
                  }),
                  ActionChip(
                    avatar: Icon(
                      Icons.add,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      'Custom',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    onPressed: () {
                      HapticsHelper.performLightHaptic();
                      _pickCustomTime();
                    },
                  ),
                ],
              ),
            ),

            // Reminders List
            if (formState.reminderTimes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Column(
                children: formState.reminderTimes.map((time) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.alarm,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                time,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            iconSize: 16,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              HapticsHelper.performLightHaptic();
                              controller.removeReminderTime(time);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 28),

            // 5. Footer Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: widget.onDismiss,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: formState.isSaving
                        ? null
                        : () async {
                            HapticsHelper.performLightHaptic();
                            final success = await controller.saveHabit();
                            if (success) {
                              widget.onDismiss();
                            }
                          },
                    child: formState.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            formState.isEditMode
                                ? 'Update Habit'
                                : 'Create Habit',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
