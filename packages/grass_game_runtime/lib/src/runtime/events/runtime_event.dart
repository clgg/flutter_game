abstract class RuntimeEvent {
  const RuntimeEvent();
}

class GameStarted extends RuntimeEvent {
  const GameStarted();
}

class GamePaused extends RuntimeEvent {
  const GamePaused();
}

class GameResumed extends RuntimeEvent {
  const GameResumed();
}
