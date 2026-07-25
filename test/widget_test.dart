import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/main.dart';

void main() {
  testWidgets('App boots and shows a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(child: const MoneyMateApp()),
    );
    await tester.pump();

    // Just a smoke test for now — confirms the app boots without throwing.
    expect(find.byType(MaterialApp), findsWidgets);
  });
}
