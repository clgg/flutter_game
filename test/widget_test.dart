import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_game/app/app.dart';
import 'package:grass_game_ui/grass_game_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app opens overseas login after splash', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FlutterGameApp());

    expect(find.text('Start your run'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Start your run'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);
  });

  testWidgets('app skips login after fake sign in was saved', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'app_auth.fake_signed_in': true,
      'app_auth.fake_provider': 'googlePlay',
    });
    await tester.pumpWidget(const FlutterGameApp());

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Start your run'), findsNothing);
    expect(find.text('Continue with Facebook'), findsNothing);
    expect(find.byType(GrassGameLoadoutPage), findsOneWidget);
  });
}
