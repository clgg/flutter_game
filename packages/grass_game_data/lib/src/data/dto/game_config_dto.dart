import 'enemy_config_dto.dart';

class GameConfigDto {
  const GameConfigDto({
    required this.version,
    required this.enemies,
  });

  final int version;
  final List<EnemyConfigDto> enemies;

  factory GameConfigDto.fromJson(Map<String, dynamic> json) {
    final enemiesJson = json['enemies'] as List<dynamic>? ?? const [];

    return GameConfigDto(
      version: json['version'] as int? ?? 1,
      enemies: enemiesJson
          .whereType<Map<String, dynamic>>()
          .map(EnemyConfigDto.fromJson)
          .toList(),
    );
  }
}
