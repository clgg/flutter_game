class GameResult {
  const GameResult({
    required this.survivalSeconds,
    required this.killCount,
    required this.level,
    required this.isWin,
  });

  final int survivalSeconds;
  final int killCount;
  final int level;
  final bool isWin;
}
