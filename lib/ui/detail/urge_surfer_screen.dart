import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ambient_sound_type.dart';
import '../common/color_utils.dart';
import '../common/haptics_helper.dart';
import 'controllers/ambient_audio_controller.dart';
import 'widgets/ambient_sound_bottom_sheet.dart';

enum BoxBreathingPhase {
  inhale,
  holdIn,
  exhale,
  holdOut;

  String get label {
    switch (this) {
      case BoxBreathingPhase.inhale:
        return 'Inhale Slowly';
      case BoxBreathingPhase.holdIn:
        return 'Hold Breath';
      case BoxBreathingPhase.exhale:
        return 'Exhale Smoothly';
      case BoxBreathingPhase.holdOut:
        return 'Hold Empty';
    }
  }

  String get instruction {
    switch (this) {
      case BoxBreathingPhase.inhale:
        return 'Breathe in deeply through your nose';
      case BoxBreathingPhase.holdIn:
        return 'Keep lungs full and relax your shoulders';
      case BoxBreathingPhase.exhale:
        return 'Release tension as air leaves your lungs';
      case BoxBreathingPhase.holdOut:
        return 'Stay still and centered in this calm pause';
    }
  }
}

class UrgeSurferScreen extends ConsumerStatefulWidget {
  final String habitId;
  final String? habitTitle;
  final String? habitColor;
  final VoidCallback onBack;

  const UrgeSurferScreen({
    super.key,
    required this.habitId,
    this.habitTitle,
    this.habitColor,
    required this.onBack,
  });

  @override
  ConsumerState<UrgeSurferScreen> createState() => _UrgeSurferScreenState();
}

