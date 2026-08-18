import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/preferences/theme_preferences.dart';
import '../common/haptics_helper.dart';
import 'controllers/timer_state_holder.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  final String habitId;
  final VoidCallback onBack;

  const FocusTimerScreen({
    super.key,
    required this.habitId,
    required this.onBack,
  });

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> {
  @override
  void initState() {
    super.initState();
    // Hide system status & navigation bars for distraction-free mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore standard edge-to-edge UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timerState = ref.watch(timerStateHolderProvider);
    final timerNotifier = ref.read(timerStateHolderProvider.notifier);

    final isActiveForHabit = timerState.habitId == widget.habitId;
    final status = isActiveForHabit ? timerState.status : TimerStatus.idle;
    final remainingSec = isActiveForHabit
        ? timerState.remainingSeconds
        : timerState.totalSeconds;
    final totalSec = timerState.totalSeconds > 0 ? timerState.totalSeconds : 25 * 60;

    final progress =
        totalSec > 0 ? ((totalSec - remainingSec) / totalSec).clamp(0.0, 1.0) : 0.0;

    final minutes = remainingSec ~/ 60;
    final seconds = remainingSec % 60;
    final timeFormatted =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final accentColor = theme.colorScheme.primary;

    final statusLabel = switch (status) {
      TimerStatus.running => 'Focusing...',
      TimerStatus.paused => 'Paused',
      TimerStatus.completed => 'Completed!',
      TimerStatus.idle => 'Ready',
    };

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Close button (top-left)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                iconSize: 28,
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Exit focus mode',
                onPressed: () {
                  HapticsHelper.performLightHaptic();
                  widget.onBack();
                },
              ),
            ),

            // Main content centered
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Habit title
                    Text(
                      timerState.habitTitle.isNotEmpty
                          ? timerState.habitTitle
                          : 'Focus Timer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Large circular timer (280x280)
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(260, 260),
                            painter: _FocusTimerScreenPainter(
                              progress: progress,
                              trackColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              accentColor: accentColor,
                              strokeWidth: 12,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timeFormatted,
                                style:
                                    theme.textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              Text(
                                statusLabel,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: status == TimerStatus.running
                                      ? accentColor
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Controls: Reset + Play/Pause
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset (56x56)
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
                              width: 56,
                              height: 56,
                              child: Icon(Icons.refresh, size: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Play / Pause (56h x 180w)
                        SizedBox(
                          width: 180,
                          height: 56,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            icon: Icon(
                              status == TimerStatus.running
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 24,
                            ),
                            label: Text(
                              status == TimerStatus.running
                                  ? 'Pause'
                                  : 'Start',
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
                                      : 25.0;
                                  timerNotifier.start(
                                    widget.habitId,
                                    timerState.habitTitle,
                                    durationMins,
                                  );
                                  break;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusTimerScreenPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color accentColor;
  final double strokeWidth;

  _FocusTimerScreenPainter({
    required this.progress,
    required this.trackColor,
    required this.accentColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
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
  bool shouldRepaint(covariant _FocusTimerScreenPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
