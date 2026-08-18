import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HabitTrackerApp()));
    expect(find.text('Habit Tracker - Phase 1 Complete'), findsOneWidget);
  });
}
