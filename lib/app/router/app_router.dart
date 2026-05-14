import 'package:go_router/go_router.dart';
import 'package:app_auth/app_auth.dart';
import 'package:app_splash/app_splash.dart';
import 'package:grass_game_ui/grass_game_ui.dart';

class AppRouter {
  const AppRouter._();

  static const home = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const emailLogin = '/login/email';
  static const grassGame = '/grass-game';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) => const GrassGamePage(),
      ),
      GoRoute(
        path: splash,
        builder: (context, state) => OdtSplashPage(
          onCompleted: () async {
            final route = await const StartupDecider(
              loginRoute: login,
            ).nextRoute();
            if (context.mounted) {
              context.go(route);
            }
          },
        ),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => GlobalLoginPage(
          onSignedIn: (_) => context.go(grassGame),
          onEmailRequested: () => context.push(emailLogin),
        ),
      ),
      GoRoute(
        path: emailLogin,
        builder: (context, state) => EmailLoginPage(
          onSignedIn: (_) => context.go(grassGame),
        ),
      ),
      GoRoute(
        path: grassGame,
        builder: (context, state) => const GrassGamePage(),
      ),
    ],
  );
}
