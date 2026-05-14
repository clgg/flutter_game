class EnemyConfigDto {
  const EnemyConfigDto({
    required this.id,
    required this.hp,
    required this.moveSpeed,
    required this.expDrop,
  });

  final String id;
  final int hp;
  final double moveSpeed;
  final int expDrop;

  factory EnemyConfigDto.fromJson(Map<String, dynamic> json) {
    return EnemyConfigDto(
      id: json['id'] as String,
      hp: json['hp'] as int,
      moveSpeed: (json['moveSpeed'] as num).toDouble(),
      expDrop: json['expDrop'] as int,
    );
  }
}
