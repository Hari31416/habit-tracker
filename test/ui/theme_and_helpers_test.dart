import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/preferences/theme_preferences.dart';
import 'package:habit_tracker/ui/common/color_utils.dart';
import 'package:habit_tracker/ui/theme/app_colors.dart';
import 'package:habit_tracker/ui/theme/app_shapes.dart';
import 'package:habit_tracker/ui/theme/app_theme.dart';
import 'package:habit_tracker/ui/theme/app_typography.dart';

void main() {
  group('AppTheme and Design Tokens', () {
    test('Color tokens match Kotlin Color.kt specifications', () {
      expect(kPrimaryLight.toARGB32(), 0xFF0A7A64);
      expect(kPrimaryDark.toARGB32(), 0xFF14B8A6);
      expect(kTertiaryLight.toARGB32(), 0xFFF59E0B);
      expect(kHabitColorEmerald.toARGB32(), 0xFF10B981);
      expect(kHabitPresetColors.length, 8);
      expect(kHabitPresetColors[0], '#10B981');
    });

    test('Shapes match Kotlin Shape.kt specifications', () {
      expect(AppShapes.extraSmallRadius, 4.0);
      expect(AppShapes.smallRadius, 8.0);
      expect(AppShapes.mediumRadius, 14.0);
      expect(AppShapes.cardRadius, 16.0);
      expect(AppShapes.largeRadius, 20.0);
      expect(AppShapes.extraLargeRadius, 28.0);
    });

    test('Typography matches Kotlin Type.kt specifications', () {
      expect(kAppTypography.displayLarge?.fontSize, 32);
      expect(kAppTypography.displayMedium?.fontSize, 28);
      expect(kAppTypography.displaySmall?.fontSize, 24);
      expect(kAppTypography.headlineLarge?.fontSize, 22);
      expect(kAppTypography.headlineMedium?.fontSize, 18);
      expect(kAppTypography.titleLarge?.fontSize, 18);
      expect(kAppTypography.titleMedium?.fontSize, 15);
      expect(kAppTypography.bodyLarge?.fontSize, 15);
      expect(kAppTypography.bodyMedium?.fontSize, 14);
      expect(kAppTypography.labelSmall?.fontSize, 10);
    });

    test('AppTheme creates valid light and dark ThemeData', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.useMaterial3, isTrue);
      expect(light.colorScheme.primary, kPrimaryLight);
      expect(dark.useMaterial3, isTrue);
      expect(dark.colorScheme.primary, kPrimaryDark);
    });
  });

  group('ColorUtils', () {
    test('parseHexColor parses 6-char hex with and without hash', () {
      final c1 = ColorUtils.parseHexColor('#10B981');
      expect(c1.toARGB32(), 0xFF10B981);

      final c2 = ColorUtils.parseHexColor('10B981');
      expect(c2.toARGB32(), 0xFF10B981);
    });

    test('parseHexColor parses 8-char hex', () {
      final c = ColorUtils.parseHexColor('#FF10B981');
      expect(c.toARGB32(), 0xFF10B981);
    });

    test('parseHexColor returns default color on null or invalid input', () {
      const defaultC = Color(0xFF10B981);
      expect(ColorUtils.parseHexColor(null), defaultC);
      expect(ColorUtils.parseHexColor(''), defaultC);
      expect(ColorUtils.parseHexColor('invalid'), defaultC);
    });
  });

  group('FocusDndNotifier', () {
    test('loads default DND state as false and toggles state correctly', () async {
      final themePrefs = ThemePreferences(null);
      final notifier = FocusDndNotifier(themePrefs);

      expect(notifier.state, isFalse);
      await notifier.toggle();
      expect(notifier.state, isTrue);

      await notifier.setFocusDndEnabled(false);
      expect(notifier.state, isFalse);
    });
  });
}
