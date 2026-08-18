import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/preferences/theme_preferences.dart';
import 'package:habit_tracker/domain/models/ambient_sound_type.dart';
import 'package:habit_tracker/services/ambient_audio_service.dart';
import 'package:habit_tracker/ui/detail/controllers/ambient_audio_controller.dart';
import 'package:habit_tracker/ui/detail/controllers/timer_state_holder.dart';
import 'package:habit_tracker/ui/detail/widgets/ambient_sound_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAmbientAudioService extends AmbientAudioService {
  AmbientSoundType lastPlayedSound = AmbientSoundType.none;
  double lastSetVolume = 0.7;
  bool isPaused = false;
  bool isStopped = false;

  FakeAmbientAudioService() : super(autoInit: false);

  @override
  bool get isPlaying =>
      lastPlayedSound != AmbientSoundType.none && !isPaused && !isStopped;

  @override
  Future<void> playSound(AmbientSoundType sound, {double? volume}) async {
    lastPlayedSound = sound;
    if (volume != null) lastSetVolume = volume;
    isPaused = false;
    isStopped = false;
  }

  @override
  Future<void> pause() async {
    isPaused = true;
  }

  @override
  Future<void> resume() async {
    isPaused = false;
    isStopped = false;
  }

  @override
  Future<void> setVolume(double volume) async {
    lastSetVolume = volume;
  }

  @override
  Future<void> stop() async {
    isStopped = true;
    lastPlayedSound = AmbientSoundType.none;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AmbientSoundType tests', () {
    test('fromString parses correctly with fallback', () {
      expect(AmbientSoundType.fromString('rain'), AmbientSoundType.rain);
      expect(AmbientSoundType.fromString('waves'), AmbientSoundType.waves);
      expect(AmbientSoundType.fromString('forest'), AmbientSoundType.forest);
      expect(AmbientSoundType.fromString('campfire'), AmbientSoundType.campfire);
      expect(AmbientSoundType.fromString('unknown_value'), AmbientSoundType.none);
      expect(AmbientSoundType.fromString(null), AmbientSoundType.none);
    });

    test('metadata properties return non-empty values', () {
      for (final sound in AmbientSoundType.values) {
        expect(sound.displayName.isNotEmpty, isTrue);
        expect(sound.icon, isNotNull);
        if (sound != AmbientSoundType.none) {
          expect(sound.assetPath, isNotNull);
          expect(sound.assetPath!.startsWith('audio/'), isTrue);
        } else {
          expect(sound.assetPath, isNull);
        }
      }
    });
  });

  group('AmbientAudioPreferences tests', () {
    test('loads default values and persists updates', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themePrefs = ThemePreferences(prefs);

      expect(themePrefs.loadAmbientSoundType(), 'none');
      expect(themePrefs.loadAmbientSoundVolume(), 0.7);

      await themePrefs.setAmbientSoundType('rain');
      await themePrefs.setAmbientSoundVolume(0.85);

      expect(themePrefs.loadAmbientSoundType(), 'rain');
      expect(themePrefs.loadAmbientSoundVolume(), 0.85);
    });
  });

  group('AmbientAudioNotifier tests', () {
    late FakeAmbientAudioService fakeService;
    late ThemePreferences themePrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        ThemePreferences.keyAmbientSoundType: 'rain',
        ThemePreferences.keyAmbientSoundVolume: 0.75,
      });
      final prefs = await SharedPreferences.getInstance();
      themePrefs = ThemePreferences(prefs);
      fakeService = FakeAmbientAudioService();
    });

    test('initializes state from preferences', () {
      final notifier = AmbientAudioNotifier(
        audioService: fakeService,
        prefs: themePrefs,
      );

      expect(notifier.state.selectedSound, AmbientSoundType.rain);
      expect(notifier.state.volume, 0.75);
      expect(notifier.state.isPlaying, isFalse);
    });

    test('selectSound updates state and preferences', () async {
      final notifier = AmbientAudioNotifier(
        audioService: fakeService,
        prefs: themePrefs,
      );

      await notifier.selectSound(AmbientSoundType.waves, isTimerRunning: false);
      expect(notifier.state.selectedSound, AmbientSoundType.waves);
      expect(themePrefs.loadAmbientSoundType(), 'waves');
      expect(fakeService.isPlaying, isFalse);

      // Select sound while timer is running
      await notifier.selectSound(AmbientSoundType.campfire, isTimerRunning: true);
      expect(notifier.state.selectedSound, AmbientSoundType.campfire);
      expect(fakeService.lastPlayedSound, AmbientSoundType.campfire);
      expect(notifier.state.isPlaying, isTrue);

      // Selecting none stops playback
      await notifier.selectSound(AmbientSoundType.none, isTimerRunning: true);
      expect(notifier.state.selectedSound, AmbientSoundType.none);
      expect(notifier.state.isPlaying, isFalse);
      expect(fakeService.isStopped, isTrue);
    });

    test('setVolume updates volume across notifier, preferences, and service', () async {
      final notifier = AmbientAudioNotifier(
        audioService: fakeService,
        prefs: themePrefs,
      );

      await notifier.setVolume(0.4);
      expect(notifier.state.volume, 0.4);
      expect(themePrefs.loadAmbientSoundVolume(), 0.4);
      expect(fakeService.lastSetVolume, 0.4);
    });

    test('onTimerStatusChanged synchronizes audio playback', () async {
      final notifier = AmbientAudioNotifier(
        audioService: fakeService,
        prefs: themePrefs,
      );

      // Timer starts running -> audio plays
      await notifier.onTimerStatusChanged(TimerStatus.running);
      expect(fakeService.lastPlayedSound, AmbientSoundType.rain);
      expect(notifier.state.isPlaying, isTrue);

      // Timer pauses -> audio pauses
      await notifier.onTimerStatusChanged(TimerStatus.paused);
      expect(fakeService.isPaused, isTrue);
      expect(notifier.state.isPlaying, isFalse);

      // Timer completed -> audio stops
      await notifier.onTimerStatusChanged(TimerStatus.completed);
      expect(fakeService.isStopped, isTrue);
      expect(notifier.state.isPlaying, isFalse);
    });
  });

  group('AmbientSoundBottomSheet widget tests', () {
    testWidgets('renders all sound options and slider', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themePrefs = ThemePreferences(prefs);
      final fakeService = FakeAmbientAudioService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ambientAudioServiceProvider.overrideWithValue(fakeService),
            themePreferencesProvider.overrideWithValue(themePrefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AmbientSoundBottomSheet(),
            ),
          ),
        ),
      );

      expect(find.text('Ambient Soundscapes'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Rain'), findsOneWidget);
      expect(find.text('Waves'), findsOneWidget);
      expect(find.text('Campfire'), findsOneWidget);
      expect(find.text('Forest Birds'), findsOneWidget);

      // Tap on Rain sound
      await tester.tap(find.text('Rain'));
      await tester.pumpAndSettle();

      expect(themePrefs.loadAmbientSoundType(), 'rain');
    });
  });
}
