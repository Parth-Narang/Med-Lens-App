import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FIX 1: Ensure 'my_app' matches the 'name' in your pubspec.yaml file
import 'package:my_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // FIX 2: This must match the class name in your lib/main.dart
    await tester.pumpWidget(const MedVerifyApp());

    // Verify that our counter starts at 0.
    // NOTE: If your app doesn't have a '0' on the screen, this test will fail.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
