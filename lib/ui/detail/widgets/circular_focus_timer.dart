import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/haptics_helper.dart';
import '../controllers/timer_state_holder.dart';

class CircularFocusTimer extends ConsumerStatefulWidget {
  final String habitId;
  final String habitTitle;
  final double defaultDurationMinutes;
  final double remainingUnloggedMinutes;
  final Color accentColor;
  final VoidCallback onFocusScreenClick;

  const CircularFocusTimer({
    super.key,
    required this.habitId,
    required this.habitTitle,
    required this.defaultDurationMinutes,
    this.remainingUnloggedMinutes = 25.0,
    required this.accentColor,
    required this.onFocusScreenClick,
  });

  @override
  ConsumerState<CircularFocusTimer> createState() => _CircularFocusTimerState();
}

class _CircularFocusTimerState extends ConsumerState<CircularFocusTimer> {
  void _showEditMinutesDialog(int currentMinutes, bool isRunningOrPaused) {
    final textController =
        TextEditingController(text: currentMinutes.toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Set Timer Minutes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Minutes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final parsed = int.tryParse(textController.text) ?? 25;
                final timerNotifier =
                    ref.read(timerStateHolderProvider.notifier);
                if (isRunningOrPaused) {
                  timerNotifier.setRemainingMinutes(parsed);
                } else {
                  timerNotifier.setDuration(
                    widget.habitId,
                    widget.habitTitle,
                    parsed.toDouble(),
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timerState = ref.watch(timerStateHolderProvider);
    final timerNotifier = ref.read(timerStateHolderProvider.notifier);

    final isRunningOrPausedForThisHabit = timerState.habitId == widget.habitId &&
        (timerState.status == TimerStatus.running ||
            timerState.status == TimerStatus.paused);
    final isCompletedForThisHabit = timerState.habitId == widget.habitId &&
        timerState.status == TimerStatus.completed;

    final defaultDurationSec =
        (widget.defaultDurationMinutes * 60).toInt().clamp(60, 24 * 3600);

    final remainingSec = isRunningOrPausedForThisHabit
        ? timerState.remainingSeconds
        : isCompletedForThisHabit
            ? 0
            : (timerState.habitId == widget.habitId &&
                    timerState.status == TimerStatus.idle)
                ? timerState.remainingSeconds
                : defaultDurationSec;

    final totalSec = (isRunningOrPausedForThisHabit ||
            isCompletedForThisHabit ||
            (timerState.habitId == widget.habitId &&
                timerState.status == TimerStatus.idle))
        ? timerState.totalSeconds
        : defaultDurationSec;

    final status = isRunningOrPausedForThisHabit
        ? timerState.status
        : isCompletedForThisHabit
            ? TimerStatus.completed
            : TimerStatus.idle;

    final progress = totalSec > 0
        ? ((totalSec - remainingSec) / totalSec).clamp(0.0, 1.0)
        : 0.0;

    final minutes = remainingSec ~/ 60;
    final seconds = remainingSec % 60;
    final timeFormatted =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final statusLabel = switch (status) {
      TimerStatus.running => 'Focusing...',
      TimerStatus.paused => 'Paused',
      TimerStatus.completed => 'Completed!',
      TimerStatus.idle => 'Ready',
    };

    final currentGoalMins = (totalSec / 60).toInt();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Focus Timer',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Enter Fullscreen Focus Screen
                  IconButton(
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.center_focus_strong,
                      color: isRunningOrPausedForThisHabit
                          ? widget.accentColor
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                    ),
                    tooltip: 'Enter focus mode',
                    onPressed: isRunningOrPausedForThisHabit
                        ? () {
                            HapticsHelper.performLightHaptic();
                            widget.onFocusScreenClick();
                          }
                        : null,
                  ),
                  const SizedBox(width: 4),
                  // Edit Timer Duration
                  IconButton(
                    iconSize: 18,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.edit,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Edit timer duration',
                    onPressed: () {
                      HapticsHelper.performLightHaptic();
                      _showEditMinutesDialog(
                        currentGoalMins,
                        isRunningOrPausedForThisHabit,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Large Circular Countdown Canvas
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(190, 190),
                  painter: _FocusTimerPainter(
                    progress: progress,
                    trackColor: theme.colorScheme.surfaceContainerHighest,
                    accentColor: widget.accentColor,
                    strokeWidth: 10,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeFormatted,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: status == TimerStatus.running
                            ? widget.accentColor
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Primary Controls: Reset & Play/Pause Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset Button (48x48)
              Material(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticsHelper.performLightHaptic();
                    timerNotifier.stop();
                  },
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.refresh, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Play / Pause Pill Button (48h x 160w)
              SizedBox(
                width: 160,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: Icon(
                    status == TimerStatus.running
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 20,
                  ),
                  label: Text(
                    status == TimerStatus.running ? 'Pause' : 'Start',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    HapticsHelper.performLightHaptic();
                    switch (status) {
                      case TimerStatus.running:
                        timerNotifier.pause();
                        break;
                      case TimerStatus.paused:
                        timerNotifier.resume();
                        break;
                      case TimerStatus.completed:
                      case TimerStatus.idle:
                        final durationMins = totalSec > 0
                            ? totalSec / 60.0
                            : widget.defaultDurationMinutes;
                        timerNotifier.start(
                          widget.habitId,
                          widget.habitTitle,
                          durationMins,
                        );
                        break;
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Adjustment Chips: -10m, -5m, [Goal], +5m, +10m
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [-10, -5, 0, 5, 10].map((delta) {
                final isGoal = delta == 0;
                final label = isGoal
                    ? '${currentGoalMins}m Goal'
                    : (delta > 0 ? '+$delta m' : '$delta m');

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: isGoal,
                    label: Text(
                      label,
                      style: TextStyle(
                        fontWeight:
                            isGoal ? FontWeight.bold : FontWeight.w500,
                        color: isGoal
                            ? widget.accentColor
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    onSelected: (_) {
                      if (!isGoal) {
                        HapticsHelper.performLightHaptic();
                        final newMins = max(1, (totalSec ~/ 60) + delta);
                        if (isRunningOrPausedForThisHabit) {
                          timerNotifier.setRemainingMinutes(newMins);
                        } else {
                          timerNotifier.setDuration(
                            widget.habitId,
                            widget.habitTitle,
                            newMins.toDouble(),
                          );
                        }
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusTimerPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color accentColor;
  final double strokeWidth;

  _FocusTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.accentColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Foreground sweep arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        progress * 2 * pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FocusTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
