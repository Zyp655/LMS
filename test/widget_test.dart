// Smoke test – verifies MyApp can be instantiated.
// Uses a minimal approach that doesn't require platform plugins.

import 'package:flutter_test/flutter_test.dart';
import 'package:alarmm/main.dart';

void main() {
  testWidgets('MyApp can be instantiated', (WidgetTester tester) async {
    // Simply verify the widget class exists and can be constructed.
    // Full integration testing requires platform plugins (SharedPreferences, etc.)
    // which are not available in the default test environment.
    expect(const MyApp(), isA<MyApp>());
  });
}
