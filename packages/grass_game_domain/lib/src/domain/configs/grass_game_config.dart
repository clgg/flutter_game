import 'enemy_config.dart';
import 'game_balance.dart';
import 'skill_config.dart';
import 'wave_config.dart';

class GrassGameConfig {
  const GrassGameConfig({
    required this.version,
    required this.balance,
    required this.enemies,
    required this.skills,
    required this.waves,
  });

  final int version;
  final GameBalance balance;
  final List<EnemyConfig> enemies;
  final List<SkillConfig> skills;
  final List<WaveConfig> waves;

  static const defaults = GrassGameConfig(
    version: 1,
    balance: GameBalance.defaults,
    enemies: [
      EnemyConfig(id: 'basic', hp: 3, moveSpeed: 60, expDrop: 1),
    ],
    skills: [
      SkillConfig(id: 'arrow', weight: 100, maxLevel: 5),
    ],
    waves: [
      WaveConfig(
        startSecond: 0,
        enemyId: 'basic',
        spawnIntervalSeconds: 1.2,
      ),
    ],
  );
}
