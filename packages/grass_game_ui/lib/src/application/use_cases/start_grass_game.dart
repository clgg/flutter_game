import 'package:grass_game_domain/grass_game_domain.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';

class StartGrassGame {
  const StartGrassGame();

  GrassGameRuntimeState call(GrassGameConfig config) {
    return GrassGameRuntimeState.initial(configVersion: config.version);
  }
}
