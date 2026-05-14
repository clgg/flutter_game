class HudSnapshot {
  const HudSnapshot({
    required this.hp,
    required this.exp,
    required this.level,
    required this.elapsedSeconds,
    required this.killCount,
  });

  final int hp;
  final int exp;
  final int level;
  final int elapsedSeconds;
  final int killCount;
}
