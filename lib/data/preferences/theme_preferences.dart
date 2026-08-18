import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_mode.dart';

class ThemePreferences {
  static const String prefsName = 'habit_tracker_theme_prefs';
  static const String keyThemeMode = 'key_theme_mode';
  static const String keyUserName = 'key_user_name';
  static const String keyFocusDndEnabled = 'key_focus_dnd_enabled';

  final SharedPreferences? _prefs;

  ThemePreferences(this._prefs);

  AppThemeMode loadThemeMode() {
    final saved = _prefs?.getString(keyThemeMode);
    if (saved == null) return AppThemeMode.system;
    try {
      return AppThemeMode.values.firstWhere((e) => e.name == saved);
    } catch (_) {
      return AppThemeMode.system;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _prefs?.setString(keyThemeMode, mode.name);
  }

  String loadUserName() {
    return _prefs?.getString(keyUserName) ?? '';
  }

  Future<void> setUserName(String name) async {
    await _prefs?.setString(keyUserName, name.trim());
  }

  bool loadFocusDndEnabled() {
    return _prefs?.getBool(keyFocusDndEnabled) ?? false;
  }

  Future<void> setFocusDndEnabled(bool enabled) async {
    await _prefs?.setBool(keyFocusDndEnabled, enabled);
  }
}

// Global state notifiers
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  final ThemePreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_prefs.loadThemeMode());

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(mode);
  }
}

class UserNameNotifier extends StateNotifier<String> {
  final ThemePreferences _prefs;

  UserNameNotifier(this._prefs) : super(_prefs.loadUserName());

  Future<void> setUserName(String name) async {
    state = name.trim();
    await _prefs.setUserName(name);
  }
}

class FocusDndNotifier extends StateNotifier<bool> {
  final ThemePreferences _prefs;

  FocusDndNotifier(this._prefs) : super(_prefs.loadFocusDndEnabled());

  Future<void> setFocusDndEnabled(bool enabled) async {
    state = enabled;
    await _prefs.setFocusDndEnabled(enabled);
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    await _prefs.setFocusDndEnabled(next);
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final themePreferencesProvider = Provider<ThemePreferences>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return ThemePreferences(prefsAsync.value);
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  final prefs = ref.watch(themePreferencesProvider);
  return ThemeModeNotifier(prefs);
});

final userNameProvider = StateNotifierProvider<UserNameNotifier, String>((ref) {
  final prefs = ref.watch(themePreferencesProvider);
  return UserNameNotifier(prefs);
});

final focusDndProvider = StateNotifierProvider<FocusDndNotifier, bool>((ref) {
  final prefs = ref.watch(themePreferencesProvider);
  return FocusDndNotifier(prefs);
});

