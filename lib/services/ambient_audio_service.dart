import 'package:audioplayers/audioplayers.dart';
import '../domain/models/ambient_sound_type.dart';

class AmbientAudioService {
  final AudioPlayer? _player;
  AmbientSoundType _currentSound = AmbientSoundType.none;
  double _currentVolume = 0.7;
  bool _isPlaying = false;

  AmbientAudioService({AudioPlayer? player, bool autoInit = true})
      : _player = player ?? (autoInit ? AudioPlayer() : null) {
    if (autoInit && _player != null) {
      _init();
    }
  }

  void _init() {
    try {
      _player?.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}
  }

  AmbientSoundType get currentSound => _currentSound;
  double get currentVolume => _currentVolume;
  bool get isPlaying => _isPlaying;

  Future<void> playSound(AmbientSoundType sound, {double? volume}) async {
    if (volume != null) {
      _currentVolume = volume.clamp(0.0, 1.0);
    }
    _currentSound = sound;

    if (sound == AmbientSoundType.none || sound.assetPath == null) {
      await stop();
      return;
    }

    try {
      await _player?.stop();
      await _player?.setVolume(_currentVolume);
      await _player?.setReleaseMode(ReleaseMode.loop);
      final player = _player;
      final assetPath = sound.assetPath;
      if (player != null && assetPath != null) {
        await player.play(AssetSource(assetPath));
      }
      _isPlaying = true;
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> pause() async {
    if (_isPlaying) {
      try {
        await _player?.pause();
        _isPlaying = false;
      } catch (_) {}
    }
  }

  Future<void> resume() async {
    if (!_isPlaying &&
        _currentSound != AmbientSoundType.none &&
        _currentSound.assetPath != null) {
      try {
        await _player?.resume();
        _isPlaying = true;
      } catch (_) {}
    }
  }

  Future<void> setVolume(double volume) async {
    _currentVolume = volume.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(_currentVolume);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
      _isPlaying = false;
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
      _isPlaying = false;
    } catch (_) {}
  }
}
