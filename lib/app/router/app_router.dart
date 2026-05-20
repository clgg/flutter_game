import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';
import 'package:app_auth/app_auth.dart';
import 'package:app_splash/app_splash.dart';
import 'package:grass_game_ui/grass_game_ui.dart';

import '../i18n/app_language_controller.dart';
import '../settings/app_theme_controller.dart';
import '../settings/crash_log_page.dart';
import '../settings/game_feedback_settings_controller.dart';
import '../settings/language_settings_page.dart';

class AppRouter {
  AppRouter({
    required this.languageController,
    required this.themeController,
    required this.feedbackSettingsController,
  });

  final AppLanguageController languageController;
  final AppThemeController themeController;
  final GameFeedbackSettingsController feedbackSettingsController;

  static const home = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const emailLogin = '/login/email';
  static const loadout = '/loadout';
  static const skillGuide = '/skill-guide';
  static const stageSelect = '/stages';
  static const grassGame = '/grass-game';
  static const languageSettings = '/settings/language';
  static const crashLogs = '/settings/crash-logs';

  static final GrassGameProgressController _progressController =
      GrassGameProgressController.defaults();

  late final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) => GrassGameLoadoutPage(
          progressController: _progressController,
          onSettings: () => context.push(languageSettings),
          onSkillGuide: () => context.push(skillGuide),
          onStart: () => context.go(stageSelect),
          onDeathmatchStart: () => _startDeathmatch(context),
        ),
      ),
      GoRoute(
        path: splash,
        builder: (context, state) => OdtSplashPage(
          onCompleted: () async {
            final isSignedIn =
                await const FakeAuthController().hasSignedInSession();
            final route = isSignedIn ? loadout : login;
            if (context.mounted) {
              context.go(route);
            }
          },
        ),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => GlobalLoginPage(
          onSignedIn: (_) => context.go(loadout),
          onEmailRequested: () => context.push(emailLogin),
        ),
      ),
      GoRoute(
        path: emailLogin,
        builder: (context, state) => EmailLoginPage(
          onSignedIn: (_) => context.go(loadout),
        ),
      ),
      GoRoute(
        path: loadout,
        builder: (context, state) => GrassGameLoadoutPage(
          progressController: _progressController,
          onSettings: () => context.push(languageSettings),
          onSkillGuide: () => context.push(skillGuide),
          onStart: () => context.go(stageSelect),
          onDeathmatchStart: () => _startDeathmatch(context),
        ),
      ),
      GoRoute(
        path: skillGuide,
        builder: (context, state) => const GrassGameSkillGuidePage(),
      ),
      GoRoute(
        path: stageSelect,
        builder: (context, state) => GrassGameStageSelectPage(
          progressController: _progressController,
          onBack: () => context.go(loadout),
          onStageSelected: () => context.go(grassGame),
        ),
      ),
      GoRoute(
        path: languageSettings,
        builder: (context, state) => LanguageSettingsPage(
          languageController: languageController,
          themeController: themeController,
          feedbackSettingsController: feedbackSettingsController,
          onCrashLogs: () => context.push(crashLogs),
          onSignOut: () async {
            await const FakeAuthController().signOut();
            if (context.mounted) {
              context.go(login);
            }
          },
        ),
      ),
      GoRoute(
        path: crashLogs,
        builder: (context, state) => const CrashLogPage(),
      ),
      GoRoute(
        path: grassGame,
        builder: (context, state) => GrassGamePage(
          progressController: _progressController,
          soundVolume: feedbackSettingsController.soundVolume,
          vibrationIntensity: feedbackSettingsController.vibrationIntensity,
          onExit: () => context.go(_currentRunExitRoute),
          onUpgradeWeapon: () => context.go(loadout),
        ),
      ),
    ],
  );

  String get _currentRunExitRoute {
    return _progressController.selectedStage.isDeathmatch
        ? loadout
        : stageSelect;
  }

  void _startDeathmatch(BuildContext context) {
    _progressController
        .selectStage(GrassGameProgressController.deathmatchStageId);
    context.go(grassGame);
  }
}
