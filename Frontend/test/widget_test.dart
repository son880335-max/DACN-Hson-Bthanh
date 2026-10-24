import 'package:flutter_test/flutter_test.dart';
import 'package:flood_relief_app/main.dart';

void main() {
  testWidgets('App loads role selection screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FloodReliefApp());
    await tester.pumpAndSettle();

    // Verify role selection header exists
    expect(find.text('Cứu trợ đồng bào lũ lụt'), findsOneWidget);
  });
}
