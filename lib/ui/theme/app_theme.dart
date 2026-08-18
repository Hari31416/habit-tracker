import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_shapes.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: kLightColorScheme,
      scaffoldBackgroundColor: kBackgroundLight,
      textTheme: kAppTypography,
      cardTheme: const CardThemeData(
        color: kSurfaceLight,
        elevation: 1,
        shape: AppShapes.cardShape,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.small,
        ),
        side: const BorderSide(color: kOutlineLight),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.large,
        ),
        backgroundColor: kSurfaceLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kSurfaceLight,
        foregroundColor: kOnSurfaceLight,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: kBackgroundLight,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: kDarkColorScheme,
      scaffoldBackgroundColor: kBackgroundDark,
      textTheme: kAppTypography,
      cardTheme: const CardThemeData(
        color: kSurfaceDark,
        elevation: 1,
        shape: AppShapes.cardShape,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.small,
        ),
        side: const BorderSide(color: kOutlineDark),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.large,
        ),
        backgroundColor: kSurfaceDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kSurfaceDark,
        foregroundColor: kOnSurfaceDark,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: kBackgroundDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
    );
  }
}
