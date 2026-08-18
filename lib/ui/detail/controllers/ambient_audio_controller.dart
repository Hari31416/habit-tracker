import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/preferences/theme_preferences.dart';
import '../../../domain/models/ambient_sound_type.dart';
import '../../../services/ambient_audio_service.dart';
import 'timer_state_holder.dart';

class AmbientAudioState {
  final AmbientSoundType selectedSound;
  final double volume;
  final bool isPlaying;

  const AmbientAudioState({
    this.selectedSound = AmbientSoundType.none,
    this.volume = 0.7,
    this.isPlaying = false,
  });

  AmbientAudioState copyWith({
    AmbientSoundType? selectedSound,
    double? volume,
    bool? isPlaying,
  }) {
    return AmbientAudioState(
      selectedSound: selectedSound ?? this.selectedSound,
      volume: volume ?? this.volume,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

class AmbientAudioNotifier extends StateNotifier<AmbientAudioState> {
  final AmbientAudioService _audioService;
  final ThemePreferences _prefs;

  AmbientAudioNotifier({
    required AmbientAudioService audioService,
    required ThemePreferences prefs,
  })  : _audioService = audioService,
        _prefs = prefs,
        super(
          AmbientAudioState(
            selectedSound: AmbientSoundType.fromString(prefs.loadAmbientSoundType()),
            volume: prefs.loadAmbientSoundVolume(),
            isPlaying: false,
          ),
        );

  Future<void> selectSound(AmbientSoundType sound, {bool isTimerRunning = false}) async {
    state = state.copyWith(selectedSound: sound);
    await _prefs.setAmbientSoundType(sound.name);

    if (sound == AmbientSoundType.none) {
      await _audioService.stop();
      state = state.copyWith(isPlaying: false);
    } else if (isTimerRunning) {
      await _audioService.playSound(sound, volume: state.volume);
      state = state.copyWith(isPlaying: _audioService.isPlaying);
    }
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(volume: clamped);
    await _prefs.setAmbientSoundVolume(clamped);
    await _audioService.setVolume(clamped);
  }

  Future<void> onTimerStatusChanged(TimerStatus status) async {
    if (state.selectedSound == AmbientSoundType.none) {
      if (state.isPlaying) {
        await _audioService.stop();
        state = state.copyWith(isPlaying: false);
      }
      return;
    }

    switch (status) {
      case TimerStatus.running:
        if (!_audioService.isPlaying) {
          await _audioService.playSound(state.selectedSound, volume: state.volume);
          state = state.copyWith(isPlaying: _audioService.isPlaying);
        }
        break;
      case TimerStatus.paused:
        if (_audioService.isPlaying) {
          await _audioService.pause();
          state = state.copyWith(isPlaying: false);
        }
        break;
      case TimerStatus.completed:
      case TimerStatus.idle:
        await _audioService.stop();
        state = state.copyWith(isPlaying: false);
        break;
    }
  }

  Future<void> stopPlayback() async {
    await _audioService.stop();
    state = state.copyWith(isPlaying: false);
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}

final ambientAudioServiceProvider = Provider<AmbientAudioService>((ref) {
  final service = AmbientAudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final ambientAudioControllerProvider =
    StateNotifierProvider<AmbientAudioNotifier, AmbientAudioState>((ref) {
  final service = ref.watch(ambientAudioServiceProvider);
  final prefs = ref.watch(themePreferencesProvider);
  return AmbientAudioNotifier(
    audioService: service,
    prefs: prefs,
  );
});
