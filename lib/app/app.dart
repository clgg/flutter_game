import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n/app_language_controller.dart';
import 'i18n/app_localizations.dart';
import 'router/app_router.dart';
import 'settings/app_theme_controller.dart';
import 'settings/game_feedback_settings_controller.dart';

class FlutterGameApp extends StatefulWidget {
  const FlutterGameApp({super.key});

  @override
  State<FlutterGameApp> createState() => _FlutterGameAppState();
}

class _FlutterGameAppState extends State<FlutterGameApp> {
  final AppLanguageController _languageController = AppLanguageController();
  final AppThemeController _themeController = AppThemeController();
  final GameFeedbackSettingsController _feedbackSettingsController =
      GameFeedbackSettingsController();

  late final AppRouter _appRouter = AppRouter(
    languageController: _languageController,
    themeController: _themeController,
    feedbackSettingsController: _feedbackSettingsController,
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _languageController,
        _themeController,
        _feedbackSettingsController,
      ]),
      builder: (context, _) {
        final gameTheme = _themeController.gameTheme;
        return MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: _languageController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: gameTheme.accent,
              brightness: _themeController.style == AppGameThemeStyle.sticker
                  ? Brightness.light
                  : Brightness.dark,
              primary: gameTheme.accent,
              secondary: gameTheme.accent2,
              surface: gameTheme.deep,
              error: gameTheme.hot,
            ),
            scaffoldBackgroundColor: gameTheme.background,
            appBarTheme: AppBarTheme(
              backgroundColor: gameTheme.background,
              foregroundColor: gameTheme.foreground,
              elevation: 0,
            ),
            extensions: [gameTheme],
            useMaterial3: true,
          ),
          routerConfig: _appRouter.router,
        );
      },
    );
  }
}
