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
      EnemyConfig(id: 'basic', hp: 3, moveSpeed: 148, expDrop: 2),
      EnemyConfig(id: 'lamb', hp: 2, moveSpeed: 168, expDrop: 2),
      EnemyConfig(id: 'piglet', hp: 4, moveSpeed: 133, expDrop: 2),
      EnemyConfig(id: 'calf', hp: 5, moveSpeed: 153, expDrop: 3),
      EnemyConfig(id: 'fast', hp: 2, moveSpeed: 198, expDrop: 3),
      EnemyConfig(id: 'rooster', hp: 3, moveSpeed: 183, expDrop: 3),
      EnemyConfig(id: 'turkey', hp: 6, moveSpeed: 143, expDrop: 4),
      EnemyConfig(id: 'tank', hp: 9, moveSpeed: 108, expDrop: 6),
    ],
    skills: [
      SkillConfig(
        id: 'star_projectile',
        treeId: 'star_projectile',
        weight: 100,
        maxLevel: 5,
      ),
      SkillConfig(
        id: 'orbit_blade',
        treeId: 'orbit_blade',
        weight: 100,
        maxLevel: 5,
      ),
      SkillConfig(
        id: 'thunder_matrix',
        treeId: 'thunder_matrix',
        weight: 100,
        maxLevel: 5,
      ),
      SkillConfig(
        id: 'void_magnet',
        treeId: 'void_magnet',
        weight: 100,
        maxLevel: 5,
      ),
      SkillConfig(
        id: 'ice_nova',
        treeId: 'ice_nova',
        weight: 100,
        maxLevel: 5,
      ),
      SkillConfig(
        id: 'fire_trail',
        treeId: 'fire_trail',
        weight: 100,
        maxLevel: 5,
      ),
      SkillConfig(
        id: 'poison_spore',
        treeId: 'poison_spore',
        weight: 90,
        maxLevel: 5,
      ),
      SkillConfig(
        id: 'evolve_star_barrage',
        treeId: 'star_projectile',
        tier: SkillTier.evolution,
        weight: 140,
        maxLevel: 1,
        requires: ['star_projectile'],
      ),
      SkillConfig(
        id: 'evolve_moon_wheel',
        treeId: 'orbit_blade',
        tier: SkillTier.evolution,
        weight: 140,
        maxLevel: 1,
        requires: ['orbit_blade'],
      ),
      SkillConfig(
        id: 'evolve_thunder_chain',
        treeId: 'thunder_matrix',
        tier: SkillTier.evolution,
        weight: 140,
        maxLevel: 1,
        requires: ['thunder_matrix'],
      ),
      SkillConfig(
        id: 'evolve_black_hole',
        treeId: 'void_magnet',
        tier: SkillTier.evolution,
        weight: 140,
        maxLevel: 1,
        requires: ['void_magnet'],
      ),
      SkillConfig(
        id: 'evolve_permafrost_field',
        treeId: 'ice_nova',
        tier: SkillTier.evolution,
        weight: 140,
        maxLevel: 1,
        requires: ['ice_nova'],
      ),
      SkillConfig(
        id: 'evolve_inferno_path',
        treeId: 'fire_trail',
        tier: SkillTier.evolution,
        weight: 140,
        maxLevel: 1,
        requires: ['fire_trail'],
      ),
      SkillConfig(
        id: 'evolve_corrosive_plague',
        treeId: 'poison_spore',
        tier: SkillTier.evolution,
        weight: 140,
        maxLevel: 1,
        requires: ['poison_spore'],
      ),
      SkillConfig(
        id: 'ultimate_star_judgement',
        tier: SkillTier.ultimate,
        weight: 160,
        maxLevel: 1,
        requires: ['evolve_star_barrage', 'evolve_thunder_chain'],
      ),
      SkillConfig(
        id: 'ultimate_black_moon',
        tier: SkillTier.ultimate,
        weight: 160,
        maxLevel: 1,
        requires: ['evolve_moon_wheel', 'evolve_black_hole'],
      ),
      SkillConfig(
        id: 'ultimate_frost_inferno',
        tier: SkillTier.ultimate,
        weight: 150,
        maxLevel: 1,
        requires: ['evolve_permafrost_field', 'evolve_inferno_path'],
      ),
    ],
    waves: [
      WaveConfig(
        startSecond: 0,
        enemyId: 'basic',
        spawnIntervalSeconds: 0.75,
      ),
      WaveConfig(
        startSecond: 30,
        enemyId: 'fast',
        spawnIntervalSeconds: 0.55,
      ),
      WaveConfig(
        startSecond: 75,
        enemyId: 'tank',
        spawnIntervalSeconds: 0.95,
      ),
    ],
  );
}
