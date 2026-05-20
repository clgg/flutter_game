enum WeaponFamily {
  melee('近战', 3),
  projectile('投射', 3),
  firearm('枪械', 4),
  energy('能量', 5),
  explosive('爆破', 5),
  control('控制', 4);

  const WeaponFamily(this.label, this.defaultStars);

  final String label;
  final int defaultStars;
}

enum WeaponAttackPattern {
  meleeSweep('扇形扫击'),
  projectile('直线弹'),
  bouncingProjectile('弹跳弹'),
  boomerang('回旋'),
  coneShot('扇形散射'),
  beam('光束'),
  lobbedExplosion('抛物爆炸'),
  chainLightning('链式电击'),
  flameStream('火焰喷射'),
  orbitSlash('环绕切割');

  const WeaponAttackPattern(this.label);

  final String label;
}

enum WeaponObtainType {
  free('免费'),
  shop('购买'),
  craft('合成'),
  ultimateCraft('终局合成');

  const WeaponObtainType(this.label);

  final String label;
}

class WeaponUpgradeCurve {
  const WeaponUpgradeCurve({
    required this.damageGrowth,
    required this.speedGrowth,
    required this.rangeGrowth,
    this.costMultiplier = 1,
  });

  final double damageGrowth;
  final double speedGrowth;
  final double rangeGrowth;
  final double costMultiplier;

  static const melee = WeaponUpgradeCurve(
    damageGrowth: 0.10,
    speedGrowth: 0.03,
    rangeGrowth: 0.03,
  );

  static const projectile = WeaponUpgradeCurve(
    damageGrowth: 0.08,
    speedGrowth: 0.05,
    rangeGrowth: 0.02,
  );

  static const firearm = WeaponUpgradeCurve(
    damageGrowth: 0.07,
    speedGrowth: 0.07,
    rangeGrowth: 0.01,
  );

  static const energy = WeaponUpgradeCurve(
    damageGrowth: 0.09,
    speedGrowth: 0.04,
    rangeGrowth: 0.03,
  );

  static const explosive = WeaponUpgradeCurve(
    damageGrowth: 0.12,
    speedGrowth: 0.02,
    rangeGrowth: 0.04,
  );

  static const control = WeaponUpgradeCurve(
    damageGrowth: 0.06,
    speedGrowth: 0.04,
    rangeGrowth: 0.04,
  );

  static const ultimate = WeaponUpgradeCurve(
    damageGrowth: 0.12,
    speedGrowth: 0.02,
    rangeGrowth: 0.04,
    costMultiplier: 1.15,
  );
}

class WeaponRecipe {
  const WeaponRecipe({
    required this.materialWeaponIds,
    required this.craftCost,
  });

  final List<String> materialWeaponIds;
  final int craftCost;
}

class WeaponDefinition {
  const WeaponDefinition({
    required this.id,
    required this.name,
    required this.family,
    required this.attackPattern,
    required this.buyCost,
    required this.baseDamage,
    required this.attacksPerSecond,
    required this.range,
    required this.areaRadius,
    required this.pierce,
    required this.knockback,
    required this.effectId,
    required this.upgradeCurve,
    required this.obtainType,
    required this.iconAssetPath,
    required this.muzzleFlashAssetPath,
    required this.projectileAssetPath,
    required this.fireSoundAssetPath,
    this.recipe,
    this.recommendedCharacterIds = const [],
    this.description = '',
    this.baseColorValue = 0xFF8FE388,
    this.maxLevel = 10,
    this.wikiImageUrl = '',
  });

  final String id;
  final String name;
  final WeaponFamily family;
  final WeaponAttackPattern attackPattern;
  final int buyCost;
  final int baseDamage;
  final double attacksPerSecond;
  final double range;
  final double areaRadius;
  final int pierce;
  final double knockback;
  final String effectId;
  final WeaponUpgradeCurve upgradeCurve;
  final WeaponObtainType obtainType;
  final WeaponRecipe? recipe;
  final List<String> recommendedCharacterIds;
  final String description;
  final int baseColorValue;
  final int maxLevel;
  final String wikiImageUrl;
  final String iconAssetPath;
  final String muzzleFlashAssetPath;
  final String projectileAssetPath;
  final String fireSoundAssetPath;

  String get kind => family.label;

  String get country => obtainType.label;

  String get unlockMethod => recipe == null ? obtainType.label : '配方合成';

  String get fireMode => attackPattern.label;

  int get maxStars {
    if (obtainType == WeaponObtainType.ultimateCraft) {
      return 6;
    }
    if (obtainType == WeaponObtainType.craft) {
      return 5;
    }
    return family.defaultStars;
  }

  int get damage => baseDamage;

  int get fireRateRoundsPerMinute => (attacksPerSecond * 60).round();

  bool get isCraftWeapon =>
      obtainType == WeaponObtainType.craft ||
      obtainType == WeaponObtainType.ultimateCraft;
}
