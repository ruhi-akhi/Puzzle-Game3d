import 'package:flutter_test/flutter_test.dart';
import 'package:echo_labyrinth/main.dart';

void main() {
  testWidgets('App launches with title', (WidgetTester tester) async {
    await tester.pumpWidget(const EchoLabyrinthApp());
    await tester.pump();
    expect(find.textContaining('ECHO'), findsOneWidget);
  });
}
