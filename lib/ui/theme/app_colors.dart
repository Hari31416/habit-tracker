import 'package:flutter/material.dart';

// Light Theme Tokens (Matches productivity index.css :root and Color.kt)
const Color kPrimaryLight = Color(0xFF0A7A64); // hsl(168.2 84.8% 25.9%)
const Color kOnPrimaryLight = Color(0xFFFFFFFF);
const Color kPrimaryContainerLight = Color(0xFFDDF7F0); // hsl(164 62% 91.8%)
const Color kOnPrimaryContainerLight = Color(0xFF065243); // hsl(168.2 86.4% 17.3%)

const Color kSecondaryLight = Color(0xFFF1F5F9); // hsl(210 40% 96.1%)
const Color kOnSecondaryLight = Color(0xFF334155); // hsl(215 25% 27%)
const Color kSecondaryContainerLight = Color(0xFFE2E8F0); // hsl(214.3 31.8% 91.4%)
const Color kOnSecondaryContainerLight = Color(0xFF1E293B);

const Color kTertiaryLight = Color(0xFFF59E0B); // Amber / Warning: hsl(38 92% 50%)
const Color kOnTertiaryLight = Color(0xFFFFFFFF);
const Color kTertiaryContainerLight = Color(0xFFFEF3C7);
const Color kOnTertiaryContainerLight = Color(0xFF78350F);

const Color kErrorLight = Color(0xFFEF4444); // Destructive: hsl(0 84% 60%)
const Color kOnErrorLight = Color(0xFFFFFFFF);
const Color kErrorContainerLight = Color(0xFFFEE2E2);
const Color kOnErrorContainerLight = Color(0xFF991B1B);

const Color kBackgroundLight = Color(0xFFF8FAFC); // hsl(210 40% 98%)
const Color kOnBackgroundLight = Color(0xFF0F172A); // hsl(222.2 47.4% 11.2%)
const Color kSurfaceLight = Color(0xFFFFFFFF); // hsl(0 0% 100%)
const Color kOnSurfaceLight = Color(0xFF0F172A); // hsl(222.2 47.4% 11.2%)
const Color kSurfaceVariantLight = Color(0xFFF1F5F9); // hsl(210 40% 96.1%)
const Color kOnSurfaceVariantLight = Color(0xFF475569); // hsl(215.3 19.3% 34.5%)
const Color kOutlineLight = Color(0xFFE2E8F0); // hsl(214.3 31.8% 91.4%)
const Color kOutlineVariantLight = Color(0xFFCBD5E1); // slate-300

// Dark Theme Tokens (Matches productivity index.css .dark and Color.kt)
const Color kPrimaryDark = Color(0xFF14B8A6); // hsl(173.4 80.4% 40%)
const Color kOnPrimaryDark = Color(0xFF0B1211); // hsl(171.4 24.1% 5.7%)
const Color kPrimaryContainerDark = Color(0xFF112C26); // hsl(168 45% 12%)
const Color kOnPrimaryContainerDark = Color(0xFF66DBBF);

const Color kSecondaryDark = Color(0xFF172522); // hsl(167.1 23.3% 11.8%)
const Color kOnSecondaryDark = Color(0xFFBED0CC); // hsl(165.9 16% 78%)
const Color kSecondaryContainerDark = Color(0xFF263936); // hsl(170.5 20% 18.6%)
const Color kOnSecondaryContainerDark = Color(0xFFF1F5F4);

const Color kTertiaryDark = Color(0xFFF59E0B); // Amber / Warning: hsl(38 92% 50%)
const Color kOnTertiaryDark = Color(0xFF451A03);
const Color kTertiaryContainerDark = Color(0xFF78350F);
const Color kOnTertiaryContainerDark = Color(0xFFFDE68A);

const Color kErrorDark = Color(0xFFEF4444); // Destructive: hsl(0 84% 60%)
const Color kOnErrorDark = Color(0xFF450A0A);
const Color kErrorContainerDark = Color(0xFF7F1D1D);
const Color kOnErrorContainerDark = Color(0xFFFCA5A5);

