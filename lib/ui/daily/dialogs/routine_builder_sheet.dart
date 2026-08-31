import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../di/providers.dart';
import '../../../domain/models/habit.dart';
import '../../../domain/models/habit_routine.dart';
import '../../../domain/models/time_window.dart';
import '../../common/color_utils.dart';
import '../../common/habit_icon_registry.dart';
import '../../common/haptics_helper.dart';

class RoutineBuilderSheet extends ConsumerStatefulWidget {
  final HabitRoutine? routineToEdit;

  const RoutineBuilderSheet({
    super.key,
    this.routineToEdit,
  });

  static Future<void> show(BuildContext context, {HabitRoutine? routineToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoutineBuilderSheet(routineToEdit: routineToEdit),
    );
  }

  @override
  ConsumerState<RoutineBuilderSheet> createState() => _RoutineBuilderSheetState();
}

class _RoutineBuilderSheetState extends ConsumerState<RoutineBuilderSheet> {
  static const List<String> _palette = [
    '#3B82F6', // Blue
    '#8B5CF6', // Purple
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#6366F1', // Indigo
  ];

  static const List<String> _presetIcons = [
    'sun',
    'moon',
    'zap',
    'link',
    'activity',
    'brain',
    'book-open',
    'droplet',
    'dumbbell',
    'coffee',
    'target',
    'clock',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedColor;
  late String _selectedIcon;
  late int _bonusXp;
  String _timePreset = 'morning'; // 'morning', 'afternoon', 'evening', 'custom', 'none'
  TimeWindow? _customTimeWindow;
  final List<String> _orderedHabitIds = [];

  @override
  void initState() {
    super.initState();
    final r = widget.routineToEdit;
    _titleController = TextEditingController(text: r?.title ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _selectedColor = r?.color ?? _palette[0];
    _selectedIcon = r?.icon ?? 'sun';
    _bonusXp = r?.bonusXp ?? 30;

    if (r != null) {
      _orderedHabitIds.addAll(r.habitIds);
      _customTimeWindow = r.targetTimeWindow;
      if (r.targetTimeWindow != null) {
        if (r.targetTimeWindow!.startTime == '06:00' && r.targetTimeWindow!.endTime == '10:00') {
          _timePreset = 'morning';
        } else if (r.targetTimeWindow!.startTime == '12:00' && r.targetTimeWindow!.endTime == '16:00') {
          _timePreset = 'afternoon';
        } else if (r.targetTimeWindow!.startTime == '18:00' && r.targetTimeWindow!.endTime == '22:00') {
          _timePreset = 'evening';
        } else {
          _timePreset = 'custom';
        }
      } else {
        _timePreset = 'none';
      }
    } else {
      _customTimeWindow = const TimeWindow(startTime: '06:00', endTime: '10:00');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  TimeWindow? _resolveEffectiveTimeWindow() {
    switch (_timePreset) {
      case 'morning':
        return const TimeWindow(startTime: '06:00', endTime: '10:00');
      case 'afternoon':
        return const TimeWindow(startTime: '12:00', endTime: '16:00');
      case 'evening':
        return const TimeWindow(startTime: '18:00', endTime: '22:00');
      case 'custom':
        return _customTimeWindow;
      case 'none':
      default:
        return null;
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a routine stack title')),
      );
      return;
    }

    if (_orderedHabitIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one habit to this routine chain')),
      );
      return;
    }

    final now = DateTime.now().toUtc();
    final routineId = widget.routineToEdit?.id ?? const Uuid().v4();

    final routine = HabitRoutine(
      id: routineId,
      title: title,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      color: _selectedColor,
      icon: _selectedIcon,
      targetTimeWindow: _resolveEffectiveTimeWindow(),
      habitIds: _orderedHabitIds,
      bonusXp: _bonusXp,
      isDeleted: false,
      createdAt: widget.routineToEdit?.createdAt ?? now,
      updatedAt: now,
    );

    HapticsHelper.selectionClick();
    await ref.read(routineRepositoryProvider).upsertRoutine(routine);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.routineToEdit != null;
    final allHabits = ref.watch(activeHabitsStreamProvider).value ?? const [];
    final habitMap = {for (final h in allHabits) h.id: h};

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Habit Stack' : 'Create Habit Stack',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Input
              Semantics(
                identifier: 'routine_title_field',
                child: TextField(
                  controller: _titleController,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Stack Title *',
                    hintText: 'e.g. Morning Momentum, Evening Wind-Down',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description Input
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Stack purpose or motivation...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Color Selector
              Text(
                'Color Theme',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _palette.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (ctx, idx) {
                    final hex = _palette[idx];
                    final color = ColorUtils.fromHex(hex);
                    final isSelected = _selectedColor.toUpperCase() == hex.toUpperCase();
                    return GestureDetector(
                      onTap: () {
                        HapticsHelper.selectionClick();
                        setState(() => _selectedColor = hex);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.onSurface : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Icon Selector
              Text(
                'Stack Icon',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetIcons.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final iconKey = _presetIcons[idx];
                    final isSelected = _selectedIcon == iconKey;
                    return ChoiceChip(
                      selected: isSelected,
                      onSelected: (_) {
                        HapticsHelper.selectionClick();
                        setState(() => _selectedIcon = iconKey);
                      },
                      avatar: Icon(
                        HabitIconRegistry.getIcon(iconKey),
                        size: 18,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(iconKey),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Time Window Selector
              Text(
                'Target Time Window',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Morning (06:00-10:00)'),
                    selected: _timePreset == 'morning',
                    onSelected: (_) => setState(() => _timePreset = 'morning'),
                  ),
                  ChoiceChip(
                    label: const Text('Afternoon (12:00-16:00)'),
                    selected: _timePreset == 'afternoon',
                    onSelected: (_) => setState(() => _timePreset = 'afternoon'),
                  ),
                  ChoiceChip(
                    label: const Text('Evening (18:00-22:00)'),
                    selected: _timePreset == 'evening',
                    onSelected: (_) => setState(() => _timePreset = 'evening'),
                  ),
                  ChoiceChip(
                    label: const Text('Anytime'),
                    selected: _timePreset == 'none',
                    onSelected: (_) => setState(() => _timePreset = 'none'),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Bonus XP Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completion Bonus XP',
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Awarded on finishing the full sequence in order',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 18,
                          onPressed: _bonusXp > 10
                              ? () => setState(() => _bonusXp = (_bonusXp - 5).clamp(10, 100))
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          '+$_bonusXp XP',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                        IconButton(
                          iconSize: 18,
                          onPressed: _bonusXp < 100
                              ? () => setState(() => _bonusXp = (_bonusXp + 5).clamp(10, 100))
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Sequential Chain Builder Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sequential Habit Chain',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Semantics(
                    identifier: 'btn_add_routine_step',
                    button: true,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => _showAddHabitPicker(context, allHabits),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Add Step'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (_orderedHabitIds.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.playlist_add_rounded,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No habits added yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap "Add Step" to link habits into a sequential chain.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _orderedHabitIds.length,
                  // ignore: deprecated_member_use
                  onReorder: (oldIndex, newIndex) {
                    HapticsHelper.selectionClick();
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _orderedHabitIds.removeAt(oldIndex);
                      _orderedHabitIds.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (ctx, index) {
                    final habitId = _orderedHabitIds[index];
                    final habit = habitMap[habitId];
                    final habitColor = habit != null ? ColorUtils.fromHex(habit.color) : Colors.grey;

                    return Material(
                      key: ValueKey(habitId),
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      child: Semantics(
                        identifier: 'stack_step_${index + 1}',
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    Icons.drag_handle_rounded,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: habitColor,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              habit?.title ?? 'Unknown Habit',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              index == 0
                                  ? 'Trigger habit (First step)'
                                  : 'After Step $index, perform this',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            trailing: IconButton(
                              iconSize: 18,
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                HapticsHelper.selectionClick();
                                setState(() {
                                  _orderedHabitIds.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      identifier: 'btn_save_routine',
                      button: true,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _save,
                        child: Text(isEditing ? 'Save Changes' : 'Create Stack'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddHabitPicker(BuildContext context, List<Habit> allHabits) {
    final available = allHabits.where((h) => !_orderedHabitIds.contains(h.id)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Habit to Stack',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (available.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('All active habits have already been added to this stack.'),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: available.length,
                      itemBuilder: (context, idx) {
                        final habit = available[idx];
                        final habitColor = ColorUtils.fromHex(habit.color);

                        return Semantics(
                          identifier: 'picker_habit_${habit.id}',
                          button: true,
                          child: ListTile(
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: habitColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                HabitIconRegistry.getIcon(habit.icon),
                                color: habitColor,
                                size: 18,
                              ),
                            ),
                            title: Text(habit.title),
                            subtitle: Text(habit.frequencyType.name),
                            onTap: () {
                              HapticsHelper.selectionClick();
                              setState(() {
                                _orderedHabitIds.add(habit.id);
                              });
                              Navigator.of(ctx).pop();
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
