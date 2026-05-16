class GameResult {
  const GameResult({
    required this.survivalSeconds,
    required this.killCount,
    required this.level,
    required this.isWin,
    required this.coinsEarned,
    required this.characterExpEarned,
  });

  final int survivalSeconds;
  final int killCount;
  final int level;
  final bool isWin;
  final int coinsEarned;
  final int characterExpEarned;
}
