import 'package:flutter/material.dart';

class ColorUtils {
  static Color parseHexColor(
    String? hexString, {
    Color defaultColor = const Color(0xFF10B981),
  }) {
    if (hexString == null || hexString.trim().isEmpty) {
      return defaultColor;
    }
    try {
      var cleanHex = hexString.trim();
      if (cleanHex.startsWith('#')) {
        cleanHex = cleanHex.substring(1);
      }
      if (cleanHex.length == 6) {
        final colorInt = int.parse(cleanHex, radix: 16);
        return Color(0xFF000000 | colorInt);
      } else if (cleanHex.length == 8) {
        final colorInt = int.parse(cleanHex, radix: 16);
        return Color(colorInt);
      } else {
        return defaultColor;
      }
    } catch (_) {
      return defaultColor;
    }
  }

  static Color fromHex(
    String? hexString, {
    Color defaultColor = const Color(0xFF10B981),
  }) =>
      parseHexColor(hexString, defaultColor: defaultColor);
}
