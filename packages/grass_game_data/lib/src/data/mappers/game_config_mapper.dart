import 'package:grass_game_domain/grass_game_domain.dart';

import '../dto/game_config_dto.dart';

class GameConfigMapper {
  const GameConfigMapper();

  GrassGameConfig toDomain(GameConfigDto dto) {
    final enemies = dto.enemies
        .map(
          (enemy) => EnemyConfig(
            id: enemy.id,
            hp: enemy.hp,
            moveSpeed: enemy.moveSpeed,
            expDrop: enemy.expDrop,
            meleeDamageMin: enemy.meleeDamageMin,
            meleeDamageMax: enemy.meleeDamageMax,
          ),
        )
        .toList();

    return GrassGameConfig(
      version: dto.version,
      balance: GameBalance.defaults,
      enemies: enemies.isEmpty ? GrassGameConfig.defaults.enemies : enemies,
      skills: GrassGameConfig.defaults.skills,
      waves: GrassGameConfig.defaults.waves,
    );
  }
}
