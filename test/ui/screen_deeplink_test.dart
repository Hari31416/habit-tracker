import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/ui/navigation/screen.dart';

void main() {
  group('Screen.fromUri', () {
    test('null or empty uri maps to daily', () {
      expect(Screen.fromUri(null), Screen.daily);
      expect(Screen.fromUri(''), Screen.daily);
      expect(Screen.fromUri('   '), Screen.daily);
    });

    test('daily uris map to daily route', () {
      expect(Screen.fromUri('app://habits/daily'), Screen.daily);
      expect(Screen.fromUri('app://habits/daily/'), Screen.daily);
      expect(Screen.fromUri('daily'), Screen.daily);
      expect(Screen.fromUri('/daily'), Screen.daily);
      expect(Screen.fromUri('app://habits'), Screen.daily);
    });

    test('matrix uris map to matrix route', () {
      expect(Screen.fromUri('app://habits/matrix'), Screen.matrix);
      expect(Screen.fromUri('/matrix'), Screen.matrix);
      expect(Screen.fromUri('matrix'), Screen.matrix);
    });

    test('analytics uris map to analytics route', () {
      expect(Screen.fromUri('app://habits/analytics'), Screen.analytics);
      expect(Screen.fromUri('/analytics'), Screen.analytics);
      expect(Screen.fromUri('analytics'), Screen.analytics);
    });

    test('badges uris map to badges route', () {
      expect(Screen.fromUri('app://habits/badges'), Screen.badges);
      expect(Screen.fromUri('/badges'), Screen.badges);
      expect(Screen.fromUri('badges'), Screen.badges);
    });

    test('detail uris with valid id map to detail route', () {
      expect(
        Screen.fromUri('app://habits/detail/h_123'),
        'detail/h_123',
      );
      expect(
        Screen.fromUri('app://habits/detail/uuid-550e8400-e29b-41d4-a716-446655440000'),
        'detail/uuid-550e8400-e29b-41d4-a716-446655440000',
      );
      expect(
        Screen.fromUri('detail/h_123'),
        'detail/h_123',
      );
      expect(
        Screen.fromUri('/detail/h_123'),
        'detail/h_123',
      );
    });

    test('detail uris with empty or missing id fallback to daily', () {
      expect(Screen.fromUri('app://habits/detail'), Screen.daily);
      expect(Screen.fromUri('app://habits/detail/'), Screen.daily);
      expect(Screen.fromUri('app://habits/detail/   '), Screen.daily);
      expect(Screen.fromUri('detail/'), Screen.daily);
      expect(Screen.fromUri('detail'), Screen.daily);
    });

    test('focus_timer uris with valid id map to focus_timer route', () {
      expect(
        Screen.fromUri('app://habits/focus_timer/timer_1'),
        'focus_timer/timer_1',
      );
      expect(
        Screen.fromUri('focus_timer/timer_1'),
        'focus_timer/timer_1',
      );
      expect(
        Screen.fromUri('/focus_timer/timer_1'),
        'focus_timer/timer_1',
      );
    });

    test('focus_timer uris with empty id fallback to daily', () {
      expect(Screen.fromUri('app://habits/focus_timer'), Screen.daily);
      expect(Screen.fromUri('app://habits/focus_timer/'), Screen.daily);
      expect(Screen.fromUri('focus_timer/'), Screen.daily);
      expect(Screen.fromUri('focus_timer'), Screen.daily);
    });

    test('unknown or garbage uris fallback to daily', () {
      expect(Screen.fromUri('app://habits/nonexistent/screen'), Screen.daily);
      expect(Screen.fromUri('garbage_random_string'), Screen.daily);
      expect(Screen.fromUri('https://google.com'), Screen.daily);
    });
  });
}
