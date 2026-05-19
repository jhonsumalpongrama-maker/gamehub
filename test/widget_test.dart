import 'package:flutter_test/flutter_test.dart';
import 'package:rama_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('GAME HUB'), findsOneWidget);
  });
}
