import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/notification_service.dart';
import '../common/color_utils.dart';
import '../common/haptics_helper.dart';
import 'controllers/habit_form_controller.dart';
import 'widgets/habit_form_sections.dart';

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
  late final TextEditingController _miniTargetController;
  late final TextEditingController _eliteTargetController;
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
    _miniTargetController = TextEditingController();
    _eliteTargetController = TextEditingController();
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
    _miniTargetController.text = state.miniTargetValue;
    _eliteTargetController.text = state.eliteTargetValue;
    _unitController.text = state.unit;
    _startTimeController.text = state.timeWindowStart;
    _endTimeController.text = state.timeWindowEnd;
  }

  void _syncControllersToForm(HabitFormController controller) {
    // Accessibility automation (e.g. Maestro inputText) can set TextField
    // values without firing onChanged; sync controllers before save/validate.
    controller.onTitleChange(_titleController.text);
    controller.onDescriptionChange(_descriptionController.text);
    controller.onMotivationChange(_motivationController.text);
    controller.onTargetValueChange(_targetValueController.text);
    controller.onMiniTargetValueChange(_miniTargetController.text);
    controller.onEliteTargetValueChange(_eliteTargetController.text);
    controller.onUnitChange(_unitController.text);
    controller.onTimeWindowChange(
      _startTimeController.text,
      _endTimeController.text,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _motivationController.dispose();
    _targetValueController.dispose();
    _miniTargetController.dispose();
    _eliteTargetController.dispose();
    _unitController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _handleReminderAdd(String timeStr) async {
    final hasPerm = await NotificationService.hasPermission();
    if (!hasPerm) {
      final granted = await NotificationService.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Habit reminders require notification access. Exact alarms are optional for punctuality. Please enable notifications in system settings.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }
    ref.read(habitFormControllerProvider.notifier).addReminderTime(timeStr);
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
      await _handleReminderAdd(timeStr);
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
            Semantics(
              identifier: 'habit_form_title',
              child: TextField(
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
            const SizedBox(height: 20),

            // Goal Type Mode (Positive vs Sobriety)
            HabitModeSection(
              formState: formState,
              controller: controller,
              accentColor: accentColor,
            ),
            const SizedBox(height: 20),

            // Category & Appearance Section
            HabitAppearanceSection(
              formState: formState,
              controller: controller,
              categories: categories,
              accentColor: accentColor,
            ),
            const SizedBox(height: 20),

            if (!formState.isNegative) ...[
              // Target Type Section & Elastic Goals
              HabitTargetSection(
                formState: formState,
                controller: controller,
                targetValueController: _targetValueController,
                miniTargetController: _miniTargetController,
                eliteTargetController: _eliteTargetController,
                unitController: _unitController,
              ),
              const SizedBox(height: 20),

              // Frequency Rules Section
              HabitFrequencySection(
                formState: formState,
                controller: controller,
                accentColor: accentColor,
                startTimeController: _startTimeController,
                endTimeController: _endTimeController,
              ),
              const SizedBox(height: 20),
            ],

            // Reminders Section
            HabitRemindersSection(
              formState: formState,
              controller: controller,
              onAddReminder: _handleReminderAdd,
              onPickCustomTime: _pickCustomTime,
            ),
            const SizedBox(height: 20),

            if (!formState.isNegative) ...[
              // Health & Reflection Section
              HabitHealthAndReflectionSection(
                formState: formState,
                controller: controller,
                onSyncControllers: _syncControllersWithState,
              ),
              const SizedBox(height: 28),
            ] else ...[
              const SizedBox(height: 8),
            ],

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
                  child: Semantics(
                    identifier: 'habit_form_save',
                    label: formState.isEditMode ? 'Update Habit' : 'Create Habit',
                    button: true,
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
                              _syncControllersToForm(controller);
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
