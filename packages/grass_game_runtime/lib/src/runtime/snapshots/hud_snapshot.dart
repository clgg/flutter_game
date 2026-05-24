class HudSnapshot {
  const HudSnapshot({
    required this.hp,
    required this.maxHp,
    required this.exp,
    required this.requiredExp,
    required this.level,
    required this.stageName,
    required this.stageChapter,
    required this.stageIndex,
    required this.elapsedSeconds,
    required this.killCount,
    required this.maxBattleSeconds,
    required this.coins,
    required this.stageEnemyCount,
    required this.bossTimeSeconds,
    required this.isBossSpawned,
    required this.ultimateCharge,
    required this.ultimateChargeRequired,
    required this.weaponUltimateCharge,
    required this.weaponUltimateChargeRequired,
    required this.hasWeaponUltimate,
  });

  final int hp;
  final int maxHp;
  final int exp;
  final int requiredExp;
  final int level;
  final String stageName;
  final int stageChapter;
  final int stageIndex;
  final int elapsedSeconds;
  final int killCount;
  final int maxBattleSeconds;
  final int coins;
  final int stageEnemyCount;
  final int bossTimeSeconds;
  final bool isBossSpawned;
  final int ultimateCharge;
  final int ultimateChargeRequired;
  final int weaponUltimateCharge;
  final int weaponUltimateChargeRequired;
  final bool hasWeaponUltimate;

  int get bossSecondsRemaining {
    return (bossTimeSeconds - elapsedSeconds).clamp(0, bossTimeSeconds);
  }

  bool get isBossFight => isBossSpawned;

  bool get isUltimateReady => ultimateCharge >= ultimateChargeRequired;

  bool get isWeaponUltimateReady =>
      hasWeaponUltimate && weaponUltimateCharge >= weaponUltimateChargeRequired;

  double get ultimateChargeProgress {
    if (ultimateChargeRequired <= 0) {
      return 0;
    }
    return (ultimateCharge / ultimateChargeRequired).clamp(0, 1).toDouble();
  }

  double get weaponUltimateChargeProgress {
    if (weaponUltimateChargeRequired <= 0) {
      return 0;
    }
    return (weaponUltimateCharge / weaponUltimateChargeRequired)
        .clamp(0, 1)
        .toDouble();
  }

  double get enemyProgress {
    if (stageEnemyCount <= 0) {
      return 0;
    }
    return (killCount / stageEnemyCount).clamp(0, 1).toDouble();
  }

  static const empty = HudSnapshot(
    hp: 100,
    maxHp: 100,
    exp: 0,
    requiredExp: 10,
    level: 1,
    stageName: 'Chapter 1-1',
    stageChapter: 1,
    stageIndex: 1,
    elapsedSeconds: 0,
    killCount: 0,
    maxBattleSeconds: 300,
    coins: 0,
    stageEnemyCount: 100,
    bossTimeSeconds: 300,
    isBossSpawned: false,
    ultimateCharge: 0,
    ultimateChargeRequired: 10,
    weaponUltimateCharge: 0,
    weaponUltimateChargeRequired: 8,
    hasWeaponUltimate: false,
  );
}
