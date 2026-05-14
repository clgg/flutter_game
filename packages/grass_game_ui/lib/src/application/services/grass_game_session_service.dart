import 'package:grass_game_domain/grass_game_domain.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';
import '../use_cases/start_grass_game.dart';

class GrassGameSessionService {
  const GrassGameSessionService(this._startGame);

  final StartGrassGame _startGame;

  GrassGameRuntimeState start(GrassGameConfig config) {
    return _startGame(config);
  }
}
