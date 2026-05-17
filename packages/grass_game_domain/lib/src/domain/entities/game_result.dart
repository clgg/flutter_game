class GameResult {
  const GameResult({
    required this.survivalSeconds,
    required this.killCount,
    required this.level,
    required this.isWin,
    required this.coinsEarned,
    required this.characterExpEarned,
    this.collectedCoins = 0,
    this.stageCoins = 0,
    this.survivalCoins = 0,
    this.killExp = 0,
    this.battleLevelExp = 0,
    this.stageExp = 0,
  });

  final int survivalSeconds;
  final int killCount;
  final int level;
  final bool isWin;
  final int coinsEarned;
  final int characterExpEarned;
  final int collectedCoins;
  final int stageCoins;
  final int survivalCoins;
  final int killExp;
  final int battleLevelExp;
  final int stageExp;
}
