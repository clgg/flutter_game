class EnemyConfig {
  const EnemyConfig({
    required this.id,
    required this.hp,
    required this.moveSpeed,
    required this.expDrop,
  });

  final String id;
  final int hp;
  final double moveSpeed;
  final int expDrop;
}
