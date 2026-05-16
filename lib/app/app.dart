import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n/app_language_controller.dart';
import 'i18n/app_localizations.dart';
import 'router/app_router.dart';

class FlutterGameApp extends StatefulWidget {
  const FlutterGameApp({super.key});

  @override
  State<FlutterGameApp> createState() => _FlutterGameAppState();
}

class _FlutterGameAppState extends State<FlutterGameApp> {
  final AppLanguageController _languageController = AppLanguageController();

  late final AppRouter _appRouter = AppRouter(
    languageController: _languageController,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _languageController,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Flutter Game',
          locale: _languageController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
          ),
          routerConfig: _appRouter.router,
        );
      },
    );
  }
}