const Color kBackgroundDark = Color(0xFF0B1211); // hsl(171.4 24.1% 5.7%)
const Color kOnBackgroundDark = Color(0xFFF1F5F4); // hsl(165 14.3% 95.3%)
const Color kSurfaceDark = Color(0xFF111C1A); // Card: hsl(169.1 24.4% 8.8%)
const Color kOnSurfaceDark = Color(0xFFF1F5F4); // Card foreground: hsl(165 14.3% 95.3%)
const Color kSurfaceVariantDark = Color(0xFF172522); // Elevated surface: hsl(167.1 23.3% 11.8%)
const Color kOnSurfaceVariantDark = Color(0xFF96ABA6); // Muted foreground: hsl(168 12% 64%)
const Color kOutlineDark = Color(0xFF263936); // Border: hsl(170.5 20% 18.6%)
const Color kOutlineVariantDark = Color(0xFF172522);

// Semantic Accent & Preset Habit Colors
const Color kHabitColorEmerald = Color(0xFF10B981);
const Color kHabitColorTeal = Color(0xFF0D9488);
const Color kHabitColorCyanTeal = Color(0xFF14B8A6);
const Color kHabitColorIndigo = Color(0xFF6366F1);
const Color kHabitColorViolet = Color(0xFF8B5CF6);
const Color kHabitColorAmber = Color(0xFFF59E0B);
const Color kHabitColorCoral = Color(0xFFEF4444);
const Color kHabitColorPink = Color(0xFFEC4899);
const Color kHabitColorCyan = Color(0xFF06B6D4);

const List<String> kHabitPresetColors = [
  '#10B981', // Emerald
  '#0D9488', // Teal
  '#14B8A6', // Cyan Teal
  '#6366F1', // Indigo
  '#8B5CF6', // Violet
  '#F59E0B', // Amber
  '#EF4444', // Coral
  '#EC4899', // Pink
];

const ColorScheme kLightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: kPrimaryLight,
  onPrimary: kOnPrimaryLight,
  primaryContainer: kPrimaryContainerLight,
  onPrimaryContainer: kOnPrimaryContainerLight,
  secondary: kSecondaryLight,
  onSecondary: kOnSecondaryLight,
  secondaryContainer: kSecondaryContainerLight,
  onSecondaryContainer: kOnSecondaryContainerLight,
  tertiary: kTertiaryLight,
  onTertiary: kOnTertiaryLight,
  tertiaryContainer: kTertiaryContainerLight,
  onTertiaryContainer: kOnTertiaryContainerLight,
  error: kErrorLight,
  onError: kOnErrorLight,
  errorContainer: kErrorContainerLight,
  onErrorContainer: kOnErrorContainerLight,
  surface: kSurfaceLight,
  onSurface: kOnSurfaceLight,
  surfaceContainerHighest: kSurfaceVariantLight,
  onSurfaceVariant: kOnSurfaceVariantLight,
  outline: kOutlineLight,
  outlineVariant: kOutlineVariantLight,
);

const ColorScheme kDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: kPrimaryDark,
  onPrimary: kOnPrimaryDark,
  primaryContainer: kPrimaryContainerDark,
  onPrimaryContainer: kOnPrimaryContainerDark,
  secondary: kSecondaryDark,
  onSecondary: kOnSecondaryDark,
  secondaryContainer: kSecondaryContainerDark,
  onSecondaryContainer: kOnSecondaryContainerDark,
  tertiary: kTertiaryDark,
  onTertiary: kOnTertiaryDark,
  tertiaryContainer: kTertiaryContainerDark,
  onTertiaryContainer: kOnTertiaryContainerDark,
  error: kErrorDark,
  onError: kOnErrorDark,
  errorContainer: kErrorContainerDark,
  onErrorContainer: kOnErrorContainerDark,
  surface: kSurfaceDark,
  onSurface: kOnSurfaceDark,
  surfaceContainerHighest: kSurfaceVariantDark,
  onSurfaceVariant: kOnSurfaceVariantDark,
  outline: kOutlineDark,
  outlineVariant: kOutlineVariantDark,
);
