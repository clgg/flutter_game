import 'package:app_core/app_core.dart';
import 'package:app_auth/app_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_game/app/app.dart';
import 'package:grass_game_domain/grass_game_domain.dart';
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
    await _pumpUntilFound(tester, find.byType(GrassGameLoadoutPage));

    expect(find.text('Start your run'), findsNothing);
    expect(find.text('Continue with Facebook'), findsNothing);
    expect(find.byType(GrassGameLoadoutPage), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pump();
    expect(find.text('Deathmatch'), findsOneWidget);
  });

  testWidgets('settings sign out returns to login', (
    WidgetTester tester,
  ) async {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) {
        return;
      }
      previousErrorHandler?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = previousErrorHandler;
    });

    SharedPreferences.setMockInitialValues({
      'app_auth.fake_signed_in': true,
      'app_auth.fake_provider': 'googlePlay',
    });
    await tester.pumpWidget(const FlutterGameApp());

    await tester.pump(const Duration(seconds: 2));
    await _pumpUntilFound(tester, find.byType(GrassGameLoadoutPage));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await _pumpUntilFound(tester, find.text('Settings'));

    await tester.scrollUntilVisible(
      find.text('Sign out'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('settings_list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Sign out'));
    await _pumpUntilFound(tester, find.text('Sign out?'));

    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await _pumpUntilFound(tester, find.text('Start your run'));

    expect(await const FakeAuthController().hasSignedInSession(), isFalse);
  });

  testWidgets('stage select follows saved Chinese locale', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: const [Locale('en'), Locale('zh')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          extensions: const [AppGameTheme.glyph],
          useMaterial3: true,
        ),
        home: GrassGameStageSelectPage(
          progressController: GrassGameProgressController.defaults(),
          onBack: () {},
          onStageSelected: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('选择关卡'), findsOneWidget);
    expect(find.text('战役'), findsOneWidget);
    expect(find.text('第 1 章'), findsOneWidget);
    expect(find.text('继续'), findsOneWidget);
    expect(find.textContaining('个敌人'), findsWidgets);
  });

  testWidgets('stage select scrolls to the next playable chapter', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = GrassGameProgressController.defaults();
    await controller.loadSavedProgress();

    for (var index = 0; index < 7; index++) {
      controller.applyBattleResult(
        const GameResult(
          survivalSeconds: 300,
          killCount: 100,
          level: 8,
          isWin: true,
          coinsEarned: 25,
          characterExpEarned: 80,
        ),
      );
      final nextStageId = controller.nextStageId;
      if (nextStageId != null) {
        controller.selectStage(nextStageId);
      }
    }

    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: const [Locale('en'), Locale('zh')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          extensions: const [AppGameTheme.glyph],
          useMaterial3: true,
        ),
        home: GrassGameStageSelectPage(
          progressController: controller,
          onBack: () {},
          onStageSelected: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chapter 2'), findsOneWidget);
    expect(find.text('Chapter 1'), findsNothing);
  });

  testWidgets('loadout opens skill guide and skill detail', (
    WidgetTester tester,
  ) async {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) {
        return;
      }
      previousErrorHandler?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = previousErrorHandler;
    });

    SharedPreferences.setMockInitialValues({
      'app_auth.fake_signed_in': true,
      'app_auth.fake_provider': 'googlePlay',
    });
    await tester.pumpWidget(const FlutterGameApp());

    await tester.pump(const Duration(seconds: 2));
    await _pumpUntilFound(tester, find.byType(GrassGameLoadoutPage));

    await tester.tap(find.text('Skill Guide'));
    await _pumpUntilFound(tester, find.text('星矢弹幕'));

    expect(find.text('星矢弹幕'), findsOneWidget);
    expect(find.text('星矢点火'), findsOneWidget);

    await tester.tap(find.text('星矢点火'));
    await _pumpUntilFound(tester, find.text('Required Level'));

    expect(find.text('Required Level'), findsOneWidget);
    expect(find.text('每次攻击额外 +1 小弹'), findsOneWidget);
  });

  testWidgets('level up panel follows current locale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: const [Locale('en'), Locale('zh')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: LevelUpPanel(
            options: GrassGameConfig.defaults.skills.take(1).toList(),
            pendingCount: 5,
            onSelected: (_) {},
            onRefresh: () {},
          ),
        ),
      ),
    );

    expect(find.text('选择升级'), findsOneWidget);
    expect(find.text('剩余技能点 5'), findsOneWidget);
    expect(find.text('刷新'), findsOneWidget);
    expect(find.text('星矢点火'), findsOneWidget);
    expect(find.text('LEVEL UP'), findsNothing);
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 50,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsWidgets);
}
