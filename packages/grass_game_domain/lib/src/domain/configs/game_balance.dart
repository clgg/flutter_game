class GameBalance {
  const GameBalance({
    required this.playerMoveSpeed,
    required this.baseExpToLevelUp,
    required this.maxBattleSeconds,
  });

  final double playerMoveSpeed;
  final int baseExpToLevelUp;
  final int maxBattleSeconds;

  static const defaults = GameBalance(
    playerMoveSpeed: 160,
    baseExpToLevelUp: 6,
    maxBattleSeconds: 300,
  );
}
