class GameTime {
  const GameTime(this.elapsedSeconds) : assert(elapsedSeconds >= 0);

  final int elapsedSeconds;
}
