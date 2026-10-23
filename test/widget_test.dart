import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_study_assistant_app/main.dart';

void main() {
  testWidgets('WebView app test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WebViewApp()));
    expect(find.byType(WebViewApp), findsOneWidget);
  });
}