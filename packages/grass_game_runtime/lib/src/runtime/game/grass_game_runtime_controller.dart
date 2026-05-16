import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

import 'grass_game_runtime_state.dart';
import '../snapshots/hud_snapshot.dart';

class GrassGameRuntimeController extends ChangeNotifier {
  GrassGameRuntimeController({
    GrassGameRuntimeState? initialState,
  }) : state = initialState ?? GrassGameRuntimeState.initial(configVersion: 1);

  GrassGameRuntimeState state;
  final Vector2 moveDirection = Vector2.zero();
  HudSnapshot hud = HudSnapshot.empty;
  List<SkillConfig> levelUpOptions = const [];
  GameResult? result;
  double timeScale = 1;
  int pendingLevelUpCount = 0;

  bool get isLevelUpVisible => levelUpOptions.isNotEmpty;
  bool get isGameOver => result != null;
  bool get isDoubleSpeed => timeScale == 2;
  bool get hasPendingLevelUps => pendingLevelUpCount > 0;

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
    result = null;
    levelUpOptions = const [];
    pendingLevelUpCount = 0;
    notifyListeners();
  }

  void pause() {
    state = GrassGameRuntimeState(
      configVersion: state.configVersion,
      isRunning: false,
    );
    notifyListeners();
  }

  void resume() {
    state = GrassGameRuntimeState(
      configVersion: state.configVersion,
      isRunning: true,
    );
    notifyListeners();
  }

  void setTimeScale(double value) {
    final nextTimeScale = value >= 1.5 ? 2.0 : 1.0;
    if (timeScale == nextTimeScale) {
      return;
    }
    timeScale = nextTimeScale;
    notifyListeners();
  }

  void toggleTimeScale() {
    setTimeScale(isDoubleSpeed ? 1 : 2);
  }

  void updateHud(HudSnapshot snapshot) {
    hud = snapshot;
    notifyListeners();
  }

  void showLevelUp(List<SkillConfig> options) {
    levelUpOptions = List.unmodifiable(options);
    state = GrassGameRuntimeState(
      configVersion: state.configVersion,
      isRunning: false,
    );
    notifyListeners();
  }

  void setPendingLevelUps(int count) {
    final nextCount = count < 0 ? 0 : count;
    if (pendingLevelUpCount == nextCount) {
      return;
    }
    pendingLevelUpCount = nextCount;
    if (pendingLevelUpCount == 0) {
      levelUpOptions = const [];
    }
    notifyListeners();
  }

  void clearLevelUp() {
    levelUpOptions = const [];
    state = GrassGameRuntimeState(
      configVersion: state.configVersion,
      isRunning: true,
    );
    notifyListeners();
  }

  void finish(GameResult value) {
    result = value;
    state = GrassGameRuntimeState(
      configVersion: state.configVersion,
      isRunning: false,
    );
    notifyListeners();
  }
}
