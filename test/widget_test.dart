import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_game/app/app.dart';

void main() {
  testWidgets('app shell opens grass game route', (WidgetTester tester) async {
    await tester.pumpWidget(const FlutterGameApp());

    expect(find.text('Grass Game Ready'), findsOneWidget);
    expect(find.text('HP 100'), findsOneWidget);
  });
}
