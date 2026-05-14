import 'grass_game_runtime_state.dart';

class GrassGameRuntimeController {
  GrassGameRuntimeController({
    GrassGameRuntimeState? initialState,
  }) : state = initialState ?? GrassGameRuntimeState.initial(configVersion: 1);

  GrassGameRuntimeState state;

  void start() {
    state = GrassGameRuntimeState(
      configVersion: state.configVersion,
      isRunning: true,
    );
  }

  void pause() {
    state = GrassGameRuntimeState(
      configVersion: state.configVersion,
      isRunning: false,
    );
  }
}
