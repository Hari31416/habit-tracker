import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DndService {
  static const MethodChannel _channel =
      MethodChannel('app.phial.habits/focus_timer');

  /// Checks if Notification Policy / DND access has been granted by the user on Android.
  /// Returns true on non-Android platforms or if access is granted.
  static Future<bool> isDndAccessGranted() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final granted = await _channel.invokeMethod<bool>('isDndAccessGranted');
      return granted ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Sets Do Not Disturb mode for active focus timer sessions.
  static Future<void> setDndMode(bool enabled) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setDndMode', {'enabled': enabled});
    } catch (_) {}
  }

  /// Opens the system Do Not Disturb / Notification Policy access settings page.
  static Future<void> openDndSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openDndSettings');
    } catch (_) {}
  }
}
