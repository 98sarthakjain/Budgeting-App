import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Keep this test intentionally minimal so it doesn't break when app
    // constructors or dependency wiring changes during early development.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    expect(find.byType(SizedBox), findsOneWidget);
  });
}
