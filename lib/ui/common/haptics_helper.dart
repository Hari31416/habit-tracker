import 'package:flutter/services.dart';

class HapticsHelper {
  static void performLightHaptic() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static void selectionClick() => performLightHaptic();

  static void mediumImpact() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static void performHeavyConfirmationHaptic() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {
      try {
        HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  static void celebrate() => performHeavyConfirmationHaptic();
}
