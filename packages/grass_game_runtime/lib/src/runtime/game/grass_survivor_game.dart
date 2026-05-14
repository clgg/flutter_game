import 'package:grass_game_domain/grass_game_domain.dart';
import 'grass_game_runtime_state.dart';

class GrassSurvivorGame {
  GrassSurvivorGame({
    required this.config,
  }) : state = GrassGameRuntimeState.initial(
          configVersion: config.version,
        );

  final GrassGameConfig config;
  GrassGameRuntimeState state;
}
