import 'package:flutter/material.dart';
import 'package:grass_game_ui/grass_game_ui.dart';

class AppRouter {
  const AppRouter._();

  static const home = '/';
  static const grassGame = '/grass-game';

  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const GrassGamePage(),
        grassGame: (_) => const GrassGamePage(),
      };
}
