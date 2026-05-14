import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_game/app/app.dart';

void main() {
  testWidgets('app opens overseas login after splash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlutterGameApp());

    expect(find.text('Start your run'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Start your run'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);
  });
}
