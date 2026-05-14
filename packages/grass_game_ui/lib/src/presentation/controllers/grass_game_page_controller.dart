import 'package:app_core/app_core.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';

import '../../application/use_cases/load_grass_game_config.dart';
import '../../application/use_cases/start_grass_game.dart';

class GrassGamePageController {
  const GrassGamePageController({
    required LoadGrassGameConfig loadConfig,
    required StartGrassGame startGame,
  })  : _loadConfig = loadConfig,
        _startGame = startGame;

  final LoadGrassGameConfig _loadConfig;
  final StartGrassGame _startGame;

  Future<GrassGameRuntimeState?> start() async {
    final result = await _loadConfig();

    return switch (result) {
      Success(:final value) => _startGame(value),
      Failure() => null,
    };
  }
}
