import 'package:flame/components.dart';

import 'grass_game_runtime_state.dart';

class GrassGameRuntimeController {
  GrassGameRuntimeController({
    GrassGameRuntimeState? initialState,
  }) : state = initialState ?? GrassGameRuntimeState.initial(configVersion: 1);

  GrassGameRuntimeState state;
  final Vector2 moveDirection = Vector2.zero();

  void setMoveDirection(double x, double y) {
    moveDirection.setValues(x, y);
    if (moveDirection.length2 > 1) {
      moveDirection.normalize();
    }
  }

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