class _UrgeSurferScreenState extends ConsumerState<UrgeSurferScreen>
    with SingleTickerProviderStateMixin {
  static const int totalSessionSeconds = 120; // 2 minutes
  static const int phaseSeconds = 4;

  late AnimationController _animController;
  Timer? _ticker;

  bool _isRunning = false;
  int _secondsRemaining = totalSessionSeconds;
  int _phaseSecondsRemaining = phaseSeconds;
  BoxBreathingPhase _currentPhase = BoxBreathingPhase.inhale;
  int _currentQuoteIndex = 0;

  final List<String> _mindfulQuotes = const [
    'Urges are like ocean waves — they rise, peak, and naturally fade away.',
    'Observe the craving with curiosity, without the need to react or judge.',
    'Take slow, deep breaths. This sensation is temporary and will pass.',
    'You are in control of your actions. Ride the wave to peaceful shore.',
    'Notice where you feel the urge in your body, and breathe into that space.',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: phaseSeconds),
    );
    _startSession();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isRunning = true;
      _secondsRemaining = totalSessionSeconds;
      _phaseSecondsRemaining = phaseSeconds;
      _currentPhase = BoxBreathingPhase.inhale;
    });

    _animController.forward(from: 0.0);
    _startTicker();
    _playAmbientIfConfigured();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_secondsRemaining <= 1) {
        _onSessionComplete();
        return;
      }

      setState(() {
        _secondsRemaining--;
        _phaseSecondsRemaining--;

        if (_phaseSecondsRemaining <= 0) {
          _advancePhase();
        }

        if (_secondsRemaining % 24 == 0) {
          _currentQuoteIndex =
              (_currentQuoteIndex + 1) % _mindfulQuotes.length;
        }
      });
    });
  }

  void _advancePhase() {
    HapticsHelper.selectionClick();
    _phaseSecondsRemaining = phaseSeconds;

    switch (_currentPhase) {
      case BoxBreathingPhase.inhale:
        _currentPhase = BoxBreathingPhase.holdIn;
        _animController.stop();
        break;
      case BoxBreathingPhase.holdIn:
        _currentPhase = BoxBreathingPhase.exhale;
        _animController.reverse(from: 1.0);
        break;
      case BoxBreathingPhase.exhale:
        _currentPhase = BoxBreathingPhase.holdOut;
        _animController.stop();
        break;
      case BoxBreathingPhase.holdOut:
        _currentPhase = BoxBreathingPhase.inhale;
        _animController.forward(from: 0.0);
        break;
    }
  }

  void _togglePauseResume() {
    setState(() {
      _isRunning = !_isRunning;
    });

    if (_isRunning) {
      _startTicker();
      if (_currentPhase == BoxBreathingPhase.inhale) {
        _animController.forward();
      } else if (_currentPhase == BoxBreathingPhase.exhale) {
        _animController.reverse();
      }
      _playAmbientIfConfigured();
    } else {
      _ticker?.cancel();
      _animController.stop();
      ref.read(ambientAudioControllerProvider.notifier).stopPlayback();
    }
  }

  void _playAmbientIfConfigured() {
    final audioState = ref.read(ambientAudioControllerProvider);
    if (audioState.selectedSound != AmbientSoundType.none) {
      ref
          .read(ambientAudioControllerProvider.notifier)
          .selectSound(audioState.selectedSound, isTimerRunning: true);
    }
  }

  void _onSessionComplete() async {
    _ticker?.cancel();
    _animController.stop();
    setState(() {
      _isRunning = false;
      _secondsRemaining = 0;
      _phaseSecondsRemaining = 0;
    });

    HapticsHelper.celebrate();
    ref.read(ambientAudioControllerProvider.notifier).stopPlayback();

    if (mounted) {
      _showCompletionSheet();
    }
  }

  void _showCompletionSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.surfing,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Urge Surfed Successfully!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You stayed centered for 2 minutes and let the craving crest and dissipate.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  widget.onBack();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Return to Habit'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.habitColor != null
        ? ColorUtils.parseHexColor(widget.habitColor!)
        : theme.colorScheme.primary;

    final progress =
        1.0 - (_secondsRemaining / totalSessionSeconds).clamp(0.0, 1.0);
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(ambientAudioControllerProvider.notifier).stopPlayback();
            widget.onBack();
          },
        ),
        title: Text(
          widget.habitTitle != null
              ? 'Urge Surfer • ${widget.habitTitle}'
              : 'Urge Surfer',
        ),
        actions: [
          IconButton(
            key: const Key('btn_urge_surfer_ambient'),
            icon: const Icon(Icons.music_note),
            tooltip: 'Ambient Sound',
            onPressed: () => AmbientSoundBottomSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header description
              Text(
                'Box Breathing Technique (4-4-4-4)',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cravings usually peak within 2 to 3 minutes before naturally fading.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Animated Breathing Sphere
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  double scale;
                  switch (_currentPhase) {
                    case BoxBreathingPhase.inhale:
                      scale = 0.65 + (0.35 * _animController.value);
                      break;
                    case BoxBreathingPhase.holdIn:
                      scale = 1.0;
                      break;
                    case BoxBreathingPhase.exhale:
                      scale = 0.65 + (0.35 * _animController.value);
                      break;
                    case BoxBreathingPhase.holdOut:
                      scale = 0.65;
                      break;
                  }

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.35),
                            accentColor.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.2),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.2),
                            border: Border.all(
                              color: accentColor,
                              width: 3,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_phaseSecondsRemaining',
                                style: theme.textTheme.displayMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'sec',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Phase Name & Instruction
              Text(
                _currentPhase.label,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _currentPhase.instruction,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Total Session Progress Bar & Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Session Remaining',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),

              const SizedBox(height: 16),

              // Mindful quote card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.spa_outlined,
                      size: 20,
                      color: accentColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _mindfulQuotes[_currentQuoteIndex],
                          key: ValueKey<int>(_currentQuoteIndex),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const Key('btn_urge_surfer_restart'),
                    onPressed: _startSession,
                    icon: const Icon(Icons.replay),
                    label: const Text('Restart'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    key: const Key('btn_urge_surfer_pause_resume'),
                    onPressed: _togglePauseResume,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'Pause' : 'Resume'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
