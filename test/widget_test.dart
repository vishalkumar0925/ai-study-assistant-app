import 'package:flutter_test/flutter_test.dart';
import 'package:ai_study_assistant_app/main.dart';

void main() {
  testWidgets('AI Study Assistant app test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app starts up correctly.
    expect(find.byType(MyApp), findsOneWidget);
  });
}