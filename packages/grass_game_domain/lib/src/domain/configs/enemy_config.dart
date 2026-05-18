class EnemyConfig {
  const EnemyConfig({
    required this.id,
    required this.hp,
    required this.moveSpeed,
    required this.expDrop,
    required this.meleeDamageMin,
    required this.meleeDamageMax,
  });

  final String id;
  final int hp;
  final double moveSpeed;
  final int expDrop;
  final int meleeDamageMin;
  final int meleeDamageMax;
}
