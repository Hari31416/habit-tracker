import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/di/providers.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/ui/navigation/habit_bottom_navigation.dart';
import 'ui/daily_tracker_controller_test.dart';
import 'ui/gamification_controller_test.dart' show FakeGamificationRepository;

void main() {
  testWidgets('App smoke test renders daily tracker and bottom nav',
      (WidgetTester tester) async {
    final fakeRepo = FakeHabitRepository();
    final fakeGamification = FakeGamificationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitRepositoryProvider.overrideWithValue(fakeRepo),
          gamificationRepositoryProvider.overrideWithValue(fakeGamification),
        ],
        child: const HabitTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("Today's Progress"), findsOneWidget);
    expect(find.byType(HabitBottomNavigation), findsWidgets);
  });
}
