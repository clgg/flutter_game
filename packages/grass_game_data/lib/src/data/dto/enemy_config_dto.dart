class EnemyConfigDto {
  const EnemyConfigDto({
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

  factory EnemyConfigDto.fromJson(Map<String, dynamic> json) {
    return EnemyConfigDto(
      id: json['id'] as String,
      hp: json['hp'] as int,
      moveSpeed: (json['moveSpeed'] as num).toDouble(),
      expDrop: json['expDrop'] as int,
      meleeDamageMin: json['meleeDamageMin'] as int? ?? 6,
      meleeDamageMax: json['meleeDamageMax'] as int? ?? 9,
    );
  }
}
