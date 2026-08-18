import 'package:flutter/material.dart';

enum AmbientSoundType {
  none,
  rain,
  waves,
  campfire,
  forest,
  stream,
  cafe,
  wind,
  whiteNoise;

  String get displayName => switch (this) {
        AmbientSoundType.none => 'Off',
        AmbientSoundType.rain => 'Rain',
        AmbientSoundType.waves => 'Waves',
        AmbientSoundType.campfire => 'Campfire',
        AmbientSoundType.forest => 'Forest Birds',
        AmbientSoundType.stream => 'Stream',
        AmbientSoundType.cafe => 'Cafe',
        AmbientSoundType.wind => 'Wind',
        AmbientSoundType.whiteNoise => 'White Noise',
      };

  String? get assetPath => switch (this) {
        AmbientSoundType.none => null,
        AmbientSoundType.rain => 'audio/rain.mp3',
        AmbientSoundType.waves => 'audio/waves.mp3',
        AmbientSoundType.campfire => 'audio/campfire.mp3',
        AmbientSoundType.forest => 'audio/forest.mp3',
        AmbientSoundType.stream => 'audio/stream.mp3',
        AmbientSoundType.cafe => 'audio/cafe.mp3',
        AmbientSoundType.wind => 'audio/wind.mp3',
        AmbientSoundType.whiteNoise => 'audio/white_noise.mp3',
      };

  IconData get icon => switch (this) {
        AmbientSoundType.none => Icons.volume_off,
        AmbientSoundType.rain => Icons.water_drop,
        AmbientSoundType.waves => Icons.waves,
        AmbientSoundType.campfire => Icons.local_fire_department,
        AmbientSoundType.forest => Icons.forest,
        AmbientSoundType.stream => Icons.water,
        AmbientSoundType.cafe => Icons.coffee,
        AmbientSoundType.wind => Icons.air,
        AmbientSoundType.whiteNoise => Icons.graphic_eq,
      };

  static AmbientSoundType fromString(String? val) {
    if (val == null) return AmbientSoundType.none;
    return AmbientSoundType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => AmbientSoundType.none,
    );
  }
}
