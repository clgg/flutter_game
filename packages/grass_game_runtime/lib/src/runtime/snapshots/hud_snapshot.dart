class HudSnapshot {
  const HudSnapshot({
    required this.hp,
    required this.maxHp,
    required this.exp,
    required this.requiredExp,
    required this.level,
    required this.elapsedSeconds,
    required this.killCount,
    required this.maxBattleSeconds,
    required this.coins,
  });

  final int hp;
  final int maxHp;
  final int exp;
  final int requiredExp;
  final int level;
  final int elapsedSeconds;
  final int killCount;
  final int maxBattleSeconds;
  final int coins;

  static const empty = HudSnapshot(
    hp: 100,
    maxHp: 100,
    exp: 0,
    requiredExp: 10,
    level: 1,
    elapsedSeconds: 0,
    killCount: 0,
    maxBattleSeconds: 300,
    coins: 0,
  );
}
