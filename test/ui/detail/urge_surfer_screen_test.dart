import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/preferences/theme_preferences.dart';
import 'package:habit_tracker/ui/detail/urge_surfer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('UrgeSurferScreen renders box breathing UI and controls', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final themePrefs = ThemePreferences(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themePreferencesProvider.overrideWithValue(themePrefs),
        ],
        child: MaterialApp(
          home: UrgeSurferScreen(
            habitId: 'habit_sugar_detox',
            habitTitle: 'Sugar Detox',
            habitColor: '#EF4444',
            onBack: () {},
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Title & Header
    expect(find.text('Urge Surfer • Sugar Detox'), findsOneWidget);
    expect(find.text('Box Breathing Technique (4-4-4-4)'), findsOneWidget);

    // Verify Initial Phase: Inhale Slowly
    expect(find.text('Inhale Slowly'), findsOneWidget);

    // Verify Action Controls
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);

    // Tap Pause
    await tester.ensureVisible(find.text('Pause'));
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);
  });
}
