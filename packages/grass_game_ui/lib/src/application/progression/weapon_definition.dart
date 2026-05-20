class WeaponDefinition {
  const WeaponDefinition({
    required this.id,
    required this.name,
    required this.kind,
    required this.buyCost,
    required this.baseColorValue,
    required this.country,
    required this.unlockMethod,
    required this.maxStars,
    required this.fireMode,
    required this.fireRateRoundsPerMinute,
    required this.damage,
    required this.wikiImageUrl,
    this.iconAssetPath,
    this.muzzleFlashAssetPath,
    this.projectileAssetPath,
    required this.fireSoundAssetPath,
  });

  final String id;
  final String name;
  final String kind;
  final int buyCost;
  final int baseColorValue;
  final String country;
  final String unlockMethod;
  final int maxStars;
  final String fireMode;
  final int fireRateRoundsPerMinute;
  final int damage;
  final String wikiImageUrl;
  final String? iconAssetPath;
  final String? muzzleFlashAssetPath;
  final String? projectileAssetPath;
  final String fireSoundAssetPath;
}
