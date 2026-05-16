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
      EnemyConfig(id: 'basic', hp: 3, moveSpeed: 64, expDrop: 1),
      EnemyConfig(id: 'fast', hp: 2, moveSpeed: 96, expDrop: 3),
      EnemyConfig(id: 'tank', hp: 9, moveSpeed: 42, expDrop: 5),
    ],
    skills: [
      SkillConfig(id: 'arrow', weight: 100, maxLevel: 5),
      SkillConfig(id: 'might', weight: 80, maxLevel: 5),
      SkillConfig(id: 'haste', weight: 80, maxLevel: 5),
      SkillConfig(id: 'boots', weight: 70, maxLevel: 5),
      SkillConfig(id: 'magnet', weight: 70, maxLevel: 5),
    ],
    waves: [
      WaveConfig(
        startSecond: 0,
        enemyId: 'basic',
        spawnIntervalSeconds: 1.2,
      ),
      WaveConfig(
        startSecond: 30,
        enemyId: 'fast',
        spawnIntervalSeconds: 0.95,
      ),
      WaveConfig(
        startSecond: 75,
        enemyId: 'tank',
        spawnIntervalSeconds: 1.6,
      ),
    ],
  );
}
