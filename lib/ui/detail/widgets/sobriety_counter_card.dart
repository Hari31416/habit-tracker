import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/habit.dart';
import '../../common/color_utils.dart';
import '../../common/haptics_helper.dart';

class SobrietyMilestone {
  final int days;
  final String label;

  const SobrietyMilestone(this.days, this.label);
}

class SobrietyCounterCard extends StatefulWidget {
  final Habit habit;
  final VoidCallback onLaunchUrgeSurfer;
  final Future<void> Function(String? triggerNote) onResetSobriety;

  const SobrietyCounterCard({
    super.key,
    required this.habit,
    required this.onLaunchUrgeSurfer,
    required this.onResetSobriety,
  });

  static const List<SobrietyMilestone> milestones = [
    SobrietyMilestone(1, '24 Hours'),
    SobrietyMilestone(3, '3 Days'),
    SobrietyMilestone(7, '1 Week'),
    SobrietyMilestone(14, '2 Weeks'),
    SobrietyMilestone(30, '1 Month'),
    SobrietyMilestone(60, '2 Months'),
    SobrietyMilestone(90, '90 Days'),
    SobrietyMilestone(180, '6 Months'),
    SobrietyMilestone(365, '1 Year'),
  ];

  @override
  State<SobrietyCounterCard> createState() => _SobrietyCounterCardState();
}

class _SobrietyCounterCardState extends State<SobrietyCounterCard> {
  late Timer _ticker;
  late DateTime _cleanSince;

  @override
  void initState() {
    super.initState();
    _cleanSince = widget.habit.cleanSince ?? widget.habit.createdAt;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant SobrietyCounterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.habit.cleanSince != widget.habit.cleanSince ||
        oldWidget.habit.createdAt != widget.habit.createdAt) {
      _cleanSince = widget.habit.cleanSince ?? widget.habit.createdAt;
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _showResetConfirmDialog(BuildContext context) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text(
            'Reset Sobriety Clock?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Relapses are learning moments, not failures. Be kind to yourself and restart your clean counter today.',
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('field_sobriety_reset_note'),
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'What triggered this slip? (Optional)',
                  hintText: 'e.g. Stress, social event, fatigue...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('btn_confirm_reset_sobriety'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                HapticsHelper.mediumImpact();
                await widget.onResetSobriety(
                  noteController.text.trim().isNotEmpty
                      ? noteController.text.trim()
                      : null,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('Reset Clock'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitColor = ColorUtils.parseHexColor(widget.habit.color);

    final now = DateTime.now();
    final elapsed =
        now.isAfter(_cleanSince) ? now.difference(_cleanSince) : Duration.zero;

    final days = elapsed.inDays;
    final hours = elapsed.inHours % 24;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;

    // Determine current and next milestones
    SobrietyMilestone? nextMilestone;
    SobrietyMilestone? currentMilestone;
    for (final m in SobrietyCounterCard.milestones) {
      if (days >= m.days) {
        currentMilestone = m;
      } else {
        nextMilestone ??= m;
      }
    }

    final prevDays = currentMilestone?.days ?? 0;
    final targetDays = nextMilestone?.days ?? 365;
    final milestoneProgress = ((days - prevDays) / (targetDays - prevDays))
        .clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Title + Clean Since
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: habitColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sobriety Counter',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Since ${DateFormat('MMM d, yyyy').format(_cleanSince)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Live Time Blocks
            Row(
              children: [
                _buildTimeUnit(
                  context,
                  '$days',
                  'DAYS',
                  habitColor,
                  isPrimary: true,
                ),
                const SizedBox(width: 8),
                _buildTimeUnit(
                  context,
                  hours.toString().padLeft(2, '0'),
                  'HOURS',
                  habitColor,
                ),
                const SizedBox(width: 8),
                _buildTimeUnit(
                  context,
                  minutes.toString().padLeft(2, '0'),
                  'MINS',
                  habitColor,
                ),
                const SizedBox(width: 8),
                _buildTimeUnit(
                  context,
                  seconds.toString().padLeft(2, '0'),
                  'SECS',
                  habitColor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Milestone Bar
            if (nextMilestone != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next Milestone: ${nextMilestone.label}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '$days of ${nextMilestone.days} days (${(milestoneProgress * 100).toInt()}%)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: habitColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: milestoneProgress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(habitColor),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons: Urge Surfer + Reset
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    key: const Key('btn_launch_urge_surfer'),
                    onPressed: widget.onLaunchUrgeSurfer,
                    icon: const Icon(Icons.surfing, size: 18),
                    label: const Text('Urge Surfer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: habitColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    key: const Key('btn_open_reset_sobriety'),
                    onPressed: () => _showResetConfirmDialog(context),
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

  Widget _buildTimeUnit(
    BuildContext context,
    String value,
    String label,
    Color accentColor, {
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary
              ? accentColor.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? accentColor.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPrimary ? accentColor : theme.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                letterSpacing: 0.8,
                color: isPrimary
                    ? accentColor
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
