import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../di/providers.dart';
import '../../../../domain/models/habit_routine.dart';
import '../../common/haptics_helper.dart';
import '../dialogs/routine_builder_sheet.dart';
import 'routine_chain_card.dart';

class RoutineSection extends ConsumerStatefulWidget {
  final ValueChanged<HabitRoutine> onStartRoutinePlayer;
  final DateTime selectedDate;

  const RoutineSection({
    super.key,
    required this.onStartRoutinePlayer,
    required this.selectedDate,
  });

  @override
  ConsumerState<RoutineSection> createState() => _RoutineSectionState();
}

class _RoutineSectionState extends ConsumerState<RoutineSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routinesAsync = ref.watch(activeRoutinesStreamProvider);
    final habitsAsync = ref.watch(activeHabitsStreamProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final logsAsync = ref.watch(allLogsStreamProvider);

    final routines = routinesAsync.value ?? const [];
    final habits = habitsAsync.value ?? const [];
    final allLogs = logsAsync.value ?? const [];
    final todayLogs = allLogs.where((l) => l.date == dateStr).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with expand/collapse and "+ New Stack" button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  HapticsHelper.selectionClick();
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_right_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        identifier: 'routine_section_header',
                        child: Text(
                          'Routines & Stacks',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      if (routines.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${routines.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Semantics(
                identifier: 'btn_new_stack',
                button: true,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    HapticsHelper.selectionClick();
                    RoutineBuilderSheet.show(context);
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'New Stack',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Section Content
        if (_isExpanded) ...[
          if (routines.isEmpty)
            _buildEmptyPromptCard(context)
          else
            Column(
              children: [
                for (final routine in routines)
                  RoutineChainCard(
                    routine: routine,
                    allHabits: habits,
                    todayLogs: todayLogs,
                    onStartRoutine: widget.onStartRoutinePlayer,
                    onEditRoutine: (r) {
                      RoutineBuilderSheet.show(context, routineToEdit: r);
                    },
                    onDeleteRoutine: (r) => _confirmDelete(context, r),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _buildEmptyPromptCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.link_rounded,
              color: theme.colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build Your First Routine Chain',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stack habits into seamless morning or evening flows and earn bonus XP.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            iconSize: 18,
            onPressed: () {
              HapticsHelper.selectionClick();
              RoutineBuilderSheet.show(context);
            },
            icon: const Icon(Icons.add),
            tooltip: 'Create Routine Stack',
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, HabitRoutine routine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Routine Stack?'),
        content: Text(
          'Are you sure you want to delete "${routine.title}"? Your individual habits will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(routineRepositoryProvider).deleteRoutine(routine.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
