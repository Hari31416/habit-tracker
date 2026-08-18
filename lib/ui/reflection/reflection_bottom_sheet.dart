import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../di/providers.dart';
import '../../domain/models/habit.dart';
import '../common/color_utils.dart';
import '../common/habit_icon_registry.dart';
import '../common/haptics_helper.dart';

class MoodOption {
  final String key;
  final String label;
  final IconData icon;

  const MoodOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

const List<MoodOption> kDefaultMoodOptions = [
  MoodOption(key: 'energized', label: 'Energized', icon: Icons.bolt),
  MoodOption(key: 'happy', label: 'Happy', icon: Icons.sentiment_very_satisfied),
  MoodOption(key: 'calm', label: 'Calm', icon: Icons.spa),
  MoodOption(key: 'focused', label: 'Focused', icon: Icons.center_focus_strong),
  MoodOption(key: 'tired', label: 'Tired', icon: Icons.bedtime),
  MoodOption(key: 'stressed', label: 'Stressed', icon: Icons.sentiment_dissatisfied),
];

class ReflectionBottomSheet extends ConsumerStatefulWidget {
  final Habit habit;
  final DateTime date;
  final int? initialEnergyLevel;
  final String? initialMood;
  final String? initialNote;
  final ValueChanged<({int? energyLevel, String? mood, String? note})>? onSaved;

  const ReflectionBottomSheet({
    super.key,
    required this.habit,
    required this.date,
    this.initialEnergyLevel,
    this.initialMood,
    this.initialNote,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required Habit habit,
    required DateTime date,
    int? initialEnergyLevel,
    String? initialMood,
    String? initialNote,
    ValueChanged<({int? energyLevel, String? mood, String? note})>? onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReflectionBottomSheet(
        habit: habit,
        date: date,
        initialEnergyLevel: initialEnergyLevel,
        initialMood: initialMood,
        initialNote: initialNote,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<ReflectionBottomSheet> createState() =>
      _ReflectionBottomSheetState();
}

class _ReflectionBottomSheetState extends ConsumerState<ReflectionBottomSheet> {
  int? _selectedEnergyLevel;
  String? _selectedMood;
  late final TextEditingController _noteController;

  final List<String> _energyLabels = ['Low', 'Fair', 'Good', 'High', 'Peak'];

  @override
  void initState() {
    super.initState();
    _selectedEnergyLevel = widget.initialEnergyLevel;
    _selectedMood = widget.initialMood;
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveReflection() async {
    final energy = _selectedEnergyLevel;
    final mood = _selectedMood;
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    final repo = ref.read(habitRepositoryProvider);
    await repo.updateReflection(
      habitId: widget.habit.id,
      date: widget.date,
      energyLevel: energy,
      mood: mood,
      note: note,
    );

    widget.onSaved?.call((energyLevel: energy, mood: mood, note: note));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = ColorUtils.parseHexColor(widget.habit.color);
    final iconData = HabitIconRegistry.getIcon(widget.habit.icon);
    final dateStr = DateFormat('EEEE, MMM d').format(widget.date);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 20 + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Habit Title & Completed Status
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-In Reflection',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.habit.title} • $dateStr',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Skip',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Energy Rating (1-5 Scale)
            Text(
              'Energy Level',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final level = index + 1;
                final isSelected = _selectedEnergyLevel == level;
                final label = _energyLabels[index];

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticsHelper.performLightHaptic();
                        setState(() {
                          _selectedEnergyLevel = isSelected ? null : level;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.18)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? accentColor
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bolt,
                              size: 20,
                              color: isSelected
                                  ? accentColor
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$level',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? accentColor
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: isSelected
                                    ? accentColor
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // 2. Mood Selection
            Text(
              'Mood Tag',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kDefaultMoodOptions.map((mood) {
                final isSelected = _selectedMood == mood.key;
                return ChoiceChip(
                  avatar: Icon(
                    mood.icon,
                    size: 16,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  label: Text(mood.label),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  onSelected: (selected) {
                    HapticsHelper.performLightHaptic();
                    setState(() {
                      _selectedMood = selected ? mood.key : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 3. Short 1-Line Micro-Note
            Text(
              'Micro-Note',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 120,
              decoration: InputDecoration(
                hintText: 'Quick reflection or context...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticsHelper.performHeavyConfirmationHaptic();
                      _saveReflection();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Reflection',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}
