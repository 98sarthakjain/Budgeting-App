// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('smoke test: HomeScreen builds', (WidgetTester tester) async {
    // Build a minimal app with HomeScreen as the root.
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Basic sanity check: HomeScreen is in the widget tree.
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
