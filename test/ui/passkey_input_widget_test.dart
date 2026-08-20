import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/ui/settings/passkey_input_widget.dart';

void main() {
  group('PasskeyInputWidget Tests', () {
    testWidgets('renders 4 input segments and separators', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasskeyInputWidget(controller: controller),
          ),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(4));
      expect(find.text('-'), findsNWidgets(3));
    });

    testWidgets('syncs full passkey from controller and formats with hyphens', (tester) async {
      final controller = TextEditingController(text: 'ABCD-EFGH-1234-5678');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasskeyInputWidget(controller: controller),
          ),
        ),
      );

      expect(find.text('ABCD'), findsOneWidget);
      expect(find.text('EFGH'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
      expect(find.text('5678'), findsOneWidget);
    });

    testWidgets('displays errorText without truncating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasskeyInputWidget(
              errorText: 'Incorrect passkey. Please check and try again.',
            ),
          ),
        ),
      );

      expect(find.text('Incorrect passkey. Please check and try again.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
