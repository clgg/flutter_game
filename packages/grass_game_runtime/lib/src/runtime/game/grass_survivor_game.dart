import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

import '../components/companion_component.dart';
import '../components/enemy_component.dart';
import '../components/exp_gem_component.dart';
import '../components/muzzle_flash_component.dart';
import '../components/player_component.dart';
import '../components/projectile_component.dart';
import '../snapshots/hud_snapshot.dart';
import 'grass_game_runtime_controller.dart';
import 'grass_game_runtime_state.dart';

class WeaponRuntimeStats {
  const WeaponRuntimeStats({
    required this.weaponId,
    required this.attackPattern,
    required this.damage,
    required this.attacksPerSecond,
    required this.range,
    required this.areaRadius,
    required this.pierce,
    required this.knockback,
    required this.effectId,
  });

  final String weaponId;
  final String attackPattern;
  final int damage;
  final double attacksPerSecond;
  final double range;
  final double areaRadius;
  final int pierce;
  final double knockback;
  final String effectId;
}

class GrassSurvivorGame extends FlameGame {
  GrassSurvivorGame({
    required this.config,
    required this.controller,
    this.playerMaxHp = 100,
    this.playerMoveSpeedMultiplier = 1,
    this.playerCharacterId = 'runner',
    this.playerSpriteSheetAssetPath =
        'assets/game/grass_game/images/player/player_02_walk_8dir_sheet.png',
    this.weaponDamage = 1,
    this.weaponCooldownMultiplier = 1,
    this.weaponFireIntervalSeconds = 0.8,
    this.weaponKind = '步枪',
    this.weaponProjectileAssetPath,
    this.weaponMuzzleFlashAssetPath,
    this.weaponFireSoundAssetPath,
    this.weaponRuntimeStats,
    this.soundVolume = 1,
    this.vibrationIntensity = 1,
    this.stageName = 'Chapter 1-1',
    this.stageChapter = 1,
    this.stageIndex = 1,
    this.bossId = 'random_guaishou',
    this.bossTimeSeconds = 300,
    this.bossMaxHp = 420,
    this.stageRewardExp = 0,
    this.stageRewardCoins = 0,
    this.stageEnemyCount = 100,
    this.stageEnemyStrengthMultiplier = 1,
    this.stageEnemyTypes = const ['basic', 'fast', 'tank'],
    this.stageBackgroundAssetPath,
    this.isDeathmatch = false,
  })  : _stageMapTheme = _StageMapTheme.forChapter(stageChapter),
        state = GrassGameRuntimeState.initial(
          configVersion: config.version,
        );

  final GrassGameConfig config;
  final GrassGameRuntimeController controller;
  final int playerMaxHp;
  final double playerMoveSpeedMultiplier;
  final String playerCharacterId;
  final String playerSpriteSheetAssetPath;
  final int weaponDamage;
  final double weaponCooldownMultiplier;
  final double weaponFireIntervalSeconds;
  final String weaponKind;
  final String? weaponProjectileAssetPath;
  final String? weaponMuzzleFlashAssetPath;
  final String? weaponFireSoundAssetPath;
  final WeaponRuntimeStats? weaponRuntimeStats;
  final double soundVolume;
  final double vibrationIntensity;
  final String stageName;
  final int stageChapter;
  final int stageIndex;
  final String bossId;
  final int bossTimeSeconds;
  final int bossMaxHp;
  final int stageRewardExp;
  final int stageRewardCoins;
  final int stageEnemyCount;
  final double stageEnemyStrengthMultiplier;
  final List<String> stageEnemyTypes;
  final String? stageBackgroundAssetPath;
  final bool isDeathmatch;
  GrassGameRuntimeState state;
  String languageCode = 'en';

  static const supportedWeaponAttackPatterns = <String>{
    'meleeSweep',
    'projectile',
    'bouncingProjectile',
    'boomerang',
    'coneShot',
    'beam',
    'lobbedExplosion',
    'chainLightning',
    'flameStream',
    'orbitSlash',
  };

  static const _fireEffectGrid = _EffectFrameGrid(columns: 6, rows: 6);
  static const _iceEffectGrid = _EffectFrameGrid(columns: 6, rows: 5);
  static const _thunderEffectGrid = _EffectFrameGrid(columns: 6, rows: 5);
  static const _poisonEffectGrid = _EffectFrameGrid(columns: 6, rows: 5);
  static const _blackHoleEffectGrid = _EffectFrameGrid(columns: 6, rows: 5);
  static const _orbitBladeEffectGrid = _EffectFrameGrid(columns: 8, rows: 1);
  static const _ultimateBeamEffectGrid = _EffectFrameGrid(columns: 8, rows: 1);

  late final PlayerComponent player;

  final math.Random _random = math.Random();
  final List<EnemyComponent> _enemies = [];
  final List<ProjectileComponent> _projectiles = [];
  final List<ExpGemComponent> _gems = [];
  final Map<(int, int), List<EnemyComponent>> _enemyCells = {};
  final List<EnemyComponent> _deadEnemyBuffer = [];
  final List<ProjectileComponent> _removedProjectileBuffer = [];
  final List<EnemyComponent> _removedEnemyBuffer = [];
  final List<ExpGemComponent> _collectedGemBuffer = [];
  final List<ExpGemComponent> _expiredGemBuffer = [];
  final List<_BlackHoleField> _finishedBlackHoleBuffer = [];
  final Map<String, EnemyAnimationSet> _enemyAnimations = {};
  late final List<_CompanionRuntimeVariant> _shadowGuardVariants;
  late final PlayerAnimationSet _playerAnimation;
  late final DropIconSet _dropIcons;
  Image? _fireEffectImage;
  Image? _iceEffectImage;
  Image? _thunderEffectImage;
  Image? _poisonEffectImage;
  Image? _blackHoleEffectImage;
  Image? _orbitBladeEffectImage;
  Image? _ultimateBeamEffectImage;
  Image? _projectileImage;
  Image? _muzzleFlashImage;
  Image? _stageBackgroundImage;
  final Map<String, Image> _obstacleImages = {};
  String? _fireSoundFileName;
  AudioPool? _fireAudioPool;
  final List<StopFunction> _activeFireSoundStops = [];
  final _StageMapTheme _stageMapTheme;

  final Paint _backgroundPaint = Paint()..color = const Color(0xFF183622);
  final Paint _groundPaint = Paint()..color = const Color(0xFF1F472D);
  final Paint _groundAltPaint = Paint()..color = const Color(0xFF234E32);
  final Paint _fieldLinePaint = Paint()
    ..color = const Color(0x183B7A4D)
    ..strokeWidth = 1;
  final Paint _stageBackgroundPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.low;
  final Paint _obstacleImagePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;
  final Paint _stageTintPaint = Paint();
  final Paint _obstaclePaint = Paint()..isAntiAlias = true;
  final Paint _obstacleStrokePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _spawnZonePaint = Paint()
    ..color = const Color(0x1AFFD36E)
    ..style = PaintingStyle.fill;
  final Paint _spawnZoneStrokePaint = Paint()
    ..color = const Color(0x66FFD36E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static const double _attackRange = 260 * 0.8;
  static const double _enemyGridCellSize = 96;
  static const double _waveRuntimeIntervalMultiplier = 0.35;
  static const double _enemySpeedBaseMultiplier = 0.9;
  static const double _enemySpeedStrengthScale = 0.07;
  static const double _enemySpeedGrowthCap = 1.35;
  static const double _spawnZoneInitialRadius = 86;
  static const double _spawnZoneShrinkStartSeconds = 3;
  static const double _spawnZoneDisappearSeconds = 5;
  static const int _deathmatchInitialLevelUps = 5;
  static const int _chargedUltimateRequiredCharge = 10;
  static const int _weaponUltimateRequiredCharge = 8;
  static const double _expHighDropChance = 0.14;
  static const double _expRareDropChance = 0.04;
  static const double _basicCoinDropChance = 0.18;
  static const double _fastCoinDropChance = 0.24;
  static const double _tankCoinDropChance = 0.40;
  static const int _bossCoinDropMin = 40;
  static const int _bossCoinDropMax = 80;
  static const double _deathmatchRareCoinDropChance = 0.18;
  static const double _deathmatchHighCoinDropChance = 0.44;
  static const int _healthPackHealAmount = 50;
  static const double _basicHealthPackDropChance = 0.045;
  static const double _fastHealthPackDropChance = 0.055;
  static const double _tankHealthPackDropChance = 0.08;
  static const double _deathmatchHealthPackDropChance = 0.10;
  static const double _starProjectileDamageMultiplier = 0.42;
  static const double _starBarrageDamageMultiplier = 0.62;
  static const double _orbitBladeDamageMultiplier = 0.36;
  static const double _orbitBladeLevel5DamageMultiplier = 0.48;
  static const double _thunderMainDamageMultiplier = 1.50;
  static const double _thunderChainDamageMultiplier = 0.62;
  static const double _voidPickupDamageMultiplier = 0.35;
  static const double _blackHoleDamageMultiplier = 0.50;
  static const double _blackHoleExplosionDamageMultiplier = 1.70;
  static const double _blackMoonDamageMultiplier = 0.70;
  static const double _blackMoonExplosionDamageMultiplier = 3.40;

  double _elapsed = 0;
  double _spawnTimer = 0;
  double _weaponTimer = 0;
  double _hudTimer = 0;
  int _killCount = 0;
  int _level = 1;
  int _exp = 0;
  int _coins = 0;
  int _pendingLevelUps = 0;
  int _levelUpRerollOffset = 0;
  late int _weaponDamage = weaponRuntimeStats?.damage ?? weaponDamage;
  late double _cooldownMultiplier = weaponCooldownMultiplier;
  late double _weaponRange = weaponRuntimeStats?.range ?? _attackRange;
  late double _weaponAreaRadius = weaponRuntimeStats?.areaRadius ?? 0;
  late int _weaponPierce = weaponRuntimeStats?.pierce ?? 0;
  bool _finished = false;
  bool _bossSpawned = false;
  bool _bossWarningShown = false;
  double _damageFlashTimer = 0;
  double _levelFlashTimer = 0;
  double _bossBannerTimer = 0;
  double _finishFlashTimer = 0;
  final List<_WorldPulse> _worldPulses = [];
  final Map<String, int> _skillLevels = {};
  final Set<String> _evolvedSkills = {};
  final List<_ThunderStrike> _thunderStrikes = [];
  final List<_BlackHoleField> _blackHoles = [];
  final List<_GroundEffectField> _groundFields = [];
  final List<_ExpandingRing> _expandingRings = [];
  final List<_ChargedUltimateBeam> _chargedUltimateBeams = [];
  final List<_WeaponUltimateImage> _weaponUltimateImages = [];
  final List<_DelayedWeaponBlast> _delayedWeaponBlasts = [];
  final List<_MeleeSweepEffect> _meleeSweeps = [];
  final List<CompanionComponent> _companions = [];
  final Set<EnemyComponent> _poisonedEnemies = {};
  final List<_GroundEffectField> _expiredGroundFieldBuffer = [];
  final List<CompanionComponent> _expiredCompanionBuffer = [];
  String? _ultimateSkillId;
  int _attackCount = 0;
  int _voidPickupCount = 0;
  double _orbitAngle = 0;
  double _orbitHitTimer = 0;
  double _moonWheelTimer = 0;
  double _thunderTimer = 0;
  double _fireTrailTimer = 0;
  double _iceNovaTimer = 0;
  double _poisonSporeTimer = 0;
  double _shadowGuardSummonTimer = 0;
  double _starJudgementCooldown = 10;
  double _starJudgementTimer = 0;
  double _starJudgementTick = 0;
  double _blackMoonCooldown = 12;
  double _frostInfernoCooldown = 14;
  double _frostInfernoTimer = 0;
  double _frostInfernoTick = 0;
  double _lastFireSoundAt = -100;
  double _gemMaintenanceTimer = 0;
  double _enemySeparationTimer = 0;
  int _chargedUltimateCharge = 0;
  int _weaponUltimateCharge = 0;
  Vector2 _lastAimDirection = Vector2(0, 1);
  int _deathmatchBuffTier = 0;
  bool _isReleased = false;

  static const int _maxLiveEnemies = 180;
  static const int _maxDeathmatchLiveEnemies = 240;
  static const int _maxGemCount = 96;
  static const int _maxGroundFieldCount = 36;
  static const int _softGemMergeCount = 56;
  static const double _gemMergeRadius = 42;
  static const double _gemMaxAgeSeconds = 14;
  static const Map<String, String> _guaishouSpriteSheets = {
    'guaishou_black_armored_beetle':
        'assets/game/grass_game/images/guaishou/guaishou_black_armored_beetle_walk_8dir_sheet.webp',
    'guaishou_black_white_armor':
        'assets/game/grass_game/images/guaishou/guaishou_black_white_armor_walk_8dir_sheet.webp',
    'guaishou_blue_antenna_alien':
        'assets/game/grass_game/images/guaishou/guaishou_blue_antenna_alien_walk_8dir_sheet.webp',
    'guaishou_gold_snail_mouth':
        'assets/game/grass_game/images/guaishou/guaishou_gold_snail_mouth_walk_8dir_sheet.webp',
    'guaishou_gray_block_head':
        'assets/game/grass_game/images/guaishou/guaishou_gray_block_head_walk_8dir_sheet.webp',
    'guaishou_horned_brute':
        'assets/game/grass_game/images/guaishou/guaishou_horned_brute_walk_8dir_sheet.webp',
    'guaishou_insect_claw':
        'assets/game/grass_game/images/guaishou/guaishou_insect_claw_walk_8dir_sheet.webp',
    'guaishou_red_gold_spear_alien':
        'assets/game/grass_game/images/guaishou/guaishou_red_gold_spear_alien_walk_8dir_sheet.webp',
    'guaishou_shell_kaiju':
        'assets/game/grass_game/images/guaishou/guaishou_shell_kaiju_walk_8dir_sheet.webp',
    'guaishou_silver_mask_rifle':
        'assets/game/grass_game/images/guaishou/guaishou_silver_mask_rifle_walk_8dir_sheet.webp',
    'guaishou_spiked_mane_beast':
        'assets/game/grass_game/images/guaishou/guaishou_spiked_mane_beast_walk_8dir_sheet.webp',
    'guaishou_winged_dragon':
        'assets/game/grass_game/images/guaishou/guaishou_winged_dragon_walk_8dir_sheet.webp',
  };
  static const Map<String, String> _bossSpriteSheets = {
    'guaishou_cyber_crocodile_boss':
        'assets/game/grass_game/images/guaishou/guaishou_cyber_crocodile_boss_walk_8dir_sheet.png',
    'guaishou_highway_juggernaut_boss':
        'assets/game/grass_game/images/guaishou/guaishou_highway_juggernaut_boss_walk_8dir_sheet.png',
    'guaishou_city_core_guardian_boss':
        'assets/game/grass_game/images/guaishou/guaishou_city_core_guardian_boss_walk_8dir_sheet.png',
    'guaishou_cave_crystal_brute_boss':
        'assets/game/grass_game/images/guaishou/guaishou_cave_crystal_brute_boss_walk_8dir_sheet.png',
    'guaishou_forest_spore_titan_boss':
        'assets/game/grass_game/images/guaishou/guaishou_forest_spore_titan_boss_walk_8dir_sheet.png',
    'guaishou_ocean_shell_leviathan_boss':
        'assets/game/grass_game/images/guaishou/guaishou_ocean_shell_leviathan_boss_walk_8dir_sheet.png',
    'guaishou_infected_plague_beetle_boss':
        'assets/game/grass_game/images/guaishou/guaishou_infected_plague_beetle_boss_walk_8dir_sheet.png',
    'guaishou_bone_wasteland_reaper_boss':
        'assets/game/grass_game/images/guaishou/guaishou_bone_wasteland_reaper_boss_walk_8dir_sheet.png',
    'guaishou_alien_landing_overlord_boss':
        'assets/game/grass_game/images/guaishou/guaishou_alien_landing_overlord_boss_walk_8dir_sheet.png',
    'guaishou_cosmic_rift_dragon_boss':
        'assets/game/grass_game/images/guaishou/guaishou_cosmic_rift_dragon_boss_walk_8dir_sheet.png',
  };
  static const Map<String, String> _animalSpriteSheets = {
    'basic':
        'assets/game/grass_game/images/animals/runtime/animal_chick_walk_sheet_runtime_128.png',
    'chick':
        'assets/game/grass_game/images/animals/runtime/animal_chick_walk_sheet_runtime_128.png',
    'lamb':
        'assets/game/grass_game/images/animals/runtime/animal_lamb_walk_sheet_runtime_128.png',
    'piglet':
        'assets/game/grass_game/images/animals/runtime/animal_piglet_walk_sheet_runtime_128.png',
    'calf':
        'assets/game/grass_game/images/animals/runtime/animal_calf_walk_sheet_runtime_128.png',
    'fast':
        'assets/game/grass_game/images/animals/runtime/animal_rooster_walk_sheet_runtime_128.png',
    'rooster':
        'assets/game/grass_game/images/animals/runtime/animal_rooster_walk_sheet_runtime_128.png',
    'dog':
        'assets/game/grass_game/images/animals/runtime/animal_dog_walk_sheet_runtime_128.png',
    'turkey':
        'assets/game/grass_game/images/animals/runtime/animal_turkey_walk_sheet_runtime_128.png',
    'sheep':
        'assets/game/grass_game/images/animals/runtime/animal_sheep_walk_sheet_runtime_128.png',
    'tank':
        'assets/game/grass_game/images/animals/runtime/animal_bull_walk_sheet_runtime_128.png',
    'bull':
        'assets/game/grass_game/images/animals/runtime/animal_bull_walk_sheet_runtime_128.png',
  };

  @override
  Color backgroundColor() => const Color(0xFF102418);

  int get _maxLiveEnemyCount =>
      isDeathmatch ? _maxDeathmatchLiveEnemies : _maxLiveEnemies;

  int get _currentDeathmatchBuffTier {
    if (!isDeathmatch) {
      return 0;
    }
    return (_elapsed ~/ 60).clamp(0, 10);
  }

  double get _deathmatchStrengthMultiplier =>
      math.pow(1.1, _currentDeathmatchBuffTier).toDouble();

  double get _deathmatchSizeMultiplier =>
      _deathmatchSizeMultiplierForTier(_currentDeathmatchBuffTier);

  double _deathmatchSizeMultiplierForTier(int tier) {
    final clampedTier = tier.clamp(0, 10).toInt();
    if (clampedTier >= 9) {
      return 1.5;
    }
    return 1 + clampedTier * 0.05;
  }

  double get _deathmatchEnemySize => 104 * _deathmatchSizeMultiplier;

  double get _deathmatchEnemyCollisionRadius => 28 * _deathmatchSizeMultiplier;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _applyStageTheme();
    await _loadStageBackground();
    await _loadObstacleImages();
    await _loadPlayerAnimation();
    await _loadEnemyAnimations();
    await _loadCompanionAnimations();
    await _loadDropIcons();
    await _loadSkillEffectImages();
    await _loadWeaponEffects();
    controller.start();
    if (isDeathmatch) {
      _pendingLevelUps = _deathmatchInitialLevelUps;
      controller.setPendingLevelUps(_pendingLevelUps);
    }

    player = PlayerComponent(
      controller: controller,
      moveSpeed: config.balance.playerMoveSpeed * playerMoveSpeedMultiplier,
      maxHp: playerMaxHp,
      animationSet: _playerAnimation,
    );

    await add(player);
    _syncHud(force: true);
  }

  void _applyStageTheme() {
    _backgroundPaint.color = _stageMapTheme.screenBackground;
    _groundPaint.color = _stageMapTheme.ground;
    _groundAltPaint.color = _stageMapTheme.groundAlt;
    _fieldLinePaint.color = _stageMapTheme.gridLine;
  }

  Future<void> _loadStageBackground() async {
    final assetPath = stageBackgroundAssetPath;
    if (assetPath == null || assetPath.isEmpty) {
      return;
    }
    _stageBackgroundImage = await _loadImage(assetPath);
  }

  Future<void> _loadObstacleImages() async {
    final assetPaths = _stageMapTheme.obstacles
        .map((obstacle) => obstacle.assetPath)
        .whereType<String>()
        .toSet();
    for (final assetPath in assetPaths) {
      try {
        _obstacleImages[assetPath] = await _loadImage(assetPath);
      } on Object {
        // Keep the colored rectangle fallback if a prop asset is absent.
      }
    }
  }

  void releaseRuntimeResources() {
    if (_isReleased) {
      return;
    }
    _isReleased = true;
    pauseEngine();
    removeAll(children.toList());
    final fireAudioPool = _fireAudioPool;
    _fireAudioPool = null;
    final activeFireSoundStops = List<StopFunction>.of(_activeFireSoundStops);
    _activeFireSoundStops.clear();
    if (fireAudioPool != null) {
      unawaited(
        Future.wait(activeFireSoundStops.map((stop) => stop()))
            .whenComplete(fireAudioPool.dispose),
      );
    }
    _enemies.clear();
    _projectiles.clear();
    _gems.clear();
    _enemyCells.clear();
    _deadEnemyBuffer.clear();
    _removedProjectileBuffer.clear();
    _removedEnemyBuffer.clear();
    _collectedGemBuffer.clear();
    _expiredGemBuffer.clear();
    _finishedBlackHoleBuffer.clear();
    _worldPulses.clear();
    _thunderStrikes.clear();
    _blackHoles.clear();
    _chargedUltimateBeams.clear();
    _weaponUltimateImages.clear();
    _delayedWeaponBlasts.clear();
    _meleeSweeps.clear();
    _companions.clear();
    _obstacleImages.clear();
  }

  Future<void> _loadPlayerAnimation() async {
    _playerAnimation = PlayerAnimationSet(
      image: await _loadImage(playerSpriteSheetAssetPath),
      displaySize: Vector2.all(52),
    );
  }

  Future<void> _loadEnemyAnimations() async {
    _enemyAnimations
      ..clear()
      ..addAll(await _loadAnimalEnemyAnimations());
    for (final entry in _guaishouSpriteSheets.entries) {
      _enemyAnimations[entry.key] = EnemyAnimationSet(
        image: await _loadImage(entry.value),
        displaySize: Vector2.all(isDeathmatch ? _deathmatchEnemySize : 42),
      );
    }
    for (final entry in _bossSpriteSheets.entries) {
      _enemyAnimations[entry.key] = EnemyAnimationSet(
        image: await _loadImage(entry.value),
        displaySize: Vector2.all(104),
      );
    }
  }

  Future<Map<String, EnemyAnimationSet>> _loadAnimalEnemyAnimations() async {
    final animations = <String, EnemyAnimationSet>{};
    for (final entry in _animalSpriteSheets.entries) {
      animations[entry.key] = EnemyAnimationSet(
        image: await _loadImage(entry.value),
        displaySize: _animalEnemyDisplaySize(entry.key),
        facingRows: _animalEnemyFacingRows(entry.key),
      );
    }
    return animations;
  }

  Vector2 _animalEnemyDisplaySize(String enemyId) {
    return Vector2.all(
      switch (enemyId) {
        'chick' || 'fast' || 'rooster' => 38,
        'dog' => 40,
        'lamb' || 'piglet' || 'sheep' => 42,
        'calf' => 50,
        'tank' || 'bull' => 62,
        _ => 40,
      },
    );
  }

  Map<EnemyFacing, int>? _animalEnemyFacingRows(String enemyId) {
    return switch (enemyId) {
      'lamb' || 'sheep' || 'calf' || 'bull' => const {
          EnemyFacing.front: 0,
          EnemyFacing.frontRight: 3,
          EnemyFacing.right: 3,
          EnemyFacing.backRight: 3,
          EnemyFacing.back: 1,
          EnemyFacing.backLeft: 2,
          EnemyFacing.left: 2,
          EnemyFacing.frontLeft: 2,
        },
      _ => null,
    };
  }

  Future<void> _loadCompanionAnimations() async {
    const variants = [
      (
        id: 'shadow_guard',
        asset:
            'assets/game/grass_game/images/companions/companion_shadow_guard_walk_8dir_sheet.png',
        size: 42.0,
        color: Color(0xFFB68CFF),
        accent: Color(0xFF7B61FF),
      ),
      (
        id: 'azure_drone',
        asset:
            'assets/game/grass_game/images/companions/companion_azure_drone_walk_8dir_sheet.png',
        size: 38.0,
        color: Color(0xFF7AD7FF),
        accent: Color(0xFF3D8BFF),
      ),
      (
        id: 'emerald_spirit_archer',
        asset:
            'assets/game/grass_game/images/companions/companion_emerald_spirit_archer_walk_8dir_sheet.png',
        size: 40.0,
        color: Color(0xFF70E06B),
        accent: Color(0xFF32B86A),
      ),
      (
        id: 'golden_shield_squire',
        asset:
            'assets/game/grass_game/images/companions/companion_golden_shield_squire_walk_8dir_sheet.png',
        size: 43.0,
        color: Color(0xFFFFD36E),
        accent: Color(0xFFFF9F3D),
      ),
      (
        id: 'silver_blade_puppet',
        asset:
            'assets/game/grass_game/images/companions/companion_silver_blade_puppet_walk_8dir_sheet.png',
        size: 41.0,
        color: Color(0xFFC7F7FF),
        accent: Color(0xFF8FD7FF),
      ),
      (
        id: 'violet_void_imp',
        asset:
            'assets/game/grass_game/images/companions/companion_violet_void_imp_walk_8dir_sheet.png',
        size: 39.0,
        color: Color(0xFFB68CFF),
        accent: Color(0xFF5E4BFF),
      ),
    ];
    _shadowGuardVariants = [
      for (final variant in variants)
        _CompanionRuntimeVariant(
          id: variant.id,
          animationSet: CompanionAnimationSet(
            image: await _loadImage(variant.asset),
            displaySize: Vector2.all(variant.size),
          ),
          color: variant.color,
          accentColor: variant.accent,
        ),
    ];
  }

  Future<void> _loadDropIcons() async {
    _dropIcons = DropIconSet(
      expLow: await _loadImage(
        'assets/game/grass_game/images/exp/exp_drop_low.webp',
      ),
      expMid: await _loadImage(
        'assets/game/grass_game/images/exp/exp_drop_mid.webp',
      ),
      expHigh: await _loadImage(
        'assets/game/grass_game/images/exp/exp_drop_high.webp',
      ),
      coinSmall: await _loadImage(
        'assets/game/grass_game/images/coins/coin_drop_small.webp',
      ),
      coinMedium: await _loadImage(
        'assets/game/grass_game/images/coins/coin_drop_medium.webp',
      ),
      coinLarge: await _loadImage(
        'assets/game/grass_game/images/coins/coin_drop_large.webp',
      ),
    );
  }

  Future<void> _loadSkillEffectImages() async {
    _fireEffectImage = await _loadImage(
      'assets/game/grass_game/images/effects/skill_fire_flame_sheet.png',
    );
    _iceEffectImage = await _loadImage(
      'assets/game/grass_game/images/effects/skill_ice_crystal_sheet.png',
    );
    _thunderEffectImage = await _loadImage(
      'assets/game/grass_game/images/effects/skill_thunder_lightning_sheet.png',
    );
    _poisonEffectImage = await _loadImage(
      'assets/game/grass_game/images/effects/skill_poison_spore_sheet.png',
    );
    _blackHoleEffectImage = await _loadImage(
      'assets/game/grass_game/images/effects/skill_void_black_hole_sheet.png',
    );
    _orbitBladeEffectImage = await _loadImage(
      'assets/game/grass_game/images/effects/skill_orbit_blade_sheet.png',
    );
    _ultimateBeamEffectImage = await _loadImage(
      'assets/game/grass_game/images/effects/skill_ultimate_beam_sheet.png',
    );
  }

  Future<Image> _loadImage(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final codec = await instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _loadWeaponEffects() async {
    final projectilePath = weaponProjectileAssetPath;
    if (projectilePath != null) {
      _projectileImage = await _loadImage(projectilePath);
    }

    final muzzleFlashPath = weaponMuzzleFlashAssetPath;
    if (muzzleFlashPath != null) {
      _muzzleFlashImage = await _loadImage(muzzleFlashPath);
    }

    final fireSoundPath = weaponFireSoundAssetPath;
    if (fireSoundPath != null) {
      FlameAudio.updatePrefix('assets/game/grass_game/audio/');
      _fireSoundFileName = fireSoundPath.split('/').last;
      _fireAudioPool = await FlameAudio.createPool(
        _fireSoundFileName!,
        minPlayers: 1,
        maxPlayers: 3,
      );
    }
  }

  @override
  void update(double dt) {
    final scaledDt = dt * controller.timeScale;
    if (_finished || !controller.state.isRunning) {
      super.update(0);
      return;
    }

    super.update(scaledDt);
    _resolveCircleObstacleCollisions(player.position, player.collisionRadius);
    _elapsed += scaledDt;
    _spawnTimer += scaledDt;
    _weaponTimer += scaledDt;
    _hudTimer += scaledDt;

    _updateDeathmatchBuffs();
    _spawnEnemies();
    _moveEnemies(scaledDt);
    _resolveEnemyObstacleCollisions();
    _rebuildEnemyCells();
    _enemySeparationTimer += scaledDt;
    if (_enemySeparationTimer >= 0.08) {
      _enemySeparationTimer = 0;
      _resolveEnemySeparation();
      _resolveEnemyObstacleCollisions();
      _rebuildEnemyCells();
    }
    _resolveEnemyPlayerSeparation();
    _faceNearestEnemy();
    _fireWeapon();
    _updateWeaponEffects(scaledDt);
    _updateProjectileWorldBounds();
    _updateSkillEffects(scaledDt);
    _rebuildEnemyCells();
    _resolveProjectileHits();
    _resolvePlayerHits();
    _updateGems(scaledDt);
    _checkBattleEnd();
    _updateFeedback(scaledDt);
    _syncHud();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Offset.zero & Size(size.x, size.y), _backgroundPaint);
    canvas.save();
    final cameraOffset = _cameraOffset;
    canvas.translate(cameraOffset.x, cameraOffset.y);
    _drawBattlefield(canvas);
    super.render(canvas);
    _drawSkillEffects(canvas);
    _drawWorldPulses(canvas);
    canvas.restore();
    _drawScreenFeedback(canvas);
  }

  void _drawBattlefield(Canvas canvas) {
    const cellSize = 72.0;
    final left = player.position.x - size.x / 2;
    final right = player.position.x + size.x / 2;
    final top = player.position.y - size.y / 2;
    final bottom = player.position.y + size.y / 2;
    _drawStageBackground(canvas,
        left: left, right: right, top: top, bottom: bottom);
    final startX = (left / cellSize).floor() * cellSize;
    final startY = (top / cellSize).floor() * cellSize;

    _stageTintPaint.color = _stageMapTheme.groundOverlay;
    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), _stageTintPaint);

    for (var x = startX; x <= right; x += cellSize) {
      for (var y = startY; y <= bottom; y += cellSize) {
        final cellX = (x / cellSize).floor();
        final cellY = (y / cellSize).floor();
        final rect = Rect.fromLTWH(x, y, cellSize, cellSize);
        if (_stageBackgroundImage == null) {
          canvas.drawRect(
            rect,
            (cellX + cellY).isEven ? _groundPaint : _groundAltPaint,
          );
        }
        canvas.drawRect(rect, _fieldLinePaint);
      }
    }

    _drawStageObstacles(canvas);
    _drawSpawnZone(canvas);
  }

  void _drawStageBackground(
    Canvas canvas, {
    required double left,
    required double right,
    required double top,
    required double bottom,
  }) {
    final image = _stageBackgroundImage;
    if (image == null) {
      return;
    }

    const tileWidth = 960.0;
    const tileHeight = 540.0;
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final startX = (left / tileWidth).floor() * tileWidth;
    final startY = (top / tileHeight).floor() * tileHeight;
    _stageBackgroundPaint.color = const Color(0xCCFFFFFF);
    for (var x = startX; x <= right; x += tileWidth) {
      for (var y = startY; y <= bottom; y += tileHeight) {
        canvas.drawImageRect(
          image,
          src,
          Rect.fromLTWH(x, y, tileWidth, tileHeight),
          _stageBackgroundPaint,
        );
      }
    }
  }

  void _drawStageObstacles(Canvas canvas) {
    for (final obstacle in _stageMapTheme.obstacles) {
      final assetPath = obstacle.assetPath;
      final image = assetPath == null ? null : _obstacleImages[assetPath];
      if (image != null) {
        _drawStageObstacleImage(canvas, obstacle, image);
      } else {
        _drawStageObstacleFallback(canvas, obstacle);
      }
    }
  }

  void _drawStageObstacleImage(
    Canvas canvas,
    _StageObstacle obstacle,
    Image image,
  ) {
    final visualRect = obstacle.visualRect;
    canvas.save();
    if (obstacle.rotation != 0) {
      final center = visualRect.center;
      canvas.translate(center.dx, center.dy);
      canvas.rotate(obstacle.rotation);
      canvas.translate(-center.dx, -center.dy);
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      visualRect,
      _obstacleImagePaint,
    );
    canvas.restore();
  }

  void _drawStageObstacleFallback(Canvas canvas, _StageObstacle obstacle) {
    _obstaclePaint.color = obstacle.color;
    _obstacleStrokePaint.color = obstacle.strokeColor;
    final rrect = RRect.fromRectAndRadius(
      obstacle.rect,
      Radius.circular(obstacle.radius),
    );
    canvas.drawRRect(rrect, _obstaclePaint);
    canvas.drawRRect(rrect, _obstacleStrokePaint);
    if (obstacle.detailColor != null) {
      _obstaclePaint.color = obstacle.detailColor!;
      final inset = math.min(
            obstacle.rect.width,
            obstacle.rect.height,
          ) *
          0.18;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          obstacle.rect.deflate(inset),
          Radius.circular(math.max(2, obstacle.radius * 0.5)),
        ),
        _obstaclePaint,
      );
    }
  }

  void _drawSpawnZone(Canvas canvas) {
    if (_elapsed >= _spawnZoneDisappearSeconds) {
      return;
    }

    var radius = _spawnZoneInitialRadius;
    var opacity = 1.0;
    if (_elapsed > _spawnZoneShrinkStartSeconds) {
      final progress = ((_elapsed - _spawnZoneShrinkStartSeconds) /
              (_spawnZoneDisappearSeconds - _spawnZoneShrinkStartSeconds))
          .clamp(0, 1)
          .toDouble();
      radius = _spawnZoneInitialRadius * (1 - progress);
      opacity = 1 - progress;
    }

    _spawnZonePaint.color = const Color(0x1AFFD36E).withOpacity(0.10 * opacity);
    _spawnZoneStrokePaint.color =
        const Color(0x66FFD36E).withOpacity(0.40 * opacity);
    canvas.drawCircle(Offset.zero, radius, _spawnZonePaint);
    canvas.drawCircle(Offset.zero, radius, _spawnZoneStrokePaint);
  }

  Vector2 get _cameraOffset {
    return Vector2(
        size.x / 2 - player.position.x, size.y / 2 - player.position.y);
  }

  void _drawWorldPulses(Canvas canvas) {
    for (final pulse in _worldPulses) {
      final progress = pulse.progress;
      final paint = Paint()
        ..color = pulse.color.withOpacity((1 - progress) * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(
        Offset(pulse.position.x, pulse.position.y),
        pulse.maxRadius * progress,
        paint,
      );
    }
  }

  void _drawScreenFeedback(Canvas canvas) {
    final screenRect = Offset.zero & Size(size.x, size.y);
    if (_damageFlashTimer > 0) {
      final opacity = (_damageFlashTimer / 0.35).clamp(0, 1) * 0.28;
      final paint = Paint()
        ..color = const Color(0xFFFF2D4F).withOpacity(opacity);
      canvas.drawRect(screenRect, paint);
    }
    if (_levelFlashTimer > 0) {
      final opacity = (_levelFlashTimer / 0.75).clamp(0, 1) * 0.08;
      final paint = Paint()
        ..color = const Color(0xFFFFD36E).withOpacity(opacity);
      canvas.drawRect(screenRect, paint);
      _drawCenterBanner(
        canvas,
        languageCode == 'zh' ? '升级可用' : 'LEVEL UP READY',
        const Color(0xFFFFD36E),
      );
    }
    if (_bossBannerTimer > 0) {
      _drawCenterBanner(
        canvas,
        _bossBannerText,
        const Color(0xFFFF5B6F),
      );
    }
    if (_finishFlashTimer > 0) {
      final opacity = (_finishFlashTimer / 1).clamp(0, 1) * 0.16;
      final paint = Paint()
        ..color = const Color(0xFFFFFFFF).withOpacity(opacity);
      canvas.drawRect(screenRect, paint);
    }
  }

  String get _bossBannerText {
    final isZh = languageCode == 'zh';
    if (isDeathmatch) {
      return isZh ? '怪兽强化' : 'MONSTERS ENRAGED';
    }
    if (_bossSpawned) {
      return isZh ? 'Boss 出现' : 'BOSS APPEARED';
    }
    return isZh ? 'Boss 即将出现' : 'BOSS INCOMING';
  }

  void _drawCenterBanner(Canvas canvas, String text, Color color) {
    final paragraphStyle = ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 22,
      fontWeight: FontWeight.w800,
    );
    final builder = ParagraphBuilder(paragraphStyle)
      ..pushStyle(
        TextStyle(
          color: color,
          letterSpacing: 1.2,
          shadows: const [
            Shadow(
              color: Color(0xCC000000),
              blurRadius: 8,
            ),
          ],
        ),
      )
      ..addText(text);
    final paragraph = builder.build()
      ..layout(ParagraphConstraints(width: size.x));
    canvas.drawParagraph(
      paragraph,
      Offset(0, size.y * 0.24 - paragraph.height / 2),
    );
  }

  void _updateDeathmatchBuffs() {
    if (!isDeathmatch) {
      return;
    }
    final nextTier = _currentDeathmatchBuffTier;
    if (nextTier <= _deathmatchBuffTier) {
      return;
    }
    final gainedTiers = nextTier - _deathmatchBuffTier;
    final previousSizeMultiplier =
        _deathmatchSizeMultiplierForTier(_deathmatchBuffTier);
    final nextSizeMultiplier = _deathmatchSizeMultiplierForTier(nextTier);
    _deathmatchBuffTier = nextTier;

    final hpMultiplier = math.pow(1.1, gainedTiers).toDouble();
    final speedMultiplier = math.pow(1.04, gainedTiers).toDouble();
    final sizeMultiplier = nextSizeMultiplier / previousSizeMultiplier;
    for (final enemy in _enemies) {
      if (enemy.enemyId.startsWith('guaishou_') && !enemy.isDead) {
        enemy.applyBuff(
          hpMultiplier: hpMultiplier,
          speedMultiplier: speedMultiplier,
          sizeMultiplier: sizeMultiplier,
          damageMultiplier: hpMultiplier,
        );
      }
    }
    _bossBannerTimer = 2;
    _addWorldPulse(
      position: player.position.clone(),
      color: const Color(0xFFFF5B6F),
      maxRadius: 180,
    );
  }

  void _spawnEnemies() {
    if (isDeathmatch) {
      _spawnDeathmatchEnemies();
      return;
    }
    if (_bossSpawned) {
      return;
    }
    if (_enemies.length >= _maxLiveEnemyCount) {
      return;
    }
    if (_killCount >= stageEnemyCount) {
      _spawnBoss();
      return;
    }
    final wave = _activeWave();
    if (wave == null) {
      return;
    }
    final spawnInterval = math.max(
      0.12,
      wave.spawnIntervalSeconds * _waveRuntimeIntervalMultiplier,
    );
    if (_spawnTimer < spawnInterval) {
      return;
    }
    _spawnTimer = 0;

    final batchCount = _spawnBatchCount();
    for (var i = 0;
        i < batchCount && _enemies.length < _maxLiveEnemyCount;
        i++) {
      final enemyId = _enemyIdForWave(wave.enemyId);
      final enemyConfig = _enemyConfig(enemyId) ?? config.enemies.first;
      final enemy = EnemyComponent(
        enemyId: enemyConfig.id,
        maxHp: math.max(
          1,
          (enemyConfig.hp * stageEnemyStrengthMultiplier).round(),
        ),
        moveSpeed: enemyConfig.moveSpeed *
            math.min(
              _enemySpeedGrowthCap,
              _enemySpeedBaseMultiplier +
                  stageEnemyStrengthMultiplier * _enemySpeedStrengthScale,
            ),
        expDrop: enemyConfig.expDrop,
        position: _randomSpawnPosition(),
        animationSet: _enemyAnimations[enemyConfig.id],
        meleeDamageMin: math.max(
          1,
          (enemyConfig.meleeDamageMin * stageEnemyStrengthMultiplier).round(),
        ),
        meleeDamageMax: math.max(
          1,
          (enemyConfig.meleeDamageMax * stageEnemyStrengthMultiplier).round(),
        ),
      );
      _enemies.add(enemy);
      add(enemy);
    }
  }

  void _spawnDeathmatchEnemies() {
    if (_enemies.length >= _maxLiveEnemyCount) {
      return;
    }

    final spawnInterval = math.max(0.16, 0.82 - (_elapsed / 60) * 0.055);
    if (_spawnTimer < spawnInterval) {
      return;
    }
    _spawnTimer = 0;

    final batchCount = math.min(14, 2 + (_elapsed ~/ 35));
    for (var i = 0;
        i < batchCount && _enemies.length < _maxLiveEnemyCount;
        i++) {
      final enemyId = _randomGuaishouEnemyId();
      final hash = enemyId.hashCode.abs();
      final strength = _deathmatchStrengthMultiplier;
      final enemy = EnemyComponent(
        enemyId: enemyId,
        maxHp: math.max(1, ((18 + hash % 10) * 1.35 * strength).round()),
        moveSpeed: (96 + hash % 34) * (1 + _currentDeathmatchBuffTier * 0.04),
        expDrop: 7 + hash % 5,
        position: _randomSpawnPosition(),
        animationSet: _enemyAnimations[enemyId],
        collisionRadiusOverride: _deathmatchEnemyCollisionRadius,
        sizeOverride: Vector2.all(_deathmatchEnemySize),
        meleeDamageMin: (5 * strength).ceil(),
        meleeDamageMax: (10 * strength).ceil(),
      );
      _enemies.add(enemy);
      add(enemy);
    }
  }

  int _spawnBatchCount() {
    if (_elapsed >= 90) {
      return 4;
    }
    if (_elapsed >= 35) {
      return 3;
    }
    return 2;
  }

  String _enemyIdForWave(String fallbackEnemyId) {
    if (stageEnemyTypes.isEmpty) {
      return fallbackEnemyId;
    }
    final candidates = stageEnemyTypes
        .where((enemyId) => _enemyWaveGroup(enemyId) == fallbackEnemyId)
        .toList();
    if (candidates.isNotEmpty) {
      return candidates[_random.nextInt(candidates.length)];
    }
    return stageEnemyTypes[_random.nextInt(stageEnemyTypes.length)];
  }

  String _randomGuaishouEnemyId() {
    final types = stageEnemyTypes
        .where((enemyId) => enemyId.startsWith('guaishou_'))
        .toList(growable: false);
    final pool = types.isEmpty ? _guaishouSpriteSheets.keys.toList() : types;
    return pool[_random.nextInt(pool.length)];
  }

  String _enemyWaveGroup(String enemyId) {
    return switch (enemyId) {
      'fast' || 'calf' || 'rooster' || 'chick' || 'dog' => 'fast',
      'tank' || 'turkey' || 'sheep' || 'bull' => 'tank',
      _ => 'basic',
    };
  }

  void _spawnBoss() {
    if (_bossSpawned) {
      return;
    }
    _bossSpawned = true;
    _bossBannerTimer = 3;
    final spawnPosition = _randomSpawnPosition();
    final bossVisualId = _bossVisualId;
    final hash = bossVisualId.hashCode.abs();
    _playHaptic(_GameHaptic.medium);
    final boss = EnemyComponent(
      enemyId: 'boss',
      maxHp: bossMaxHp + _level * 24,
      moveSpeed: 32 + hash % 16,
      expDrop: _bossExpDrop,
      position: spawnPosition,
      animationSet: _enemyAnimations[bossVisualId],
      collisionRadiusOverride: _bossCollisionRadius(bossVisualId),
      sizeOverride: Vector2.all(_bossDisplaySize(bossVisualId)),
      meleeDamageMin: 14 + hash % 5,
      meleeDamageMax: 22 + hash % 8,
    );
    _enemies.add(boss);
    add(boss);
  }

  String get _bossVisualId {
    if (bossId == 'random_guaishou') {
      return _randomGuaishouEnemyId();
    }
    if (_enemyAnimations.containsKey(bossId)) {
      return bossId;
    }
    return _randomGuaishouEnemyId();
  }

  double _bossDisplaySize(String bossVisualId) {
    return switch (bossVisualId) {
      'guaishou_cyber_crocodile_boss' => 122,
      'guaishou_highway_juggernaut_boss' => 124,
      'guaishou_city_core_guardian_boss' => 116,
      'guaishou_cave_crystal_brute_boss' => 126,
      'guaishou_forest_spore_titan_boss' => 126,
      'guaishou_ocean_shell_leviathan_boss' => 126,
      'guaishou_infected_plague_beetle_boss' => 118,
      'guaishou_bone_wasteland_reaper_boss' => 118,
      'guaishou_alien_landing_overlord_boss' => 120,
      'guaishou_cosmic_rift_dragon_boss' => 132,
      _ => 104,
    };
  }

  double _bossCollisionRadius(String bossVisualId) {
    return switch (bossVisualId) {
      'guaishou_cyber_crocodile_boss' => 40,
      'guaishou_highway_juggernaut_boss' => 42,
      'guaishou_city_core_guardian_boss' => 38,
      'guaishou_cave_crystal_brute_boss' => 42,
      'guaishou_forest_spore_titan_boss' => 42,
      'guaishou_ocean_shell_leviathan_boss' => 42,
      'guaishou_infected_plague_beetle_boss' => 39,
      'guaishou_bone_wasteland_reaper_boss' => 39,
      'guaishou_alien_landing_overlord_boss' => 40,
      'guaishou_cosmic_rift_dragon_boss' => 44,
      _ => 34,
    };
  }

  WaveConfig? _activeWave() {
    WaveConfig? active;
    for (final wave in config.waves) {
      if (_elapsed >= wave.startSecond) {
        active = wave;
      }
    }
    return active;
  }

  EnemyConfig? _enemyConfig(String id) {
    for (final enemy in config.enemies) {
      if (enemy.id == id) {
        return enemy;
      }
    }
    for (final enemy in GrassGameConfig.defaults.enemies) {
      if (enemy.id == id) {
        return enemy;
      }
    }
    return null;
  }

  int get _bossExpDrop {
    if (stageChapter == 1) {
      return switch (stageIndex) {
        1 => 40,
        2 => 60,
        3 => 80,
        4 => 100,
        _ => 130,
      };
    }
    return math.min(160, 80 + stageChapter * 8 + stageIndex * 6);
  }

  Vector2 _randomSpawnPosition() {
    const margin = 36.0;
    final side = _random.nextInt(4);
    final left = player.position.x - size.x / 2;
    final right = player.position.x + size.x / 2;
    final top = player.position.y - size.y / 2;
    final bottom = player.position.y + size.y / 2;
    return switch (side) {
      0 => Vector2(left + _random.nextDouble() * size.x, top - margin),
      1 => Vector2(right + margin, top + _random.nextDouble() * size.y),
      2 => Vector2(left + _random.nextDouble() * size.x, bottom + margin),
      _ => Vector2(left - margin, top + _random.nextDouble() * size.y),
    };
  }

  void _fireWeapon() {
    final runtimeStats = weaponRuntimeStats;
    final cooldown = math.max(
      0.06,
      (runtimeStats == null
              ? weaponFireIntervalSeconds
              : 1 / runtimeStats.attacksPerSecond) *
          _cooldownMultiplier,
    );
    if (_weaponTimer < cooldown || _enemies.isEmpty) {
      return;
    }

    final target = _nearestEnemy(maxDistance: _weaponRange);
    if (target == null) {
      return;
    }

    _weaponTimer = 0;
    _attackCount++;
    final direction = target.position - player.position;
    if (direction.length2 == 0) {
      return;
    }
    direction.normalize();
    _lastAimDirection = direction.clone();
    final spawnPosition = player.position + direction * 34;
    _fireWeaponPattern(direction, spawnPosition);
    _fireStarProjectiles(direction);
    _fireStarBarrage(direction);

    final muzzleFlashImage = _muzzleFlashImage;
    if (muzzleFlashImage != null) {
      add(
        MuzzleFlashComponent(
          image: muzzleFlashImage,
          position: spawnPosition + direction * 12,
          direction: direction,
        ),
      );
    }
    _playFireSound(cooldown);
  }

  void _fireWeaponPattern(Vector2 direction, Vector2 spawnPosition) {
    final pattern = weaponRuntimeStats?.attackPattern ?? 'projectile';
    switch (pattern) {
      case 'bouncingProjectile':
        _fireWeaponProjectile(
          direction: direction,
          position: spawnPosition,
          speed: 410,
          skillTag: 'weapon_bounce',
          pierceBonus: 0,
          motionType: ProjectileMotionType.bouncing,
          bouncesRemaining:
              weaponRuntimeStats?.effectId == 'bounce_chain' ? 6 : 4,
          rangeMultiplier:
              weaponRuntimeStats?.effectId == 'bounce_chain' ? 3.25 : 2.65,
        );
      case 'boomerang':
        _fireWeaponProjectile(
          direction: direction,
          position: spawnPosition,
          speed: 340,
          skillTag: 'weapon_boomerang',
          pierceBonus: 0,
          motionType: ProjectileMotionType.boomerang,
          rangeMultiplier:
              weaponRuntimeStats?.effectId == 'outer_ring_bonus' ? 2.45 : 2.1,
        );
      case 'coneShot':
        _fireWeaponCone(direction, spawnPosition);
      case 'beam':
        _damageEnemiesAlongLine(
          direction: direction,
          length: _weaponRange,
          width: math.max(18, _weaponAreaRadius * 0.34),
          damage: _weaponDamage,
          color: const Color(0xFF8FD7FF),
          bossDamageMultiplier: 0.42,
        );
      case 'lobbedExplosion':
        _fireWeaponProjectile(
          direction: direction,
          position: spawnPosition,
          speed: 310,
          skillTag: 'weapon_explosion',
        );
      case 'chainLightning':
        _fireWeaponProjectile(
          direction: direction,
          position: spawnPosition,
          speed: 390,
          skillTag: 'weapon_chain',
        );
      case 'meleeSweep':
        _fireMeleeSweep(direction);
      case 'flameStream':
        _fireWeaponCone(direction, spawnPosition, count: 3, angleSpread: 0.58);
      case 'orbitSlash':
        _damageEnemiesInRadius(
          origin: player.position,
          radius: math.max(_weaponRange, _weaponAreaRadius),
          damage: _weaponDamage,
          color: const Color(0xFF9BD3FF),
          bossDamageMultiplier: 0.38,
          slowMultiplier:
              weaponRuntimeStats?.effectId.contains('slow') ?? false ? 0.76 : 1,
          slowDuration:
              weaponRuntimeStats?.effectId.contains('slow') ?? false ? 0.9 : 0,
          knockback: weaponRuntimeStats?.knockback ?? 0,
        );
      default:
        _fireWeaponProjectile(direction: direction, position: spawnPosition);
    }
  }

  void _fireWeaponCone(
    Vector2 direction,
    Vector2 spawnPosition, {
    int? count,
    double angleSpread = 0.74,
  }) {
    final projectileCount = count ??
        (weaponRuntimeStats?.effectId == 'burn_spread'
            ? 6
            : weaponRuntimeStats?.effectId == 'spread_5'
                ? 5
                : 4);
    for (var i = 0; i < projectileCount; i++) {
      final factor = projectileCount == 1 ? 0.5 : i / (projectileCount - 1);
      final angle = -angleSpread / 2 + angleSpread * factor;
      _fireWeaponProjectile(
        direction: _rotated(direction, angle),
        position: spawnPosition,
        speed: 340,
      );
    }
  }

  void _fireMeleeSweep(Vector2 direction) {
    final effectId = weaponRuntimeStats?.effectId ?? '';
    final isHeavy = effectId.contains('heavy');
    final radius = math.max(
      _weaponRange,
      _weaponAreaRadius * (isHeavy ? 1.65 : 1.45),
    );
    final arc = isHeavy ? 1.85 : 1.42;
    final damage = math.max(1, (_weaponDamage * (isHeavy ? 1.18 : 1)).ceil());
    final knockback =
        (weaponRuntimeStats?.knockback ?? 0) * (isHeavy ? 1.25 : 1);
    final origin = player.position + direction * 18;
    final cosLimit = math.cos(arc / 2);
    final searchRadius = radius + 44;

    for (final enemy in _nearbyEnemies(player.position, searchRadius)) {
      if (enemy.isDead) {
        continue;
      }
      final toEnemy = enemy.position - player.position;
      final distanceSquared = toEnemy.length2;
      final hitDistance = radius + enemy.collisionRadius;
      if (distanceSquared > hitDistance * hitDistance) {
        continue;
      }
      final distance = math.sqrt(distanceSquared);
      final enemyDirection =
          distance <= 0.0001 ? direction : toEnemy / distance;
      if (direction.dot(enemyDirection) < cosLimit) {
        continue;
      }

      enemy.takeDamage(
        enemy.enemyId == 'boss' ? math.max(1, (damage * 0.48).ceil()) : damage,
      );
      if (knockback > 0 && enemy.enemyId != 'boss') {
        enemy.position += enemyDirection * knockback;
      }
    }

    _meleeSweeps.add(
      _MeleeSweepEffect(
        origin: origin,
        direction: direction.clone(),
        radius: radius,
        arc: arc,
        color: isHeavy ? const Color(0xFFFFD36E) : const Color(0xFFD9A441),
      ),
    );
    _addWorldPulse(
      position: origin,
      color: isHeavy ? const Color(0xFFFFD36E) : const Color(0xFFD9A441),
      maxRadius: math.min(92, radius),
    );
  }

  void _fireWeaponProjectile({
    required Vector2 direction,
    required Vector2 position,
    double speed = 380,
    String? skillTag,
    int pierceBonus = 0,
    ProjectileMotionType motionType = ProjectileMotionType.straight,
    int bouncesRemaining = 0,
    double rangeMultiplier = 1,
  }) {
    _spawnProjectile(
      direction: direction,
      position: position,
      damage: _weaponDamage,
      speed: speed,
      range: _weaponRange * rangeMultiplier,
      style: ProjectileVisualStyle.forKind(skillTag ?? weaponKind),
      image: _projectileImage,
      skillTag: skillTag,
      pierceRemaining: _weaponPierce +
          pierceBonus +
          (_skillLevel('star_projectile') >= 4 ? 1 : 0),
      motionType: motionType,
      bouncesRemaining: bouncesRemaining,
    );
  }

  void _spawnProjectile({
    required Vector2 direction,
    required Vector2 position,
    required int damage,
    required double speed,
    required double range,
    required ProjectileVisualStyle style,
    Image? image,
    String? skillTag,
    int pierceRemaining = 0,
    ProjectileMotionType motionType = ProjectileMotionType.straight,
    int bouncesRemaining = 0,
  }) {
    if (direction.length2 == 0) {
      return;
    }
    final nextDirection = direction.normalized();
    final projectile = ProjectileComponent(
      damage: math.max(1, damage),
      maxTravelDistance: range,
      velocity: nextDirection * speed,
      position: position,
      visualStyle: style,
      image: image,
      skillTag: skillTag,
      pierceRemaining: pierceRemaining,
      motionType: motionType,
      bouncesRemaining: bouncesRemaining,
      origin: position,
    );
    _projectiles.add(projectile);
    add(projectile);
  }

  void _fireStarProjectiles(Vector2 baseDirection) {
    final level = _skillLevel('star_projectile');
    if (level <= 0) {
      return;
    }

    final extraCount = 1 + (level >= 3 ? 2 : 0) + (level >= 5 ? 1 : 0);
    final damage = math.max(
      1,
      (_weaponDamage * _starProjectileDamageMultiplier).ceil(),
    );
    for (var i = 0; i < extraCount; i++) {
      final angle = extraCount == 1
          ? 0.0
          : -0.34 + 0.68 * (i / math.max(1, extraCount - 1));
      final direction = _rotated(baseDirection, angle);
      _spawnProjectile(
        direction: direction,
        position: player.position + direction * 32,
        damage: damage,
        speed: 430,
        range: _attackRange * 1.06,
        style: ProjectileVisualStyle.forKind('star_projectile'),
        skillTag: 'star_projectile',
        pierceRemaining: level >= 4 ? 1 : 0,
      );
    }
  }

  void _fireStarBarrage(Vector2 baseDirection) {
    if (!_evolvedSkills.contains('evolve_star_barrage') ||
        _attackCount % 5 != 0) {
      return;
    }

    for (var i = 0; i < 9; i++) {
      final angle = -0.72 + 1.44 * (i / 8);
      final direction = _rotated(baseDirection, angle);
      _spawnProjectile(
        direction: direction,
        position: player.position + direction * 36,
        damage: math.max(
          1,
          (_weaponDamage * _starBarrageDamageMultiplier).ceil(),
        ),
        speed: 470,
        range: _attackRange * 1.15,
        style: ProjectileVisualStyle.forKind('star_projectile'),
        skillTag: 'star_projectile',
        pierceRemaining: 1,
      );
    }
    _addWorldPulse(
      position: player.position.clone(),
      color: const Color(0xFF8FD7FF),
      maxRadius: 120,
    );
  }

  Vector2 _rotated(Vector2 direction, double radians) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    return Vector2(
      direction.x * cos - direction.y * sin,
      direction.x * sin + direction.y * cos,
    );
  }

  void _playFireSound(double cooldown) {
    final fileName = _fireSoundFileName;
    final volumeScale = soundVolume.clamp(0, 1).toDouble();
    if (fileName == null || volumeScale <= 0) {
      return;
    }

    final minGapSeconds = cooldown < 0.16 ? 0.18 : 0.14;
    if (_elapsed - _lastFireSoundAt < minGapSeconds) {
      return;
    }
    _lastFireSoundAt = _elapsed;

    final volume = (cooldown < 0.16 ? 0.16 : 0.28) * volumeScale;
    unawaited(_playAudioFile(fileName, volume: volume));
  }

  Future<void> _playAudioFile(String fileName, {required double volume}) async {
    if (_isReleased) {
      return;
    }
    try {
      final pool = _fireAudioPool;
      if (pool != null && fileName == _fireSoundFileName) {
        final stop = await pool.start(volume: volume);
        _activeFireSoundStops.add(stop);
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 900), () {
            _activeFireSoundStops.remove(stop);
          }),
        );
        return;
      }
      await FlameAudio.play(fileName, volume: volume);
    } catch (_) {
      // Audio should never interrupt gameplay.
    }
  }

  void _playHaptic(_GameHaptic haptic) {
    final intensity = vibrationIntensity.clamp(0, 1).toDouble();
    if (intensity <= 0) {
      return;
    }

    final Future<void> feedback;
    if (intensity < 0.4) {
      feedback = HapticFeedback.selectionClick();
    } else if (intensity < 0.75) {
      feedback = switch (haptic) {
        _GameHaptic.light => HapticFeedback.selectionClick(),
        _ => HapticFeedback.mediumImpact(),
      };
    } else {
      feedback = switch (haptic) {
        _GameHaptic.light => HapticFeedback.selectionClick(),
        _GameHaptic.medium => HapticFeedback.mediumImpact(),
        _GameHaptic.heavy => HapticFeedback.heavyImpact(),
        _GameHaptic.damage => HapticFeedback.lightImpact(),
      };
    }
    unawaited(feedback);
  }

  void _faceNearestEnemy() {
    final target = _nearestEnemy(maxDistance: _attackRange);
    if (target == null) {
      return;
    }
    player.faceToward(target.position);
  }

  EnemyComponent? _nearestEnemy({double? maxDistance}) {
    EnemyComponent? nearest;
    final maxDistanceSquared =
        maxDistance == null ? double.infinity : maxDistance * maxDistance;
    var nearestDistance = double.infinity;
    final candidates = maxDistance == null
        ? _enemies
        : _nearbyEnemies(player.position, maxDistance);
    for (final enemy in candidates) {
      if (enemy.isDead) {
        continue;
      }
      final distance = enemy.position.distanceToSquared(player.position);
      if (distance > maxDistanceSquared) {
        continue;
      }
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = enemy;
      }
    }
    return nearest;
  }

  void _rebuildEnemyCells() {
    _enemyCells.clear();
    for (final enemy in _enemies) {
      if (enemy.isDead) {
        continue;
      }
      final key = _enemyCellKey(enemy.position);
      (_enemyCells[key] ??= <EnemyComponent>[]).add(enemy);
    }
  }

  Iterable<EnemyComponent> _nearbyEnemies(Vector2 origin, double radius) sync* {
    if (_enemyCells.isEmpty) {
      yield* _enemies;
      return;
    }

    final minCellX = ((origin.x - radius) / _enemyGridCellSize).floor();
    final maxCellX = ((origin.x + radius) / _enemyGridCellSize).floor();
    final minCellY = ((origin.y - radius) / _enemyGridCellSize).floor();
    final maxCellY = ((origin.y + radius) / _enemyGridCellSize).floor();
    for (var cellX = minCellX; cellX <= maxCellX; cellX++) {
      for (var cellY = minCellY; cellY <= maxCellY; cellY++) {
        final enemies = _enemyCells[(cellX, cellY)];
        if (enemies == null) {
          continue;
        }
        for (final enemy in enemies) {
          yield enemy;
        }
      }
    }
  }

  (int, int) _enemyCellKey(Vector2 position) {
    return (
      (position.x / _enemyGridCellSize).floor(),
      (position.y / _enemyGridCellSize).floor(),
    );
  }

  void _moveEnemies(double dt) {
    for (final enemy in _enemies) {
      enemy.moveToward(player.position, dt);
    }
  }

  void _resolveEnemyObstacleCollisions() {
    for (final enemy in _enemies) {
      if (enemy.isDead) {
        continue;
      }
      _resolveCircleObstacleCollisions(enemy.position, enemy.collisionRadius);
    }
  }

  void _resolveCircleObstacleCollisions(Vector2 center, double radius) {
    for (final obstacle in _stageMapTheme.obstacles) {
      final rect = obstacle.rect;
      final closestX = center.x.clamp(rect.left, rect.right).toDouble();
      final closestY = center.y.clamp(rect.top, rect.bottom).toDouble();
      final deltaX = center.x - closestX;
      final deltaY = center.y - closestY;
      final distanceSquared = deltaX * deltaX + deltaY * deltaY;
      if (distanceSquared > radius * radius) {
        continue;
      }

      if (distanceSquared > 0.0001) {
        final distance = math.sqrt(distanceSquared);
        final push = radius - distance + 0.5;
        center.x += deltaX / distance * push;
        center.y += deltaY / distance * push;
        continue;
      }

      final leftPush = (center.x - rect.left).abs();
      final rightPush = (rect.right - center.x).abs();
      final topPush = (center.y - rect.top).abs();
      final bottomPush = (rect.bottom - center.y).abs();
      final minPush = math.min(
        math.min(leftPush, rightPush),
        math.min(topPush, bottomPush),
      );
      if (minPush == leftPush) {
        center.x = rect.left - radius - 0.5;
      } else if (minPush == rightPush) {
        center.x = rect.right + radius + 0.5;
      } else if (minPush == topPush) {
        center.y = rect.top - radius - 0.5;
      } else {
        center.y = rect.bottom + radius + 0.5;
      }
    }
  }

  void _updateWeaponEffects(double dt) {
    for (final sweep in _meleeSweeps) {
      sweep.age += dt;
    }
    _meleeSweeps.removeWhere((sweep) => sweep.isDone);
    for (final image in _weaponUltimateImages) {
      image.age += dt;
    }
    _weaponUltimateImages.removeWhere((image) => image.isDone);
    for (final blast in _delayedWeaponBlasts) {
      blast.delay -= dt;
      blast.age += dt;
      if (blast.delay > 0 || blast.hasExploded) {
        continue;
      }
      blast.hasExploded = true;
      _damageEnemiesInRadius(
        origin: blast.center,
        radius: blast.radius,
        damage: blast.damage,
        color: blast.color,
        bossDamageMultiplier: blast.bossDamageMultiplier,
        slowMultiplier: blast.slowMultiplier,
        slowDuration: blast.slowDuration,
        knockback: blast.knockback,
      );
      _weaponUltimateImages.add(
        _WeaponUltimateImage(
          center: blast.center.clone(),
          size: blast.imageSize,
          color: blast.color,
          duration: 0.48,
          spinTurns: 0.35,
        ),
      );
    }
    _delayedWeaponBlasts.removeWhere((blast) => blast.isDone);
  }

  void _updateProjectileWorldBounds() {
    final bounds = _visibleWorldRect(margin: -10);
    for (final projectile in _projectiles) {
      if (projectile.bounceInside(bounds)) {
        _addWorldPulse(
          position: projectile.position.clone(),
          color: const Color(0xFFFFD36E),
          maxRadius: 38,
        );
      }
    }
  }

  Rect _visibleWorldRect({double margin = 0}) {
    final halfWidth = size.x / 2 + margin;
    final halfHeight = size.y / 2 + margin;
    return Rect.fromLTRB(
      player.position.x - halfWidth,
      player.position.y - halfHeight,
      player.position.x + halfWidth,
      player.position.y + halfHeight,
    );
  }

  void _updateSkillEffects(double dt) {
    _updateGroundFields(dt);
    _updateFireTrail(dt);
    _updateIceNova(dt);
    _updatePoisonSpore(dt);
    _updateShadowGuard(dt);
    _updateOrbitBlades(dt);
    _updateThunderMatrix(dt);
    _updateVoidMagnet(dt);
    _updateBlackHoles(dt);
    _updateUltimates(dt);
    _updateChargedUltimateBeams(dt);
    for (final strike in _thunderStrikes) {
      strike.age += dt;
    }
    _thunderStrikes.removeWhere((strike) => strike.isDone);
    for (final ring in _expandingRings) {
      ring.age += dt;
    }
    _expandingRings.removeWhere((ring) => ring.isDone);
    _cleanupDefeatedEnemies();
  }

  void _updateGroundFields(double dt) {
    _expiredGroundFieldBuffer.clear();
    for (final field in _groundFields) {
      field.age += dt;
      field.tickTimer -= dt;
      if (field.tickTimer <= 0) {
        field.tickTimer = field.tickInterval;
        _tickGroundField(field);
      }
      if (field.isDone) {
        _expiredGroundFieldBuffer.add(field);
      }
    }
    for (final field in _expiredGroundFieldBuffer) {
      _groundFields.remove(field);
    }
    _expiredGroundFieldBuffer.clear();
  }

  void _tickGroundField(_GroundEffectField field) {
    final radiusSquared = field.radius * field.radius;
    for (final enemy in _nearbyEnemies(field.center, field.radius)) {
      if (enemy.isDead ||
          enemy.position.distanceToSquared(field.center) > radiusSquared) {
        continue;
      }

      final isBoss = enemy.enemyId == 'boss';
      final damage = isBoss
          ? math.max(1, (field.damage * field.bossDamageMultiplier).ceil())
          : field.damage;
      enemy.takeDamage(damage);

      switch (field.type) {
        case _GroundEffectType.fire:
          if (field.firstHitExplosionDamage > 0 &&
              field.firstHitEnemies.add(enemy)) {
            _damageEnemiesInRadius(
              origin: enemy.position,
              radius: 34,
              damage: field.firstHitExplosionDamage,
              color: const Color(0xFFFF8A3D),
            );
          }
        case _GroundEffectType.poison:
          _poisonedEnemies.add(enemy);
          if (field.slowMultiplier < 1) {
            enemy.applySlow(
              multiplier: field.slowMultiplier,
              duration: field.tickInterval + 0.18,
            );
          }
        case _GroundEffectType.frostInferno:
          enemy.applySlow(
            multiplier: isBoss ? 0.72 : 0.46,
            duration: field.tickInterval + 0.28,
          );
      }
    }
  }

  void _updateFireTrail(double dt) {
    final level = _skillLevel('fire_trail');
    if (level <= 0 || controller.moveDirection.length2 < 0.01) {
      return;
    }

    _fireTrailTimer += dt;
    final interval = _evolvedSkills.contains('evolve_inferno_path')
        ? 0.38
        : level >= 5
            ? 0.58
            : 0.8;
    if (_fireTrailTimer < interval) {
      return;
    }
    _fireTrailTimer = 0;
    _addFireField(player.position.clone(), level: level);
  }

  void _addFireField(Vector2 center, {required int level}) {
    final evolved = _evolvedSkills.contains('evolve_inferno_path');
    final radius = (36.0 + (level >= 4 ? 8.0 : 0.0)) * (evolved ? 1.18 : 1.0);
    final duration = (1.8 * (level >= 2 ? 1.35 : 1.0)) * (evolved ? 1.45 : 1.0);
    final damage = math.max(
      1,
      (_weaponDamage * (0.32 + level * 0.06) * (evolved ? 1.18 : 1)).ceil(),
    );
    _addGroundField(
      _GroundEffectField(
        type: _GroundEffectType.fire,
        center: center,
        radius: radius,
        duration: duration,
        tickInterval: evolved ? 0.22 : 0.35,
        damage: damage,
        bossDamageMultiplier: 0.38,
        color: const Color(0xFFFF8A3D),
        firstHitExplosionDamage:
            level >= 5 ? math.max(1, (_weaponDamage * 0.7).ceil()) : 0,
      ),
    );
  }

  void _updateIceNova(double dt) {
    final level = _skillLevel('ice_nova');
    if (level <= 0) {
      return;
    }

    _iceNovaTimer += dt;
    final cooldown = (level >= 5 ? 4.8 : 6.0).clamp(2.2, 8.0).toDouble();
    if (_iceNovaTimer < cooldown) {
      return;
    }
    _iceNovaTimer = 0;
    _releaseIceNova(level);
  }

  void _releaseIceNova(int level) {
    final evolved = _evolvedSkills.contains('evolve_permafrost_field');
    final radius = (90.0 * (level >= 3 ? 1.22 : 1.0)) * (evolved ? 1.14 : 1.0);
    final slowDuration = 1.35 + (level >= 2 ? 0.6 : 0) + (evolved ? 0.8 : 0);
    final damage = level >= 4
        ? math.max(1, (_weaponDamage * (evolved ? 0.75 : 0.48)).ceil())
        : 0;
    final radiusSquared = radius * radius;
    for (final enemy in _nearbyEnemies(player.position, radius)) {
      if (enemy.isDead ||
          enemy.position.distanceToSquared(player.position) > radiusSquared) {
        continue;
      }
      final isBoss = enemy.enemyId == 'boss';
      enemy.applySlow(
        multiplier: evolved
            ? isBoss
                ? 0.62
                : 0.12
            : isBoss
                ? 0.78
                : 0.45,
        duration: slowDuration,
      );
      if (damage > 0) {
        enemy.takeDamage(isBoss ? math.max(1, (damage * 0.35).ceil()) : damage);
      }
    }
    _expandingRings.add(
      _ExpandingRing(
        center: player.position.clone(),
        radius: radius,
        color: const Color(0xFF9BD3FF),
        strokeWidth: evolved ? 5 : 3,
      ),
    );
    if (evolved) {
      _damageEnemiesInRadius(
        origin: player.position,
        radius: radius * 0.56,
        damage: math.max(1, (_weaponDamage * 0.62).ceil()),
        color: const Color(0xFFC7F7FF),
      );
    }
  }

  void _updatePoisonSpore(double dt) {
    final level = _skillLevel('poison_spore');
    if (level <= 0 || _enemies.isEmpty) {
      return;
    }

    _poisonSporeTimer += dt;
    final interval = level >= 5 ? 4.0 : 5.0;
    if (_poisonSporeTimer < interval) {
      return;
    }
    _poisonSporeTimer = 0;
    final target = _pickPoisonTarget();
    if (target != null) {
      _addPoisonField(target.position.clone(), level: level);
    }
  }

  EnemyComponent? _pickPoisonTarget() {
    EnemyComponent? best;
    var bestCount = -1;
    var bestDistance = double.infinity;
    for (final enemy in _enemies) {
      if (enemy.isDead) {
        continue;
      }
      final nearby = _nearbyEnemyCount(enemy.position, 110);
      final distance = enemy.position.distanceToSquared(player.position);
      if (nearby > bestCount ||
          (nearby == bestCount && distance < bestDistance)) {
        best = enemy;
        bestCount = nearby;
        bestDistance = distance;
      }
    }
    return best;
  }

  void _addPoisonField(Vector2 center,
      {required int level, bool small = false}) {
    final evolved = _evolvedSkills.contains('evolve_corrosive_plague');
    final radius =
        (small ? 38.0 : 58.0) * (level >= 3 ? 1.2 : 1) * (evolved ? 1.12 : 1);
    final duration = (small ? 1.8 : 3.0) * (level >= 2 ? 1.3 : 1);
    _addGroundField(
      _GroundEffectField(
        type: _GroundEffectType.poison,
        center: center,
        radius: radius,
        duration: duration,
        tickInterval: level >= 5 ? 0.36 : 0.52,
        damage: math.max(1, (_weaponDamage * (small ? 0.28 : 0.44)).ceil()),
        bossDamageMultiplier: 0.42,
        color: const Color(0xFF70E06B),
        slowMultiplier: level >= 4 ? 0.85 : 1,
      ),
    );
  }

  void _updateShadowGuard(double dt) {
    final level = _skillLevel('shadow_guard');
    _expiredCompanionBuffer.clear();

    for (final companion in _companions) {
      if (companion.isExpired) {
        _expiredCompanionBuffer.add(companion);
        continue;
      }
      final followPosition = _shadowGuardFollowPosition(
        companion,
        _shadowGuardMaxActiveCount,
      );
      companion.moveToward(followPosition, dt);
      if (level > 0) {
        _tryShadowGuardAttack(companion, level);
      }
    }

    for (final companion in _expiredCompanionBuffer) {
      _companions.remove(companion);
      companion.removeFromParent();
    }
    _expiredCompanionBuffer.clear();

    if (level <= 0) {
      return;
    }

    _shadowGuardSummonTimer += dt;
    if (_shadowGuardSummonTimer < _shadowGuardSummonInterval &&
        _companions.length >= _shadowGuardMaxActiveCount) {
      return;
    }
    _shadowGuardSummonTimer = 0;
    _summonShadowGuards(level);
  }

  int get _shadowGuardMaxActiveCount =>
      _evolvedSkills.contains('evolve_twin_shadow') ? 2 : 1;

  double get _shadowGuardSummonInterval =>
      _evolvedSkills.contains('evolve_twin_shadow') ? 7.0 : 9.0;

  double _shadowGuardLifetime(int level) {
    return 16 +
        level * 2.0 +
        (_evolvedSkills.contains('evolve_twin_shadow') ? 4 : 0);
  }

  void _summonShadowGuards(int level) {
    final maxActive = _shadowGuardMaxActiveCount;
    final lifetime = _shadowGuardLifetime(level);
    for (final companion in _companions) {
      companion.refreshLifetime(lifetime);
    }

    while (_companions.length < maxActive) {
      final slotIndex = _companions.length;
      final variant =
          _shadowGuardVariants[_random.nextInt(_shadowGuardVariants.length)];
      final companion = CompanionComponent(
        companionId: variant.id,
        slotIndex: slotIndex,
        moveSpeed: 235 + level * 13 + _random.nextDouble() * 26,
        remainingLifetime: lifetime,
        formationPhase: _random.nextDouble() * math.pi * 2,
        wanderRadius: 9 + _random.nextDouble() * 13,
        animationSet: variant.animationSet,
        position: player.position +
            Vector2(
              -14 + _random.nextDouble() * 28,
              24 + slotIndex * 8 + _random.nextDouble() * 18,
            ),
      );
      companion.attackTimer =
          0.12 + slotIndex * 0.24 + _random.nextDouble() * 0.2;
      _companions.add(companion);
      add(companion);
    }

    _addWorldPulse(
      position: player.position.clone(),
      color: const Color(0xFFB68CFF),
      maxRadius: 74,
    );
  }

  Vector2 _shadowGuardFollowPosition(CompanionComponent companion, int count) {
    final aim = _lastAimDirection.length2 > 0.0001
        ? _lastAimDirection.normalized()
        : Vector2(0, 1);
    final back = -aim;
    final side = Vector2(-aim.y, aim.x);
    final slotIndex = companion.slotIndex;
    final phase =
        companion.formationPhase + _elapsed * (0.9 + slotIndex * 0.17);
    final drift = side * math.sin(phase) * companion.wanderRadius +
        back * math.cos(phase * 0.73) * (companion.wanderRadius * 0.55);
    if (count <= 1) {
      return player.position + back * (50 + math.sin(phase * 0.61) * 8) + drift;
    }
    final sideSign = slotIndex.isEven ? -1.0 : 1.0;
    return player.position +
        back * (44 + math.cos(phase * 0.47) * 7) +
        side * (34 + companion.wanderRadius * 0.4) * sideSign +
        drift;
  }

  void _tryShadowGuardAttack(CompanionComponent companion, int level) {
    if (companion.attackTimer > 0 || _enemies.isEmpty) {
      return;
    }

    final target = _pickShadowGuardTarget(companion);
    if (target == null) {
      companion.attackTimer = 0.3;
      return;
    }

    companion.faceToward(target.position);
    final roll = _random.nextDouble();
    final id = companion.companionId;
    final dashChance = switch (id) {
      'silver_blade_puppet' => 0.34,
      'violet_void_imp' => 0.30,
      'golden_shield_squire' => 0.18,
      _ => 0.22,
    };
    final clawChance = switch (id) {
      'golden_shield_squire' => 0.64,
      'shadow_guard' => 0.50,
      'violet_void_imp' => 0.42,
      _ => 0.34,
    };
    if (level >= 5 && roll < dashChance) {
      _shadowGuardDashSlash(companion, target, level);
    } else if (level >= 2 && roll < clawChance) {
      _shadowGuardClaw(companion, target, level);
    } else {
      _shadowGuardBlade(companion, target, level);
    }

    final evolvedFactor =
        _evolvedSkills.contains('evolve_twin_shadow') ? 0.84 : 1.0;
    companion.attackTimer =
        math.max(0.58, (1.42 - level * 0.09) * evolvedFactor);
  }

  EnemyComponent? _pickShadowGuardTarget(CompanionComponent companion) {
    EnemyComponent? best;
    var bestScore = double.infinity;
    for (final enemy in _nearbyEnemies(companion.position, 360)) {
      if (enemy.isDead) {
        continue;
      }
      final distance = enemy.position.distanceToSquared(companion.position);
      final score = distance * (0.72 + _random.nextDouble() * 0.56);
      if (score < bestScore) {
        best = enemy;
        bestScore = score;
      }
    }
    if (best != null) {
      return best;
    }

    for (final enemy in _nearbyEnemies(player.position, 420)) {
      if (enemy.isDead) {
        continue;
      }
      final distance = enemy.position.distanceToSquared(player.position);
      final score = distance * (0.82 + _random.nextDouble() * 0.42);
      if (score < bestScore) {
        best = enemy;
        bestScore = score;
      }
    }
    return best;
  }

  void _shadowGuardBlade(
    CompanionComponent companion,
    EnemyComponent target,
    int level,
  ) {
    final direction = target.position - companion.position;
    if (direction.length2 <= 0.0001) {
      return;
    }
    _spawnProjectile(
      direction: direction,
      position: companion.position + direction.normalized() * 24,
      damage: _shadowGuardDamage(level, 0.72),
      speed: companion.companionId == 'azure_drone' ? 560 : 480,
      range: companion.companionId == 'emerald_spirit_archer' ? 430 : 370,
      style: ProjectileVisualStyle.forKind(
        _shadowGuardProjectileKind(companion.companionId),
      ),
      skillTag: 'shadow_guard',
      pierceRemaining: level >= 4 ? 1 : 0,
    );
  }

  void _shadowGuardClaw(
    CompanionComponent companion,
    EnemyComponent target,
    int level,
  ) {
    final direction = target.position - companion.position;
    if (direction.length2 <= 0.0001) {
      return;
    }
    final normalized = direction.normalized();
    final origin = companion.position + normalized * 26;
    _damageEnemiesInRadius(
      origin: origin,
      radius: level >= 3 ? 48 : 38,
      damage: _shadowGuardDamage(level, 0.92),
      color: _shadowGuardVariantFor(companion.companionId).color,
      bossDamageMultiplier: 0.38,
      slowMultiplier: level >= 4 ? 0.88 : 1,
      slowDuration: 0.45,
      knockback: 18,
    );
    _meleeSweeps.add(
      _MeleeSweepEffect(
        origin: origin,
        direction: normalized,
        radius: level >= 3 ? 70 : 56,
        arc: 1.48,
        color: _shadowGuardVariantFor(companion.companionId).accentColor,
      ),
    );
  }

  void _shadowGuardDashSlash(
    CompanionComponent companion,
    EnemyComponent target,
    int level,
  ) {
    final direction = target.position - companion.position;
    if (direction.length2 <= 0.0001) {
      return;
    }
    final normalized = direction.normalized();
    companion.dash(normalized, speed: 520, time: 0.12);
    _damageEnemiesInRadius(
      origin: target.position.clone(),
      radius: companion.companionId == 'violet_void_imp' ? 72 : 62,
      damage: _shadowGuardDamage(level, 1.15),
      color: _shadowGuardVariantFor(companion.companionId).accentColor,
      bossDamageMultiplier: 0.40,
      slowMultiplier: 0.82,
      slowDuration: 0.55,
      knockback: 24,
    );
    _expandingRings.add(
      _ExpandingRing(
        center: target.position.clone(),
        radius: 82,
        color: _shadowGuardVariantFor(companion.companionId).color,
        strokeWidth: 3,
      ),
    );
  }

  _CompanionRuntimeVariant _shadowGuardVariantFor(String companionId) {
    for (final variant in _shadowGuardVariants) {
      if (variant.id == companionId) {
        return variant;
      }
    }
    return _shadowGuardVariants.first;
  }

  String _shadowGuardProjectileKind(String companionId) {
    return switch (companionId) {
      'azure_drone' => 'shadow_guard_azure',
      'emerald_spirit_archer' => 'shadow_guard_emerald',
      'golden_shield_squire' => 'shadow_guard_golden',
      'silver_blade_puppet' => 'shadow_guard_silver',
      'violet_void_imp' => 'shadow_guard_violet',
      _ => 'shadow_guard',
    };
  }

  int _shadowGuardDamage(int level, double multiplier) {
    final evolved = _evolvedSkills.contains('evolve_twin_shadow');
    return math.max(
      1,
      (_weaponDamage * multiplier * (0.9 + level * 0.12) * (evolved ? 0.9 : 1))
          .ceil(),
    );
  }

  void _addGroundField(_GroundEffectField field) {
    _groundFields.add(field);
    while (_groundFields.length > _maxGroundFieldCount) {
      _groundFields.removeAt(0);
    }
  }

  void _updateOrbitBlades(double dt) {
    final level = _skillLevel('orbit_blade');
    if (level <= 0) {
      return;
    }

    _orbitAngle += dt * (2.8 + (level >= 3 ? 0.7 : 0));
    _orbitHitTimer -= dt;
    if (_evolvedSkills.contains('evolve_moon_wheel')) {
      _moonWheelTimer = (_moonWheelTimer + dt) % 8;
    }
    if (_orbitHitTimer > 0) {
      return;
    }
    _orbitHitTimer = 0.18;

    final bladeCount = 1 + (level >= 2 ? 1 : 0);
    final stormPhase =
        _evolvedSkills.contains('evolve_moon_wheel') && _moonWheelTimer <= 2.4;
    final radius = stormPhase
        ? 70 + 80 * math.sin((_moonWheelTimer / 2.4) * math.pi)
        : 70 * (level >= 5 ? 1.22 : 1.0);
    final damage = math.max(
      1,
      (_weaponDamage *
              (level >= 5
                  ? _orbitBladeLevel5DamageMultiplier
                  : _orbitBladeDamageMultiplier))
          .ceil(),
    );

    for (var i = 0; i < bladeCount; i++) {
      final angle = _orbitAngle + math.pi * 2 * i / bladeCount;
      final bladePosition =
          player.position + Vector2(math.cos(angle), math.sin(angle)) * radius;
      _damageEnemiesInRadius(
        origin: bladePosition,
        radius: stormPhase ? 34 : 24,
        damage: damage,
        color: const Color(0xFFC7F7FF),
      );
    }
  }

  void _updateThunderMatrix(double dt) {
    final level = _skillLevel('thunder_matrix');
    if (level <= 0 || _enemies.isEmpty) {
      return;
    }

    _thunderTimer += dt;
    final cooldown = 3.2 * (level >= 5 ? 0.8 : 1);
    if (_thunderTimer < cooldown) {
      return;
    }
    _thunderTimer = 0;

    final targets = _pickThunderTargets(count: level >= 2 ? 2 : 1);
    for (final target in targets) {
      _strikeEnemy(target, level: level);
    }
  }

  List<EnemyComponent> _pickThunderTargets({required int count}) {
    final picked = <_ThunderTargetScore>[];
    for (final enemy in _enemies) {
      if (enemy.isDead) {
        continue;
      }
      final score = _ThunderTargetScore(
        enemy: enemy,
        nearbyCount: _nearbyEnemyCount(enemy.position, 96),
        playerDistanceSquared: enemy.position.distanceToSquared(
          player.position,
        ),
      );
      var insertAt = picked.length;
      for (var i = 0; i < picked.length; i++) {
        if (score.compareTo(picked[i]) < 0) {
          insertAt = i;
          break;
        }
      }
      picked.insert(insertAt, score);
      if (picked.length > count) {
        picked.removeLast();
      }
    }
    if (picked.isEmpty) {
      return const [];
    }
    return [for (final score in picked) score.enemy];
  }

  int _nearbyEnemyCount(Vector2 origin, double radius) {
    final radiusSquared = radius * radius;
    var count = 0;
    for (final enemy in _nearbyEnemies(origin, radius)) {
      if (!enemy.isDead &&
          enemy.position.distanceToSquared(origin) <= radiusSquared) {
        count++;
      }
    }
    return count;
  }

  void _strikeEnemy(EnemyComponent enemy, {required int level}) {
    if (enemy.isDead) {
      return;
    }
    final damage = math.max(
      2,
      (_weaponDamage * _thunderMainDamageMultiplier).ceil(),
    );
    enemy.takeDamage(enemy.enemyId == 'boss' ? (damage * 0.6).ceil() : damage);
    _thunderStrikes.add(
      _ThunderStrike(
        position: enemy.position.clone(),
        radius: level >= 3 ? 58 : 34,
      ),
    );
    if (level >= 3) {
      _damageEnemiesInRadius(
        origin: enemy.position,
        radius: 52,
        damage: math.max(1, (damage * 0.35).ceil()),
        color: const Color(0xFF8FD7FF),
      );
    }
    if (level >= 4) {
      _chainThunder(enemy.position, maxTargets: 2);
    }
    if (_evolvedSkills.contains('evolve_thunder_chain') &&
        (enemy.enemyId == 'boss' || _enemyWaveGroup(enemy.enemyId) == 'tank')) {
      _chainThunder(enemy.position, maxTargets: 12, radius: 190);
    }
  }

  void _chainThunder(
    Vector2 origin, {
    int maxTargets = 2,
    double radius = 130,
  }) {
    final radiusSquared = radius * radius;
    var count = 0;
    for (final target in _nearbyEnemies(origin, radius)) {
      if (target.isDead ||
          target.position.distanceToSquared(origin) > radiusSquared) {
        continue;
      }
      target.takeDamage(
        math.max(1, (_weaponDamage * _thunderChainDamageMultiplier).ceil()),
      );
      _thunderStrikes.add(
        _ThunderStrike(position: target.position.clone(), radius: 26),
      );
      count++;
      if (count >= maxTargets) {
        break;
      }
    }
  }

  void _updateVoidMagnet(double dt) {
    final level = _skillLevel('void_magnet');
    if (level < 3 || _gems.isEmpty) {
      return;
    }

    var processedEnemies = 0;
    final maxProcessedEnemies = _gems.length > _softGemMergeCount ? 32 : 64;
    for (final enemy in _enemies) {
      if (enemy.isDead || enemy.enemyId == 'boss') {
        continue;
      }
      processedEnemies++;
      if (processedEnemies > maxProcessedEnemies) {
        break;
      }
      ExpGemComponent? nearestGem;
      var nearestDistance = double.infinity;
      for (final gem in _gems) {
        if (gem.isAttracted) {
          continue;
        }
        final distance = enemy.position.distanceToSquared(gem.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestGem = gem;
        }
      }
      if (nearestGem == null || nearestDistance > 120 * 120) {
        continue;
      }
      final direction = nearestGem.position - enemy.position;
      if (direction.length2 == 0) {
        continue;
      }
      direction.normalize();
      enemy.position += direction * 18 * dt;
    }
  }

  void _updateBlackHoles(double dt) {
    for (final field in _blackHoles) {
      field.age += dt;
      field.damageTimer -= dt;
      final radiusSquared = field.radius * field.radius;
      for (final enemy in _enemies) {
        if (enemy.isDead) {
          continue;
        }
        final distanceSquared = enemy.position.distanceToSquared(field.center);
        if (distanceSquared > radiusSquared) {
          continue;
        }
        final direction = field.center - enemy.position;
        if (direction.length2 > 0) {
          direction.normalize();
          final pull = enemy.enemyId == 'boss' ? field.pull * 0.2 : field.pull;
          enemy.position += direction * pull * dt;
        }
        if (field.damageTimer <= 0) {
          enemy.takeDamage(
            enemy.enemyId == 'boss'
                ? (field.damage * 0.45).ceil()
                : field.damage,
          );
        }
      }
      if (field.damageTimer <= 0) {
        field.damageTimer = 0.25;
      }
    }

    _finishedBlackHoleBuffer.clear();
    for (final field in _blackHoles) {
      if (field.isDone) {
        _finishedBlackHoleBuffer.add(field);
      }
    }
    for (final field in _finishedBlackHoleBuffer) {
      _damageEnemiesInRadius(
        origin: field.center,
        radius: field.radius * 0.82,
        damage: field.explosionDamage,
        color: field.color,
      );
      _addWorldPulse(
        position: field.center.clone(),
        color: field.color,
        maxRadius: field.radius,
      );
    }
    for (final field in _finishedBlackHoleBuffer) {
      _blackHoles.remove(field);
    }
    _finishedBlackHoleBuffer.clear();
  }

  void _updateUltimates(double dt) {
    switch (_ultimateSkillId) {
      case 'ultimate_star_judgement':
        _updateStarJudgement(dt);
      case 'ultimate_black_moon':
        _updateBlackMoon(dt);
      case 'ultimate_frost_inferno':
        _updateFrostInferno(dt);
    }
  }

  void _updateChargedUltimateBeams(double dt) {
    if (_chargedUltimateBeams.isEmpty) {
      return;
    }

    for (final beam in _chargedUltimateBeams) {
      beam.age += dt;
      beam.damageTimer -= dt;
      if (beam.damageTimer > 0) {
        continue;
      }
      beam.damageTimer = beam.damageInterval;
      _damageEnemiesInBeam(beam);
    }
    _chargedUltimateBeams.removeWhere((beam) => beam.isDone);
  }

  void _updateStarJudgement(double dt) {
    if (_starJudgementTimer <= 0) {
      _starJudgementCooldown -= dt;
      if (_starJudgementCooldown > 0) {
        return;
      }
      _starJudgementTimer = 5;
      _starJudgementTick = 0;
      _starJudgementCooldown = 22;
      _addWorldPulse(
        position: player.position.clone(),
        color: const Color(0xFF8FD7FF),
        maxRadius: 180,
      );
    }

    _starJudgementTimer -= dt;
    _starJudgementTick -= dt;
    if (_starJudgementTick > 0) {
      return;
    }
    _starJudgementTick = 0.35;
    final targets = _pickThunderTargets(count: 5);
    for (final target in targets) {
      _thunderStrikes.add(
        _ThunderStrike(position: target.position.clone(), radius: 70),
      );
      target.takeDamage(
        target.enemyId == 'boss'
            ? math.max(1, (_weaponDamage * 0.7).ceil())
            : math.max(2, (_weaponDamage * 2.0).ceil()),
      );
      _chainThunder(target.position, maxTargets: 3, radius: 95);
    }
  }

  void _updateBlackMoon(double dt) {
    _blackMoonCooldown -= dt;
    if (_blackMoonCooldown > 0) {
      return;
    }
    _blackMoonCooldown = 24;
    _blackHoles.add(
      _BlackHoleField(
        center: player.position.clone(),
        radius: 190,
        duration: 3,
        damage:
            math.max(2, (_weaponDamage * _blackMoonDamageMultiplier).ceil()),
        explosionDamage: math.max(
          8,
          (_weaponDamage * _blackMoonExplosionDamageMultiplier).ceil(),
        ),
        pull: 130,
        color: const Color(0xFFB68CFF),
      ),
    );
  }

  void _updateFrostInferno(double dt) {
    if (_frostInfernoTimer <= 0) {
      _frostInfernoCooldown -= dt;
      if (_frostInfernoCooldown > 0) {
        return;
      }
      _frostInfernoTimer = 5.2;
      _frostInfernoTick = 0;
      _frostInfernoCooldown = 18;
      _addWorldPulse(
        position: player.position.clone(),
        color: const Color(0xFFFFD36E),
        maxRadius: 210,
      );
    }

    _frostInfernoTimer -= dt;
    _frostInfernoTick -= dt;
    if (_frostInfernoTick > 0) {
      return;
    }
    _frostInfernoTick = 0.65;
    final target = _pickPoisonTarget();
    final center = target?.position.clone() ?? player.position.clone();
    _addFireField(center, level: math.max(5, _skillLevel('fire_trail')));
    _addGroundField(
      _GroundEffectField(
        type: _GroundEffectType.frostInferno,
        center: center,
        radius: 86,
        duration: 1.8,
        tickInterval: 0.34,
        damage: math.max(2, (_weaponDamage * 0.76).ceil()),
        bossDamageMultiplier: 0.45,
        color: const Color(0xFF9BD3FF),
      ),
    );
    _expandingRings.add(
      _ExpandingRing(
        center: center,
        radius: 118,
        color: const Color(0xFFC7F7FF),
        strokeWidth: 4,
      ),
    );
  }

  void _drawSkillEffects(Canvas canvas) {
    _drawMeleeSweepEffects(canvas);
    _drawDelayedWeaponBlastWarnings(canvas);
    _drawWeaponUltimateImages(canvas);
    _drawGroundFieldEffects(canvas);
    _drawOrbitBladeEffects(canvas);
    _drawThunderEffects(canvas);
    _drawBlackHoleEffects(canvas);
    _drawExpandingRings(canvas);
    _drawChargedUltimateBeams(canvas);
  }

  void _drawDelayedWeaponBlastWarnings(Canvas canvas) {
    for (final blast in _delayedWeaponBlasts) {
      if (blast.hasExploded) {
        continue;
      }
      final progress = blast.warningProgress;
      final center = Offset(blast.center.x, blast.center.y);
      final radius = blast.radius * (0.72 + progress * 0.28);
      final fillPaint = Paint()
        ..color = blast.color.withOpacity(0.10 + progress * 0.10)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = blast.color.withOpacity(0.45 + progress * 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 + progress * 2.2;
      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, strokePaint);
    }
  }

  void _drawWeaponUltimateImages(Canvas canvas) {
    final image = _projectileImage;
    for (final effect in _weaponUltimateImages) {
      final progress = effect.progress;
      final opacity = math.sin(progress * math.pi).clamp(0, 1).toDouble();
      final center = Offset(effect.center.x, effect.center.y);
      final size = effect.size * (0.82 + progress * 0.36);
      if (image == null) {
        canvas.drawCircle(
          center,
          size * 0.32,
          Paint()
            ..color = effect.color.withOpacity(0.64 * opacity)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          center,
          size * 0.46,
          Paint()
            ..color = effect.color.withOpacity(0.52 * opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        continue;
      }

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(effect.angle);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: size, height: size),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..blendMode = BlendMode.screen
          ..color = Color.fromRGBO(255, 255, 255, opacity),
      );
      canvas.restore();
      canvas.drawCircle(
        center,
        size * 0.52,
        Paint()
          ..color = effect.color.withOpacity(0.30 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2,
      );
    }
  }

  void _drawMeleeSweepEffects(Canvas canvas) {
    for (final sweep in _meleeSweeps) {
      final progress = sweep.progress;
      final opacity = math.sin(progress * math.pi).clamp(0, 1).toDouble();
      final startAngle =
          math.atan2(sweep.direction.y, sweep.direction.x) - sweep.arc / 2;
      final rect = Rect.fromCircle(
        center: Offset(sweep.origin.x, sweep.origin.y),
        radius: sweep.radius,
      );
      final glowPaint = Paint()
        ..color = sweep.color.withOpacity(0.24 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 18 * (1 - progress * 0.36);
      final edgePaint = Paint()
        ..color = const Color(0xFFFFF1A8).withOpacity(0.74 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.5;
      canvas.drawArc(rect, startAngle, sweep.arc, false, glowPaint);
      canvas.drawArc(rect, startAngle, sweep.arc, false, edgePaint);
    }
  }

  void _drawChargedUltimateBeams(Canvas canvas) {
    for (final beam in _chargedUltimateBeams) {
      final progress = beam.progress;
      final direction = beam.direction;
      final start = player.position + direction * 22;
      final end = start + direction * beam.length;
      final opacity = math.sin(progress * math.pi).clamp(0, 1).toDouble();
      final beamEffectImage = _ultimateBeamEffectImage;
      if (beamEffectImage != null) {
        _drawUltimateBeamEffectSprite(
          canvas,
          image: beamEffectImage,
          start: Offset(start.x, start.y),
          direction: direction,
          length: beam.length,
          width: beam.width,
          opacity: opacity,
          progress: progress,
        );
      }
      final glowPaint = Paint()
        ..color = beam.glowColor.withOpacity(0.34 * opacity)
        ..strokeWidth = beam.width * 1.65
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final bodyPaint = Paint()
        ..color = beam.bodyColor.withOpacity(0.78 * opacity)
        ..strokeWidth = beam.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final corePaint = Paint()
        ..color = beam.coreColor.withOpacity(0.88 * opacity)
        ..strokeWidth = beam.width * 0.34
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas
        ..drawLine(
          Offset(start.x, start.y),
          Offset(end.x, end.y),
          glowPaint,
        )
        ..drawLine(
          Offset(start.x, start.y),
          Offset(end.x, end.y),
          bodyPaint,
        )
        ..drawLine(
          Offset(start.x, start.y),
          Offset(end.x, end.y),
          corePaint,
        );
      canvas.drawCircle(
        Offset(start.x, start.y),
        beam.width * 0.78,
        Paint()
          ..color = beam.coreColor.withOpacity(0.68 * opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawUltimateBeamEffectSprite(
    Canvas canvas, {
    required Image image,
    required Offset start,
    required Vector2 direction,
    required double length,
    required double width,
    required double opacity,
    required double progress,
  }) {
    final frame = _effectFrameForProgress(
      progress,
      _ultimateBeamEffectGrid.frameCount,
    );
    final source = _effectFrameSource(image, _ultimateBeamEffectGrid, frame);
    final angle = math.atan2(direction.y, direction.x);
    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.rotate(angle);
    canvas.drawImageRect(
      image,
      source,
      Rect.fromLTWH(0, -width * 1.25, length, width * 2.5),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.screen
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
    canvas.restore();
  }

  void _drawGroundFieldEffects(Canvas canvas) {
    for (final field in _groundFields) {
      switch (field.type) {
        case _GroundEffectType.fire:
          _drawFireField(canvas, field);
        case _GroundEffectType.poison:
          _drawPoisonField(canvas, field);
        case _GroundEffectType.frostInferno:
          _drawFrostField(canvas, field);
      }
    }
  }

  void _drawFireField(Canvas canvas, _GroundEffectField field) {
    final center = Offset(field.center.x, field.center.y);
    final progress = field.progress;
    final opacity = (1 - progress * 0.68).clamp(0, 1).toDouble();
    final seed = _visualSeed(field);
    final pulse = math.sin(_elapsed * 8 + seed) * 0.08;
    final radius = field.radius * (0.94 + pulse);
    final fireEffectImage = _fireEffectImage;

    if (fireEffectImage != null) {
      _drawFireEffectSprite(
        canvas,
        image: fireEffectImage,
        center: center,
        radius: radius,
        opacity: opacity,
        seed: seed,
        isEvolved: field.tickInterval < 0.3,
      );
      return;
    }

    final emberPaint = Paint()
      ..color = const Color(0xFFFFD36E).withOpacity(0.75 * opacity)
      ..style = PaintingStyle.fill;
    final flamePaint = Paint()
      ..color = const Color(0xFFFF6B2D).withOpacity(0.68 * opacity)
      ..style = PaintingStyle.fill;
    final smokePaint = Paint()
      ..color = const Color(0x55331A12).withOpacity(0.22 * opacity)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 6; i++) {
      final angle = seed + i * 1.13 + math.sin(_elapsed * 1.7 + i) * 0.18;
      final distance = radius * (0.18 + 0.11 * (i % 4));
      final base = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final height = radius * (0.36 + 0.06 * (i % 3));
      final width = radius * 0.12;
      final tip = base +
          Offset(math.cos(angle - 1.35), math.sin(angle - 1.35)) * height;
      final path = Path()
        ..moveTo(base.dx - width, base.dy + width * 0.35)
        ..quadraticBezierTo(
          base.dx - width * 1.2,
          base.dy - height * 0.22,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          base.dx + width * 1.25,
          base.dy - height * 0.08,
          base.dx + width,
          base.dy + width * 0.36,
        )
        ..close();
      canvas.drawPath(path, flamePaint);
      if (i.isEven) {
        canvas.drawCircle(base, 2.2 + (i % 3), emberPaint);
      }
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius * 0.05),
        width: radius * 1.45,
        height: radius * 0.52,
      ),
      smokePaint,
    );
  }

  void _drawFireEffectSprite(
    Canvas canvas, {
    required Image image,
    required Offset center,
    required double radius,
    required double opacity,
    required double seed,
    required bool isEvolved,
  }) {
    final frame = (_elapsed * (isEvolved ? 15 : 10) + seed).floor() %
        _fireEffectGrid.frameCount;
    final source = _effectFrameSource(image, _fireEffectGrid, frame);
    final side = radius * (isEvolved ? 2.55 : 2.25);
    final destination = Rect.fromCenter(
      center: center.translate(0, -radius * 0.08),
      width: side,
      height: side,
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..blendMode = BlendMode.screen
      ..color = Color.fromRGBO(255, 255, 255, opacity);
    canvas.drawImageRect(image, source, destination, paint);
  }

  void _drawPoisonField(Canvas canvas, _GroundEffectField field) {
    final center = Offset(field.center.x, field.center.y);
    final progress = field.progress;
    final opacity = (1 - progress * 0.55).clamp(0, 1).toDouble();
    final seed = _visualSeed(field);
    final radius = field.radius * (0.92 + 0.06 * math.sin(_elapsed * 2 + seed));
    final poisonEffectImage = _poisonEffectImage;

    if (poisonEffectImage != null) {
      _drawPoisonEffectSprite(
        canvas,
        image: poisonEffectImage,
        center: center,
        radius: radius,
        opacity: opacity,
        seed: seed,
      );
      return;
    }

    _drawIrregularPatch(
      canvas,
      center: center,
      radius: radius,
      seed: seed,
      fill: Paint()
        ..color = const Color(0xFF245C2B).withOpacity(0.22 * opacity)
        ..style = PaintingStyle.fill,
      stroke: Paint()
        ..color = const Color(0xFF70E06B).withOpacity(0.42 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
      wobble: 0.28,
    );

    for (var i = 0; i < 9; i++) {
      final angle = seed + i * 2.39;
      final drift = math.sin(_elapsed * (0.9 + i * 0.07) + i) * 5;
      final distance = radius * (0.18 + (i % 5) * 0.12);
      final bubbleCenter = center +
          Offset(math.cos(angle), math.sin(angle)) * distance +
          Offset(math.cos(angle + 1.8), math.sin(angle + 1.8)) * drift;
      final bubbleRadius = radius * (0.055 + (i % 3) * 0.018);
      canvas.drawCircle(
        bubbleCenter,
        bubbleRadius,
        Paint()
          ..color = const Color(0xFFB8FF8A).withOpacity(0.20 * opacity)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        bubbleCenter,
        bubbleRadius,
        Paint()
          ..color = const Color(0xFF7DFF72).withOpacity(0.34 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _drawPoisonEffectSprite(
    Canvas canvas, {
    required Image image,
    required Offset center,
    required double radius,
    required double opacity,
    required double seed,
  }) {
    final frame =
        ((_elapsed * 11 + seed) * 1.4).floor() % _poisonEffectGrid.frameCount;
    final source = _effectFrameSource(image, _poisonEffectGrid, frame);
    final side = radius * 2.5;
    canvas.drawImageRect(
      image,
      source,
      Rect.fromCenter(
        center: center.translate(0, -radius * 0.08),
        width: side,
        height: side,
      ),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.screen
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
  }

  void _drawFrostField(Canvas canvas, _GroundEffectField field) {
    final center = Offset(field.center.x, field.center.y);
    final progress = field.progress;
    final opacity = (1 - progress * 0.55).clamp(0, 1).toDouble();
    final seed = _visualSeed(field);
    final radius = field.radius * (0.96 + 0.04 * math.sin(_elapsed * 3 + seed));
    final iceEffectImage = _iceEffectImage;

    if (iceEffectImage != null) {
      _drawIceEffectSprite(
        canvas,
        image: iceEffectImage,
        center: center,
        radius: radius,
        opacity: opacity,
        seed: seed,
        progress: progress,
        isField: true,
      );
      return;
    }

    _drawIrregularPatch(
      canvas,
      center: center,
      radius: radius,
      seed: seed,
      fill: Paint()
        ..color = const Color(0xFF8FD7FF).withOpacity(0.18 * opacity)
        ..style = PaintingStyle.fill,
      stroke: Paint()
        ..color = const Color(0xFFC7F7FF).withOpacity(0.60 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
      wobble: 0.16,
    );

    final crackPaint = Paint()
      ..color = const Color(0xFFE8FFF2).withOpacity(0.62 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;
    for (var i = 0; i < 7; i++) {
      final angle = seed + i * math.pi * 2 / 7;
      final start = center +
          Offset(math.cos(angle), math.sin(angle)) *
              radius *
              (0.18 + 0.03 * (i % 2));
      final mid = center +
          Offset(math.cos(angle + 0.14), math.sin(angle + 0.14)) *
              radius *
              0.48;
      final end = center +
          Offset(math.cos(angle - 0.09), math.sin(angle - 0.09)) *
              radius *
              0.82;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(path, crackPaint);

      final branchAngle = angle + (i.isEven ? 0.72 : -0.72);
      final branchEnd = mid +
          Offset(math.cos(branchAngle), math.sin(branchAngle)) * radius * 0.18;
      canvas.drawLine(mid, branchEnd, crackPaint);
    }
  }

  void _drawIceEffectSprite(
    Canvas canvas, {
    required Image image,
    required Offset center,
    required double radius,
    required double opacity,
    required double seed,
    required double progress,
    required bool isField,
  }) {
    final frame =
        (progress.clamp(0, 1) * _iceEffectGrid.frameCount + seed.floor())
                .floor() %
            _iceEffectGrid.frameCount;
    final source = _effectFrameSource(image, _iceEffectGrid, frame);
    final frameWidth = source.width;
    final frameHeight = source.height;
    final side = radius * (isField ? 2.55 : 2.25);
    final destination = Rect.fromCenter(
      center: center.translate(0, -radius * (isField ? 0.16 : 0.08)),
      width: side,
      height: side * frameHeight / frameWidth,
    );
    canvas.drawImageRect(
      image,
      source,
      destination,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.screen
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
  }

  void _drawIrregularPatch(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double seed,
    required Paint fill,
    required Paint stroke,
    double wobble = 0.22,
  }) {
    const points = 18;
    final path = Path();
    for (var i = 0; i < points; i++) {
      final angle = math.pi * 2 * i / points;
      final noise = math.sin(seed + i * 1.91 + _elapsed * 0.9) * wobble +
          math.cos(seed * 0.7 + i * 2.73) * wobble * 0.55;
      final nextRadius = radius * (1 + noise);
      final point = center +
          Offset(math.cos(angle), math.sin(angle)) *
              nextRadius.clamp(radius * 0.68, radius * 1.22);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  double _visualSeed(_GroundEffectField field) {
    return (field.center.x * 0.013 + field.center.y * 0.017 + field.radius)
        .abs();
  }

  int _effectFrameForProgress(double progress, int frameCount) {
    return (progress.clamp(0, 1) * frameCount)
        .floor()
        .clamp(0, frameCount - 1)
        .toInt();
  }

  Rect _effectFrameSource(
    Image image,
    _EffectFrameGrid grid,
    int frame,
  ) {
    final safeFrame = frame.clamp(0, grid.frameCount - 1).toInt();
    final column = safeFrame % grid.columns;
    final row = safeFrame ~/ grid.columns;
    final frameWidth = image.width / grid.columns;
    final frameHeight = image.height / grid.rows;
    final left = column * frameWidth;
    final top = row * frameHeight;
    final right = column == grid.columns - 1
        ? image.width.toDouble()
        : (column + 1) * frameWidth;
    final bottom = row == grid.rows - 1
        ? image.height.toDouble()
        : (row + 1) * frameHeight;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _drawExpandingRings(Canvas canvas) {
    for (final ring in _expandingRings) {
      final progress = ring.progress;
      final center = Offset(ring.center.x, ring.center.y);
      final radius = ring.radius * progress;
      final iceEffectImage = _iceEffectImage;
      if (iceEffectImage != null) {
        _drawIceEffectSprite(
          canvas,
          image: iceEffectImage,
          center: center,
          radius: math.max(18, radius),
          opacity: (1 - progress * 0.28).clamp(0, 1).toDouble(),
          seed: ring.radius,
          progress: progress,
          isField: false,
        );
        continue;
      }
      final paint = Paint()
        ..color = ring.color.withOpacity((1 - progress) * 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.strokeWidth;
      canvas.drawCircle(center, radius, paint);

      final shardPaint = Paint()
        ..color = const Color(0xFFE8FFF2).withOpacity((1 - progress) * 0.58)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.4;
      for (var i = 0; i < 10; i++) {
        final angle = i * math.pi * 2 / 10 + progress * 0.18;
        final inner =
            center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.82;
        final outer =
            center + Offset(math.cos(angle), math.sin(angle)) * radius * 1.04;
        canvas.drawLine(inner, outer, shardPaint);
      }
    }
  }

  void _drawOrbitBladeEffects(Canvas canvas) {
    final level = _skillLevel('orbit_blade');
    if (level <= 0) {
      return;
    }
    final bladeCount = 1 + (level >= 2 ? 1 : 0);
    final stormPhase =
        _evolvedSkills.contains('evolve_moon_wheel') && _moonWheelTimer <= 2.4;
    final radius = stormPhase
        ? 70 + 80 * math.sin((_moonWheelTimer / 2.4) * math.pi)
        : 70 * (level >= 5 ? 1.22 : 1.0);
    final orbitPaint = Paint()
      ..color = (level >= 5 ? const Color(0x88C7F7FF) : const Color(0x55C7F7FF))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stormPhase ? 4 : 2;
    if (level >= 3 || stormPhase) {
      canvas.drawCircle(
        Offset(player.position.x, player.position.y),
        radius,
        orbitPaint,
      );
    }
    final bladePaint = Paint()
      ..color = level >= 5 ? const Color(0xFFFFFFFF) : const Color(0xFFE8FFF2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stormPhase ? 9 : 7;
    final trailPaint = Paint()
      ..color = const Color(0x66C7F7FF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stormPhase ? 13 : 10;
    final orbitBladeEffectImage = _orbitBladeEffectImage;
    for (var i = 0; i < bladeCount; i++) {
      final angle = _orbitAngle + math.pi * 2 * i / bladeCount;
      final rect = Rect.fromCircle(
        center: Offset(player.position.x, player.position.y),
        radius: radius,
      );
      if (orbitBladeEffectImage != null) {
        _drawOrbitBladeEffectSprite(
          canvas,
          image: orbitBladeEffectImage,
          center: Offset(player.position.x, player.position.y),
          radius: radius,
          angle: angle,
          size: stormPhase ? 58 : 42,
          opacity: stormPhase ? 0.86 : 0.68,
        );
      }
      if (level >= 5 || stormPhase) {
        canvas.drawArc(rect, angle - 0.72, 0.86, false, trailPaint);
      }
      canvas.drawArc(
          rect, angle - 0.42, stormPhase ? 0.62 : 0.48, false, bladePaint);
    }
  }

  void _drawOrbitBladeEffectSprite(
    Canvas canvas, {
    required Image image,
    required Offset center,
    required double radius,
    required double angle,
    required double size,
    required double opacity,
  }) {
    final frame = ((_elapsed * 18).floor()) % _orbitBladeEffectGrid.frameCount;
    final source = _effectFrameSource(image, _orbitBladeEffectGrid, frame);
    final position = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle + math.pi / 2);
    canvas.drawImageRect(
      image,
      source,
      Rect.fromCenter(center: Offset.zero, width: size, height: size),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.screen
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
    canvas.restore();
  }

  void _drawThunderEffects(Canvas canvas) {
    for (final strike in _thunderStrikes) {
      final opacity = (1 - strike.progress).clamp(0, 1).toDouble();
      final thunderEffectImage = _thunderEffectImage;
      if (thunderEffectImage != null) {
        _drawThunderEffectSprite(
          canvas,
          image: thunderEffectImage,
          strike: strike,
          opacity: opacity,
        );
        continue;
      }
      final paint = Paint()
        ..color = const Color(0xFF8FD7FF).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final x = strike.position.x;
      final y = strike.position.y;
      _drawJaggedLightning(
        canvas,
        start: Offset(x - 18, y - 170),
        end: Offset(x, y),
        paint: paint,
        seed: x.floor() ^ y.floor(),
      );
      canvas.drawCircle(Offset(x, y), strike.radius * strike.progress, paint);
    }
  }

  void _drawThunderEffectSprite(
    Canvas canvas, {
    required Image image,
    required _ThunderStrike strike,
    required double opacity,
  }) {
    final frame = _effectFrameForProgress(
      strike.progress,
      _thunderEffectGrid.frameCount,
    );
    final source = _effectFrameSource(image, _thunderEffectGrid, frame);
    final height = 180.0 + strike.radius * 0.65;
    final width = math.max(58.0, strike.radius * 1.2);
    final center = Offset(strike.position.x, strike.position.y - height * 0.42);
    final destination = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..blendMode = BlendMode.screen
      ..color = Color.fromRGBO(255, 255, 255, opacity);
    canvas.drawImageRect(image, source, destination, paint);

    final burstPaint = Paint()
      ..color = const Color(0xFFFFF2A6).withOpacity(0.46 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      Offset(strike.position.x, strike.position.y),
      strike.radius * strike.progress,
      burstPaint,
    );
  }

  void _drawJaggedLightning(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required Paint paint,
    required int seed,
  }) {
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 1; i <= 4; i++) {
      final t = i / 5;
      final base = Offset.lerp(start, end, t)!;
      final wobble = (((seed + i * 37) % 17) - 8) * 1.8;
      path.lineTo(base.dx + wobble, base.dy);
    }
    path.lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  void _drawBlackHoleEffects(Canvas canvas) {
    for (final field in _blackHoles) {
      final progress = field.progress;
      final fill = Paint()
        ..color = field.color.withOpacity(0.16 + 0.1 * math.sin(progress * 18))
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = field.color.withOpacity(0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      final center = Offset(field.center.x, field.center.y);
      final blackHoleEffectImage = _blackHoleEffectImage;
      if (blackHoleEffectImage != null) {
        _drawBlackHoleEffectSprite(
          canvas,
          image: blackHoleEffectImage,
          center: center,
          radius: field.radius,
          progress: progress,
          opacity: 0.9,
        );
      }
      canvas.drawCircle(
        center,
        field.radius * (0.82 + 0.18 * math.sin(progress * math.pi)),
        fill,
      );
      canvas.drawCircle(
        center,
        field.radius * 0.22,
        Paint()
          ..color = const Color(0xCC050611)
          ..style = PaintingStyle.fill,
      );
      final arcPaint = Paint()
        ..color = field.color.withOpacity(0.82)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5;
      final rect = Rect.fromCircle(center: center, radius: field.radius * 0.72);
      for (var i = 0; i < 3; i++) {
        canvas.drawArc(
          rect.inflate(i * 12),
          _elapsed * (1.1 + i * 0.18) + i * 2.1,
          0.72,
          false,
          arcPaint,
        );
      }
      canvas.drawCircle(
        center,
        field.radius,
        stroke,
      );
    }
  }

  void _drawBlackHoleEffectSprite(
    Canvas canvas, {
    required Image image,
    required Offset center,
    required double radius,
    required double progress,
    required double opacity,
  }) {
    final frame =
        ((_elapsed * 16 + progress * _blackHoleEffectGrid.frameCount).floor()) %
            _blackHoleEffectGrid.frameCount;
    final source = _effectFrameSource(image, _blackHoleEffectGrid, frame);
    final side = radius * 2.35;
    canvas.drawImageRect(
      image,
      source,
      Rect.fromCenter(center: center, width: side, height: side),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.screen
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
  }

  int _skillLevel(String treeId) => _skillLevels[treeId] ?? 0;

  void _damageEnemiesInRadius({
    required Vector2 origin,
    required double radius,
    required int damage,
    required Color color,
    double bossDamageMultiplier = 0.45,
    double slowMultiplier = 1,
    double slowDuration = 0,
    double knockback = 0,
  }) {
    final radiusSquared = radius * radius;
    var hitCount = 0;
    for (final enemy in _nearbyEnemies(origin, radius)) {
      if (enemy.isDead ||
          enemy.position.distanceToSquared(origin) > radiusSquared) {
        continue;
      }
      enemy.takeDamage(
        enemy.enemyId == 'boss'
            ? math.max(1, (damage * bossDamageMultiplier).ceil())
            : damage,
      );
      if (slowMultiplier < 1 && slowDuration > 0) {
        enemy.applySlow(multiplier: slowMultiplier, duration: slowDuration);
      }
      if (knockback > 0) {
        final direction = enemy.position - origin;
        if (direction.length2 > 0.0001) {
          direction.normalize();
          final push = enemy.enemyId == 'boss' ? knockback * 0.24 : knockback;
          enemy.position += direction * push;
        }
      }
      hitCount++;
    }
    if (hitCount == 0) {
      return;
    }
    _addWorldPulse(
      position: origin.clone(),
      color: color,
      maxRadius: radius,
    );
  }

  void _damageEnemiesAlongLine({
    required Vector2 direction,
    required double length,
    required double width,
    required int damage,
    required Color color,
    double bossDamageMultiplier = 0.45,
    double slowMultiplier = 1,
    double slowDuration = 0,
  }) {
    if (direction.length2 == 0) {
      return;
    }
    final normalized = direction.normalized();
    final start = player.position + normalized * 28;
    final end = start + normalized * length;
    final hitRadius = math.max(6, width * 0.5);
    var hitCount = 0;

    for (final enemy in _nearbyEnemies(player.position, length + hitRadius)) {
      if (enemy.isDead) {
        continue;
      }
      final distanceSquared =
          _distanceToSegmentSquared(enemy.position, start, end);
      final combinedRadius = hitRadius + enemy.collisionRadius;
      if (distanceSquared > combinedRadius * combinedRadius) {
        continue;
      }
      enemy.takeDamage(
        enemy.enemyId == 'boss'
            ? math.max(1, (damage * bossDamageMultiplier).ceil())
            : damage,
      );
      if (slowMultiplier < 1 && slowDuration > 0) {
        enemy.applySlow(multiplier: slowMultiplier, duration: slowDuration);
      }
      hitCount++;
    }

    if (hitCount == 0) {
      return;
    }
    _addWorldPulse(
      position: start + normalized * math.min(length * 0.55, 260),
      color: color,
      maxRadius: math.max(26, width * 1.5),
    );
  }

  void _damageEnemiesInBeam(_ChargedUltimateBeam beam) {
    final direction = beam.direction;
    final start = player.position + direction * 24;
    final end = start + direction * beam.length;
    final radius = beam.width * 0.5;
    var hitCount = 0;

    for (final enemy in _nearbyEnemies(player.position, beam.length + radius)) {
      if (enemy.isDead) {
        continue;
      }
      final hitRadius = radius + enemy.collisionRadius;
      final distanceSquared =
          _distanceToSegmentSquared(enemy.position, start, end);
      if (distanceSquared > hitRadius * hitRadius) {
        continue;
      }
      final damage = math.max(
        1,
        (enemy.hp *
                (enemy.enemyId == 'boss'
                    ? beam.bossHpDamageRatio
                    : beam.normalHpDamageRatio))
            .ceil(),
      );
      enemy.takeDamage(damage);
      hitCount++;
    }

    if (hitCount == 0) {
      return;
    }
    _addWorldPulse(
      position: start + direction * math.min(beam.length * 0.55, 260),
      color: beam.pulseColor,
      maxRadius: beam.width * 2.4,
    );
  }

  double _distanceToSegmentSquared(Vector2 point, Vector2 start, Vector2 end) {
    final segment = end - start;
    final segmentLengthSquared = segment.length2;
    if (segmentLengthSquared <= 0.0001) {
      return point.distanceToSquared(start);
    }
    final t = ((point - start).dot(segment) / segmentLengthSquared)
        .clamp(0, 1)
        .toDouble();
    final projection = start + segment * t;
    return point.distanceToSquared(projection);
  }

  void _damageNearestEnemy({
    required Vector2 origin,
    required EnemyComponent exclude,
    required double radius,
    required int damage,
    required Color color,
  }) {
    final radiusSquared = radius * radius;
    EnemyComponent? nearest;
    var nearestDistance = double.infinity;
    for (final enemy in _nearbyEnemies(origin, radius)) {
      if (enemy.isDead || identical(enemy, exclude)) {
        continue;
      }
      final distance = enemy.position.distanceToSquared(origin);
      if (distance > radiusSquared || distance >= nearestDistance) {
        continue;
      }
      nearest = enemy;
      nearestDistance = distance;
    }
    if (nearest == null) {
      return;
    }
    nearest.takeDamage(damage);
    _addWorldPulse(
      position: nearest.position.clone(),
      color: color,
      maxRadius: 28,
    );
  }

  void _cleanupDefeatedEnemies() {
    _deadEnemyBuffer.clear();
    for (final enemy in _enemies) {
      if (enemy.isDead) {
        _deadEnemyBuffer.add(enemy);
      }
    }
    for (final enemy in _deadEnemyBuffer) {
      if (enemy.enemyId == 'boss') {
        _collectDefeatedEnemy(enemy);
        _finishFlashTimer = 1;
        _finish(isWin: true);
        return;
      }
    }
    for (final enemy in _deadEnemyBuffer) {
      _collectDefeatedEnemy(enemy);
    }
    _deadEnemyBuffer.clear();
  }

  void _collectDefeatedEnemy(EnemyComponent enemy) {
    _killCount++;
    if (_evolvedSkills.contains('evolve_corrosive_plague') &&
        enemy.enemyId != 'boss' &&
        _poisonedEnemies.contains(enemy)) {
      _addPoisonField(
        enemy.position.clone(),
        level: math.max(1, _skillLevel('poison_spore')),
        small: true,
      );
    }
    _poisonedEnemies.remove(enemy);
    _spawnGem(enemy);
    _enemies.remove(enemy);
    enemy.removeFromParent();
  }

  void _resolveEnemySeparation() {
    for (var i = 0; i < _enemies.length; i++) {
      final first = _enemies[i];
      if (first.isDead) {
        continue;
      }
      final queryRadius = first.collisionRadius + 36;
      for (final second in _nearbyEnemies(first.position, queryRadius)) {
        if (identical(first, second) ||
            second.isDead ||
            identityHashCode(first) >= identityHashCode(second)) {
          continue;
        }
        final minDistance = first.collisionRadius + second.collisionRadius + 2;
        final delta = second.position - first.position;
        final distanceSquared = delta.length2;
        if (distanceSquared >= minDistance * minDistance) {
          continue;
        }

        final direction = _safeDirection(delta, i + identityHashCode(second));
        final distance =
            distanceSquared <= 0 ? 0.0 : math.sqrt(distanceSquared);
        final push = (minDistance - distance) / 2;
        first.position -= direction * push;
        second.position += direction * push;
      }
    }
  }

  void _resolveEnemyPlayerSeparation() {
    var i = 0;
    for (final enemy in _nearbyEnemies(player.position, 96)) {
      if (enemy.isDead) {
        continue;
      }
      final minDistance = enemy.collisionRadius + player.collisionRadius;
      final delta = enemy.position - player.position;
      final distanceSquared = delta.length2;
      if (distanceSquared >= minDistance * minDistance) {
        continue;
      }

      final direction = _safeDirection(delta, i);
      final distance = distanceSquared <= 0 ? 0.0 : math.sqrt(distanceSquared);
      final push = minDistance - distance;
      enemy.position += direction * push;
      i++;
    }
  }

  Vector2 _safeDirection(Vector2 delta, int seed) {
    if (delta.length2 > 0.0001) {
      return delta.normalized();
    }

    final angle = (seed * 0.61803398875) * math.pi * 2;
    return Vector2(math.cos(angle), math.sin(angle));
  }

  void _resolveProjectileHits() {
    _removedProjectileBuffer.clear();
    _removedEnemyBuffer.clear();

    for (final projectile in _projectiles) {
      if (projectile.isDone ||
          projectile.hasExceededRange ||
          projectile.age > _projectileMaxAge(projectile) ||
          (projectile.motionType != ProjectileMotionType.bouncing &&
              !_isInsideProjectileBounds(projectile))) {
        _markProjectileForRemoval(projectile);
        continue;
      }

      for (final enemy in _nearbyEnemies(projectile.position, 80)) {
        if (enemy.isDead) {
          continue;
        }
        final hitDistance = projectile.radius + enemy.collisionRadius;
        if (projectile.position.distanceToSquared(enemy.position) >
            hitDistance * hitDistance) {
          continue;
        }
        if (!projectile.canHit(enemy)) {
          continue;
        }
        projectile.markHit(enemy);

        final hitDamage =
            projectile.motionType == ProjectileMotionType.boomerang &&
                    projectile.isReturning
                ? math.max(1, (projectile.damage * 0.74).ceil())
                : projectile.damage;
        enemy.takeDamage(hitDamage);
        if (projectile.skillTag == 'weapon_explosion' &&
            _weaponAreaRadius > 0) {
          _damageEnemiesInRadius(
            origin: enemy.position,
            radius: _weaponAreaRadius,
            damage: math.max(1, (projectile.damage * 0.65).ceil()),
            color: const Color(0xFFFF8A4C),
          );
        }
        if (projectile.skillTag == 'weapon_chain') {
          _damageNearestEnemy(
            origin: enemy.position,
            exclude: enemy,
            radius: math.max(96, _weaponAreaRadius),
            damage: math.max(1, (projectile.damage * 0.62).ceil()),
            color: const Color(0xFFB68CFF),
          );
        }
        if (projectile.skillTag == 'weapon_bounce') {
          _damageNearestEnemy(
            origin: enemy.position,
            exclude: enemy,
            radius: math.max(82, _weaponAreaRadius),
            damage: math.max(1, (projectile.damage * 0.52).ceil()),
            color: const Color(0xFFFFC857),
          );
        }
        if (projectile.skillTag == 'weapon_boomerang' &&
            _weaponAreaRadius > 0) {
          _damageEnemiesInRadius(
            origin: enemy.position,
            radius: _weaponAreaRadius,
            damage: math.max(1, (projectile.damage * 0.38).ceil()),
            color: const Color(0xFFFFD36E),
            bossDamageMultiplier: 0.34,
          );
        }
        if (projectile.skillTag == 'star_projectile' &&
            _skillLevel('star_projectile') >= 2) {
          _damageNearestEnemy(
            origin: enemy.position,
            exclude: enemy,
            radius: 90,
            damage: math.max(1, (projectile.damage * 0.55).ceil()),
            color: const Color(0xFF8FD7FF),
          );
        }
        if (enemy.isDead) {
          _addWorldPulse(
            position: enemy.position.clone(),
            color: enemy.enemyId == 'boss'
                ? const Color(0xFFFF5B6F)
                : const Color(0xFF8FE388),
            maxRadius: enemy.enemyId == 'boss' ? 112 : 34,
          );
          _removedEnemyBuffer.add(enemy);
          if (enemy.enemyId == 'boss') {
            _collectDefeatedEnemy(enemy);
            _finishFlashTimer = 1;
            _finish(isWin: true);
            return;
          }
        }
        if (projectile.pierceRemaining > 0) {
          projectile.pierceRemaining--;
          continue;
        }
        if (projectile.motionType == ProjectileMotionType.bouncing ||
            projectile.motionType == ProjectileMotionType.boomerang) {
          continue;
        }
        _markProjectileForRemoval(projectile);
        break;
      }
    }

    for (final projectile in _removedProjectileBuffer) {
      _projectiles.remove(projectile);
      projectile.removeFromParent();
    }
    _deadEnemyBuffer
      ..clear()
      ..addAll(_removedEnemyBuffer);
    for (final enemy in _enemies) {
      if (enemy.isDead && !_deadEnemyBuffer.contains(enemy)) {
        _deadEnemyBuffer.add(enemy);
      }
    }
    for (final enemy in _deadEnemyBuffer) {
      if (enemy.enemyId == 'boss') {
        _collectDefeatedEnemy(enemy);
        _finishFlashTimer = 1;
        _finish(isWin: true);
        return;
      }
    }
    for (final enemy in _deadEnemyBuffer) {
      _collectDefeatedEnemy(enemy);
    }
    _removedProjectileBuffer.clear();
    _removedEnemyBuffer.clear();
    _deadEnemyBuffer.clear();
  }

  void _markProjectileForRemoval(ProjectileComponent projectile) {
    if (!_removedProjectileBuffer.contains(projectile)) {
      _removedProjectileBuffer.add(projectile);
    }
  }

  bool _isInsideProjectileBounds(ProjectileComponent projectile) {
    const margin = 80.0;
    final left = player.position.x - size.x / 2 - margin;
    final right = player.position.x + size.x / 2 + margin;
    final top = player.position.y - size.y / 2 - margin;
    final bottom = player.position.y + size.y / 2 + margin;
    return projectile.position.x >= left &&
        projectile.position.x <= right &&
        projectile.position.y >= top &&
        projectile.position.y <= bottom;
  }

  double _projectileMaxAge(ProjectileComponent projectile) {
    return switch (projectile.motionType) {
      ProjectileMotionType.bouncing => 3.2,
      ProjectileMotionType.boomerang => 2.6,
      ProjectileMotionType.straight => 1.8,
    };
  }

  void _spawnGem(EnemyComponent enemy) {
    final expDrop = _rollExpDrop(enemy);
    _spawnDrop(
      position: _randomDropPosition(enemy.position),
      exp: expDrop.value,
      coins: 0,
      healing: 0,
      expTier: expDrop.tier,
      coinTier: DropVisualTier.normal,
    );

    final coinDrop = _rollCoinDrop(enemy);
    if (coinDrop.value > 0) {
      _spawnDrop(
        position: _randomDropPosition(enemy.position),
        exp: 0,
        coins: coinDrop.value,
        healing: 0,
        expTier: DropVisualTier.normal,
        coinTier: coinDrop.tier,
      );
    }

    final healing = _rollHealthPackDrop(enemy);
    if (healing <= 0) {
      return;
    }

    _spawnDrop(
      position: _randomDropPosition(enemy.position),
      exp: 0,
      coins: 0,
      healing: healing,
      expTier: DropVisualTier.normal,
      coinTier: DropVisualTier.normal,
    );
  }

  void _spawnDrop({
    required Vector2 position,
    required int exp,
    required int coins,
    required int healing,
    required DropVisualTier expTier,
    required DropVisualTier coinTier,
  }) {
    if (exp <= 0 && coins <= 0 && healing <= 0) {
      return;
    }
    final payloadKind = _payloadKindForDrop(
      exp: exp,
      coins: coins,
      healing: healing,
    );
    final mergeTarget = _findMergeTarget(position, payloadKind: payloadKind);
    if (mergeTarget != null) {
      mergeTarget.absorb(
        addedExp: exp,
        addedCoins: coins,
        addedHealing: healing,
        addedExpTier: expTier,
        addedCoinTier: coinTier,
      );
      return;
    }

    final drop = ExpGemComponent(
      exp: exp,
      coins: coins,
      healing: healing,
      icons: _dropIcons,
      expTier: expTier,
      coinTier: coinTier,
      position: position,
    );
    _gems.add(drop);
    add(drop);
    if (_gems.length > _maxGemCount) {
      _compactOldestDrop(payloadKind: payloadKind);
    }
  }

  ExpGemComponent? _findMergeTarget(
    Vector2 position, {
    required DropPayloadKind payloadKind,
  }) {
    const mergeRadiusSquared = _gemMergeRadius * _gemMergeRadius;
    var checked = 0;
    for (var i = _gems.length - 1; i >= 0; i--) {
      checked++;
      if (checked > 64 && _gems.length < _softGemMergeCount) {
        break;
      }
      final gem = _gems[i];
      if (gem.payloadKind != payloadKind || gem.isAttracted) {
        continue;
      }
      if (gem.position.distanceToSquared(position) > mergeRadiusSquared &&
          _gems.length < _softGemMergeCount) {
        continue;
      }
      return gem;
    }
    return null;
  }

  void _compactOldestDrop({required DropPayloadKind payloadKind}) {
    ExpGemComponent? oldest;
    for (final gem in _gems) {
      if (gem.payloadKind == payloadKind && !gem.isAttracted) {
        oldest = gem;
        break;
      }
    }
    if (oldest == null || identical(oldest, _gems.last)) {
      return;
    }
    final newest = _gems.last;
    newest.absorb(
      addedExp: oldest.exp,
      addedCoins: oldest.coins,
      addedHealing: oldest.healing,
      addedExpTier: oldest.expTier,
      addedCoinTier: oldest.coinTier,
    );
    _gems.remove(oldest);
    oldest.removeFromParent();
  }

  DropPayloadKind _payloadKindForDrop({
    required int exp,
    required int coins,
    required int healing,
  }) {
    if (exp > 0) {
      return DropPayloadKind.exp;
    }
    if (coins > 0) {
      return DropPayloadKind.coin;
    }
    return DropPayloadKind.health;
  }

  _DropRoll _rollExpDrop(EnemyComponent enemy) {
    if (isDeathmatch && enemy.enemyId.startsWith('guaishou_')) {
      final roll = _random.nextDouble();
      if (roll < 0.22) {
        return _DropRoll(enemy.expDrop * 3, DropVisualTier.rare);
      }
      return _DropRoll(enemy.expDrop * 2, DropVisualTier.high);
    }
    if (enemy.enemyId == 'boss') {
      return _DropRoll(enemy.expDrop, DropVisualTier.rare);
    }
    if (stageChapter == 1 && stageIndex == 1 && _killCount <= 10) {
      return _DropRoll(enemy.expDrop, DropVisualTier.normal);
    }

    final roll = _random.nextDouble();
    if (roll < _expRareDropChance) {
      return _DropRoll(enemy.expDrop * 4, DropVisualTier.rare);
    }
    if (roll < _expRareDropChance + _expHighDropChance) {
      return _DropRoll(enemy.expDrop * 2, DropVisualTier.high);
    }
    return _DropRoll(enemy.expDrop, DropVisualTier.normal);
  }

  _DropRoll _rollCoinDrop(EnemyComponent enemy) {
    if (isDeathmatch && enemy.enemyId.startsWith('guaishou_')) {
      final roll = _random.nextDouble();
      if (roll < _deathmatchRareCoinDropChance) {
        return _DropRoll(10 + _random.nextInt(8), DropVisualTier.rare);
      }
      if (roll <
          _deathmatchRareCoinDropChance + _deathmatchHighCoinDropChance) {
        return _DropRoll(5 + _random.nextInt(5), DropVisualTier.high);
      }
      return const _DropRoll(0, DropVisualTier.high);
    }
    if (enemy.enemyId == 'boss') {
      return _DropRoll(
        _bossCoinDropMin +
            _random.nextInt(_bossCoinDropMax - _bossCoinDropMin + 1),
        DropVisualTier.rare,
      );
    }
    return switch (_enemyWaveGroup(enemy.enemyId)) {
      'tank' => _rollCoinByChance(
          chance: _tankCoinDropChance,
          min: 5,
          max: 8,
          tier: DropVisualTier.high,
        ),
      'fast' => _rollCoinByChance(
          chance: _fastCoinDropChance,
          min: 2,
          max: 4,
          tier: DropVisualTier.normal,
        ),
      _ => _rollCoinByChance(
          chance: _basicCoinDropChance,
          min: 1,
          max: 2,
          tier: DropVisualTier.normal,
        ),
    };
  }

  _DropRoll _rollCoinByChance({
    required double chance,
    required int min,
    required int max,
    required DropVisualTier tier,
  }) {
    if (_random.nextDouble() >= chance) {
      return const _DropRoll(0, DropVisualTier.normal);
    }
    final value = min + _random.nextInt(max - min + 1);
    final visualTier = value >= 8
        ? DropVisualTier.rare
        : value >= 4
            ? DropVisualTier.high
            : tier;
    return _DropRoll(value, visualTier);
  }

  int _rollHealthPackDrop(EnemyComponent enemy) {
    if (enemy.enemyId == 'boss') {
      return 0;
    }
    final chance = isDeathmatch && enemy.enemyId.startsWith('guaishou_')
        ? _deathmatchHealthPackDropChance
        : switch (_enemyWaveGroup(enemy.enemyId)) {
            'tank' => _tankHealthPackDropChance,
            'fast' => _fastHealthPackDropChance,
            _ => _basicHealthPackDropChance,
          };
    return _random.nextDouble() < chance ? _healthPackHealAmount : 0;
  }

  Vector2 _randomDropPosition(Vector2 origin) {
    final angle = _random.nextDouble() * math.pi * 2;
    final distance = 8 + _random.nextDouble() * 22;
    return origin + Vector2(math.cos(angle), math.sin(angle)) * distance;
  }

  void _resolvePlayerHits() {
    for (final enemy in _nearbyEnemies(player.position, 96)) {
      final hitDistance = enemy.collisionRadius + player.collisionRadius;
      if (enemy.position.distanceToSquared(player.position) >
          hitDistance * hitDistance) {
        continue;
      }
      if (player.takeDamage(_randomEnemyDamage(enemy))) {
        enemy.triggerAttackAnimation();
        _damageFlashTimer = 0.35;
        _addWorldPulse(
          position: player.position.clone(),
          color: const Color(0xFFFF5B6F),
          maxRadius: 58,
        );
        if (player.isDead) {
          _playHaptic(_GameHaptic.heavy);
          _finishFlashTimer = 1;
          _finish(isWin: false);
          return;
        }
        _playHaptic(_GameHaptic.damage);
      }
    }
  }

  int _randomEnemyDamage(EnemyComponent enemy) {
    final minDamage = math.min(enemy.meleeDamageMin, enemy.meleeDamageMax);
    final maxDamage = math.max(enemy.meleeDamageMin, enemy.meleeDamageMax);
    if (maxDamage <= minDamage) {
      return minDamage;
    }
    return minDamage + _random.nextInt(maxDamage - minDamage + 1);
  }

  void _updateGems(double dt) {
    _gemMaintenanceTimer += dt;
    if (_gemMaintenanceTimer >= 0.35) {
      _gemMaintenanceTimer = 0;
      _cleanupStaleGems();
    }

    _collectedGemBuffer.clear();
    final pickupDistance = _gems.length > _softGemMergeCount
        ? player.pickupRange * 1.55
        : player.pickupRange;
    final pickupDistanceSquared = pickupDistance * pickupDistance;
    for (final gem in _gems) {
      if (gem.position.distanceToSquared(player.position) <=
          pickupDistanceSquared) {
        gem.isAttracted = true;
      }
      if (gem.isAttracted) {
        gem.moveToward(player.position, dt);
      }
      final collectDistance = player.collisionRadius + gem.radius;
      if (gem.position.distanceToSquared(player.position) <=
          collectDistance * collectDistance) {
        _collectedGemBuffer.add(gem);
      }
    }

    for (final gem in _collectedGemBuffer) {
      _gems.remove(gem);
      gem.removeFromParent();
      _coins += gem.coins;
      final healed = player.heal(gem.healing);
      if (_collectedGemBuffer.length <= 12 || gem.isRare) {
        _addWorldPulse(
          position: gem.position.clone(),
          color: switch (gem.payloadKind) {
            DropPayloadKind.exp => const Color(0xFF8FE388),
            DropPayloadKind.coin => const Color(0xFFFFD36E),
            DropPayloadKind.health => const Color(0xFFFF6B7E),
          },
          maxRadius: gem.isRare ? 42 : 28,
        );
      }
      if (healed > 0) {
        _addWorldPulse(
          position: player.position.clone(),
          color: const Color(0xFFFF6B7E),
          maxRadius: 36,
        );
        _syncHud(force: true);
      }
      if (gem.exp > 0 && _skillLevel('void_magnet') >= 2) {
        _damageEnemiesInRadius(
          origin: gem.position,
          radius: 48,
          damage: math.max(
            1,
            (_weaponDamage * _voidPickupDamageMultiplier).ceil(),
          ),
          color: const Color(0xFF8FE388),
        );
      }
      if (gem.exp > 0 && _evolvedSkills.contains('evolve_black_hole')) {
        _voidPickupCount++;
        if (_voidPickupCount >= 18) {
          _voidPickupCount = 0;
          _blackHoles.add(
            _BlackHoleField(
              center: gem.position.clone(),
              radius: 130,
              duration: 2,
              damage: math.max(
                1,
                (_weaponDamage * _blackHoleDamageMultiplier).ceil(),
              ),
              explosionDamage: math.max(
                4,
                (_weaponDamage * _blackHoleExplosionDamageMultiplier).ceil(),
              ),
              pull: 95,
              color: const Color(0xFF8FE388),
            ),
          );
        }
      }
      _addChargedUltimateFromDrop(gem);
      _addExp(gem.exp);
    }
    _collectedGemBuffer.clear();
  }

  void _cleanupStaleGems() {
    _expiredGemBuffer.clear();
    final maxDistanceX = size.x * 0.92;
    final maxDistanceY = size.y * 0.92;
    for (final gem in _gems) {
      final tooOld = gem.age > _gemMaxAgeSeconds && !gem.isAttracted;
      final tooFar =
          (gem.position.x - player.position.x).abs() > maxDistanceX ||
              (gem.position.y - player.position.y).abs() > maxDistanceY;
      if (tooOld || tooFar) {
        _expiredGemBuffer.add(gem);
      }
    }
    for (final gem in _expiredGemBuffer) {
      if (gem.exp > 0 && !gem.isAttracted) {
        _addExp((gem.exp * 0.35).floor());
      }
      _coins += gem.coins;
      _gems.remove(gem);
      gem.removeFromParent();
    }
    _expiredGemBuffer.clear();
  }

  void _addExp(int value) {
    _exp += value;
    var gainedLevels = 0;
    while (_exp >= _requiredExp) {
      _exp -= _requiredExp;
      _level++;
      gainedLevels++;
    }
    if (gainedLevels == 0) {
      return;
    }

    _pendingLevelUps += gainedLevels;
    _levelFlashTimer = 0.75;
    _addWorldPulse(
      position: player.position.clone(),
      color: const Color(0xFFFFD36E),
      maxRadius: 92,
    );
    if (_skillLevel('void_magnet') >= 4) {
      _damageEnemiesInRadius(
        origin: player.position,
        radius: 120,
        damage: math.max(2, (_weaponDamage * 0.75).ceil()),
        color: const Color(0xFFB68CFF),
      );
    }
    _playHaptic(_GameHaptic.light);
    controller.setPendingLevelUps(_pendingLevelUps);
    _syncHud(force: true);
  }

  void _addChargedUltimateFromDrop(ExpGemComponent gem) {
    if (gem.rareExpChargeUnits <= 0) {
      return;
    }
    var changed = false;
    if (_chargedUltimateCharge < _chargedUltimateRequiredCharge) {
      _chargedUltimateCharge = math.min(
        _chargedUltimateRequiredCharge,
        _chargedUltimateCharge + gem.rareExpChargeUnits,
      );
      changed = true;
    }
    if (_hasWeaponUltimate &&
        _weaponUltimateCharge < _weaponUltimateRequiredCharge) {
      _weaponUltimateCharge = math.min(
        _weaponUltimateRequiredCharge,
        _weaponUltimateCharge + gem.rareExpChargeUnits,
      );
      changed = true;
    }
    if (changed) {
      _syncHud(force: true);
    }
  }

  void openLevelUpChoices() {
    if (_pendingLevelUps <= 0 ||
        controller.levelUpOptions.isNotEmpty ||
        _finished) {
      return;
    }
    _levelUpRerollOffset = 0;
    _showNextLevelUpChoices();
  }

  void refreshLevelUpChoices() {
    if (_pendingLevelUps <= 0 ||
        controller.levelUpOptions.isEmpty ||
        _finished) {
      return;
    }
    _levelUpRerollOffset++;
    _showNextLevelUpChoices();
  }

  void closeLevelUpChoices() {
    if (controller.levelUpOptions.isEmpty || _finished) {
      return;
    }
    _levelUpRerollOffset = 0;
    controller.clearLevelUp();
    resumeEngine();
    _syncHud(force: true);
  }

  bool _showNextLevelUpChoices() {
    const selector = SkillOptionSelector();
    final options = selector.selectOptions(
      config.skills,
      rerollOffset: _levelUpRerollOffset,
      randomSeed: _random.nextInt(1 << 31),
      skillLevels: _skillLevels,
      evolvedSkills: _evolvedSkills,
      ultimateSkillId: _ultimateSkillId,
    );
    if (options.isEmpty) {
      _pendingLevelUps = 0;
      controller.setPendingLevelUps(0);
      controller.clearLevelUp();
      resumeEngine();
      _syncHud(force: true);
      return false;
    }
    controller.showLevelUp(options);
    pauseEngine();
    return true;
  }

  int get _requiredExp {
    return BattleExpCurve.requiredExpForLevel(
      baseExpToLevelUp: config.balance.baseExpToLevelUp,
      level: _level,
      isDeathmatch: isDeathmatch,
    );
  }

  void applySkill(String skillId) {
    final skill = _skillConfig(skillId);
    if (skill != null) {
      switch (skill.tier) {
        case SkillTier.normal:
          _applyNormalSkill(skill);
        case SkillTier.evolution:
          _applyEvolutionSkill(skill);
        case SkillTier.ultimate:
          _applyUltimateSkill(skill);
      }
    }

    if (_pendingLevelUps > 0) {
      _pendingLevelUps--;
    }
    _levelUpRerollOffset = 0;
    controller.setPendingLevelUps(_pendingLevelUps);
    _syncHud(force: true);

    if (_pendingLevelUps > 0 && !_finished && _showNextLevelUpChoices()) {
      return;
    }

    controller.clearLevelUp();
    resumeEngine();
  }

  SkillConfig? _skillConfig(String skillId) {
    for (final skill in config.skills) {
      if (skill.id == skillId) {
        return skill;
      }
    }
    return null;
  }

  void _applyNormalSkill(SkillConfig skill) {
    final treeId = skill.treeId ?? skill.id;
    final nextLevel = math.min(skill.maxLevel, (_skillLevels[treeId] ?? 0) + 1);
    _skillLevels[treeId] = nextLevel;

    switch (treeId) {
      case 'star_projectile':
        if (nextLevel == 5) {
          _cooldownMultiplier *= 0.82;
        }
      case 'orbit_blade':
        if (nextLevel == 5) {
          _weaponDamage += 1;
        }
      case 'thunder_matrix':
        if (nextLevel == 5) {
          _thunderTimer += 1.2;
        }
      case 'void_magnet':
        player.pickupRange *= nextLevel == 1 ? 1.35 : 1.08;
      case 'ice_nova':
        if (nextLevel == 1) {
          _iceNovaTimer = 999;
        }
      case 'fire_trail':
        _fireTrailTimer = math.max(_fireTrailTimer, 0.7);
      case 'poison_spore':
        if (nextLevel == 1) {
          _poisonSporeTimer = 999;
        }
      case 'shadow_guard':
        if (nextLevel == 1) {
          _shadowGuardSummonTimer = 999;
        }
    }
  }

  void _applyEvolutionSkill(SkillConfig skill) {
    _evolvedSkills.add(skill.id);
    switch (skill.id) {
      case 'evolve_star_barrage':
        _cooldownMultiplier *= 0.92;
      case 'evolve_moon_wheel':
        _moonWheelTimer = 0;
      case 'evolve_thunder_chain':
        _thunderTimer += 2.4;
      case 'evolve_black_hole':
        _voidPickupCount = 0;
      case 'evolve_permafrost_field':
        _iceNovaTimer = 999;
      case 'evolve_inferno_path':
        _fireTrailTimer = 999;
      case 'evolve_corrosive_plague':
        _poisonSporeTimer = 999;
      case 'evolve_twin_shadow':
        _shadowGuardSummonTimer = 999;
    }
    _addWorldPulse(
      position: player.position.clone(),
      color: const Color(0xFFE8FFF2),
      maxRadius: 150,
    );
    _playHaptic(_GameHaptic.medium);
  }

  void _applyUltimateSkill(SkillConfig skill) {
    _ultimateSkillId = skill.id;
    switch (skill.id) {
      case 'ultimate_star_judgement':
        _starJudgementCooldown = 0;
      case 'ultimate_black_moon':
        _blackMoonCooldown = 0;
      case 'ultimate_frost_inferno':
        _frostInfernoCooldown = 0;
    }
    _addWorldPulse(
      position: player.position.clone(),
      color: const Color(0xFFFFD36E),
      maxRadius: 210,
    );
    _playHaptic(_GameHaptic.heavy);
  }

  void _checkBattleEnd() {
    if (isDeathmatch) {
      return;
    }
    final bossSecondsRemaining = bossTimeSeconds - _elapsed;
    if (!_bossSpawned && !_bossWarningShown && bossSecondsRemaining <= 3) {
      _bossWarningShown = true;
      _bossBannerTimer = 3;
      _playHaptic(_GameHaptic.medium);
    }
    if (_elapsed >= bossTimeSeconds && !_bossSpawned) {
      _spawnBoss();
    }
  }

  void _updateFeedback(double dt) {
    _damageFlashTimer = math.max(0, _damageFlashTimer - dt);
    _levelFlashTimer = math.max(0, _levelFlashTimer - dt);
    _bossBannerTimer = math.max(0, _bossBannerTimer - dt);
    _finishFlashTimer = math.max(0, _finishFlashTimer - dt);
    for (final pulse in _worldPulses) {
      pulse.age += dt;
    }
    _worldPulses.removeWhere((pulse) => pulse.isDone);
  }

  void _addWorldPulse({
    required Vector2 position,
    required Color color,
    required double maxRadius,
  }) {
    if (_worldPulses.length >= 48) {
      _worldPulses.removeAt(0);
    }
    _worldPulses.add(
      _WorldPulse(
        position: position,
        color: color,
        maxRadius: maxRadius,
      ),
    );
  }

  void _finish({required bool isWin}) {
    if (_finished) {
      return;
    }
    _finished = true;
    pauseEngine();
    final survivalRatio =
        (_elapsed / bossTimeSeconds).clamp(0.2, 1.0).toDouble();
    final stageCoins = isWin ? stageRewardCoins : 0;
    final survivalCoins =
        isWin ? 0 : (stageRewardCoins * survivalRatio * 0.35).floor();
    final killExp = (isWin ? _killCount * 0.35 : _killCount * 0.2).floor();
    final battleLevelExp = isWin ? _level * 4 : _level * 2;
    final characterExp = isWin
        ? stageRewardExp + killExp + battleLevelExp
        : ((killExp + battleLevelExp) * survivalRatio).floor();
    controller.finish(
      GameResult(
        survivalSeconds: _elapsed.floor(),
        killCount: _killCount,
        level: _level,
        isWin: isWin,
        coinsEarned: _coins + stageCoins + survivalCoins,
        characterExpEarned: characterExp,
        collectedCoins: _coins,
        stageCoins: stageCoins,
        survivalCoins: survivalCoins,
        killExp: killExp,
        battleLevelExp: battleLevelExp,
        stageExp: isWin ? stageRewardExp : 0,
      ),
    );
    _syncHud(force: true);
  }

  void finishEarly() {
    _finish(isWin: false);
  }

  void triggerChargedUltimate() {
    if (_finished ||
        _chargedUltimateCharge < _chargedUltimateRequiredCharge ||
        controller.isLevelUpVisible) {
      return;
    }

    _chargedUltimateCharge = 0;
    final direction = _currentChargedUltimateDirection();
    _triggerCharacterChargedUltimate(direction);
    _playHaptic(_GameHaptic.heavy);
    _syncHud(force: true);
  }

  void _triggerCharacterChargedUltimate(Vector2 direction) {
    switch (playerCharacterId) {
      case 'guard':
        _triggerGuardUltimate();
      case 'aotuman':
        _triggerAotumanUltimate(direction);
      case 'aomeijia':
        _triggerAomeijiaUltimate(direction);
      case 'jingangman':
        _triggerJingangmanUltimate();
      case 'beliya':
        _triggerBeliyaUltimate();
      case 'sevengar':
        _triggerSevengarUltimate();
      case 'runner':
      default:
        _triggerRunnerUltimate(direction);
    }
  }

  void _triggerRunnerUltimate(Vector2 direction) {
    const projectileCount = 15;
    final baseDamage = math.max(3, (_weaponDamage * 1.35).ceil());
    for (var i = 0; i < projectileCount; i++) {
      final angle = -0.96 + 1.92 * (i / (projectileCount - 1));
      final nextDirection = _rotated(direction, angle);
      _spawnProjectile(
        direction: nextDirection,
        position: player.position + nextDirection * 34,
        damage: baseDamage,
        speed: 620,
        range: math.max(_weaponRange * 1.45, _attackRange * 1.55),
        style: ProjectileVisualStyle.forKind('star_projectile'),
        skillTag: 'star_projectile',
        pierceRemaining: 2,
      );
    }
    _expandingRings.add(
      _ExpandingRing(
        center: player.position.clone(),
        radius: 150,
        color: const Color(0xFF8FD7FF),
        strokeWidth: 4,
      ),
    );
    _addWorldPulse(
      position: player.position.clone(),
      color: const Color(0xFF8FD7FF),
      maxRadius: 150,
    );
  }

  void _triggerGuardUltimate() {
    final origin = player.position.clone();
    _damageEnemiesInRadius(
      origin: origin,
      radius: 185,
      damage: math.max(4, (_weaponDamage * 2.35).ceil()),
      bossDamageMultiplier: 0.55,
      color: const Color(0xFFFF8AB8),
      slowMultiplier: 0.72,
      slowDuration: 1.25,
      knockback: 42,
    );
    for (final radius in const [118.0, 178.0, 226.0]) {
      _expandingRings.add(
        _ExpandingRing(
          center: origin.clone(),
          radius: radius,
          color: const Color(0xFFFF8AB8),
          strokeWidth: 4,
        ),
      );
    }
    _addWorldPulse(
      position: origin,
      color: const Color(0xFFFF8AB8),
      maxRadius: 226,
    );
  }

  void _triggerAotumanUltimate(Vector2 direction) {
    final baseAngle = math.atan2(direction.y, direction.x);
    for (var i = 0; i < 4; i++) {
      final angle = baseAngle + i * math.pi / 2;
      _chargedUltimateBeams.add(
        _ChargedUltimateBeam(
          baseDirection: Vector2(math.cos(angle), math.sin(angle)),
          length: math.max(size.x, size.y) * 1.22,
          width: 32,
          duration: 0.95,
          damageInterval: 0.11,
          spinTurns: 0,
          normalHpDamageRatio: 0.32,
          bossHpDamageRatio: 0.07,
          glowColor: const Color(0xFFFF3B4F),
          bodyColor: const Color(0xFFFFD36E),
          coreColor: const Color(0xFFFFFFFF),
          pulseColor: const Color(0xFFFFD36E),
        ),
      );
    }
    _damageEnemiesInRadius(
      origin: player.position.clone(),
      radius: 112,
      damage: math.max(3, (_weaponDamage * 1.85).ceil()),
      bossDamageMultiplier: 0.5,
      color: const Color(0xFFFFD36E),
    );
    _addWorldPulse(
      position: player.position.clone(),
      color: const Color(0xFFFFD36E),
      maxRadius: 210,
    );
  }

  void _triggerAomeijiaUltimate(Vector2 direction) {
    final targets = _pickThunderTargets(count: 4);
    final centers = <Vector2>[
      for (final target in targets) target.position.clone(),
    ];
    if (centers.isEmpty) {
      for (var i = 0; i < 4; i++) {
        final angle = math.atan2(direction.y, direction.x) + i * math.pi / 2;
        centers.add(
          player.position + Vector2(math.cos(angle), math.sin(angle)) * 118,
        );
      }
    }

    for (final center in centers) {
      _addGroundField(
        _GroundEffectField(
          type: _GroundEffectType.frostInferno,
          center: center,
          radius: 92,
          duration: 2.05,
          tickInterval: 0.28,
          damage: math.max(2, (_weaponDamage * 0.92).ceil()),
          bossDamageMultiplier: 0.42,
          color: const Color(0xFF9BD3FF),
        ),
      );
      _expandingRings.add(
        _ExpandingRing(
          center: center.clone(),
          radius: 112,
          color: const Color(0xFFC7F7FF),
          strokeWidth: 3,
        ),
      );
    }
    _damageEnemiesInRadius(
      origin: player.position.clone(),
      radius: 172,
      damage: math.max(3, (_weaponDamage * 1.5).ceil()),
      bossDamageMultiplier: 0.48,
      color: const Color(0xFFC7F7FF),
      slowMultiplier: 0.42,
      slowDuration: 2.2,
    );
  }

  void _triggerJingangmanUltimate() {
    final origin = player.position.clone();
    _damageEnemiesInRadius(
      origin: origin,
      radius: 218,
      damage: math.max(6, (_weaponDamage * 3.05).ceil()),
      bossDamageMultiplier: 0.62,
      color: const Color(0xFFFF8A4C),
      slowMultiplier: 0.64,
      slowDuration: 1.4,
      knockback: 128,
    );
    for (final radius in const [86.0, 148.0, 218.0]) {
      _expandingRings.add(
        _ExpandingRing(
          center: origin.clone(),
          radius: radius,
          color: const Color(0xFFFF8A4C),
          strokeWidth: 6,
        ),
      );
    }
    _addWorldPulse(
      position: origin,
      color: const Color(0xFFFF8A4C),
      maxRadius: 240,
    );
  }

  void _triggerBeliyaUltimate() {
    final target = _nearestEnemy(maxDistance: math.max(size.x, size.y) * 0.86);
    final center = target?.position.clone() ?? player.position.clone();
    _blackHoles.add(
      _BlackHoleField(
        center: center,
        radius: 226,
        duration: 2.65,
        damage: math.max(2, (_weaponDamage * 0.92).ceil()),
        explosionDamage: math.max(9, (_weaponDamage * 4.05).ceil()),
        pull: 170,
        color: const Color(0xFFFF3B4F),
      ),
    );
    _damageEnemiesInRadius(
      origin: center,
      radius: 128,
      damage: math.max(3, (_weaponDamage * 1.65).ceil()),
      bossDamageMultiplier: 0.44,
      color: const Color(0xFFFF3B4F),
      slowMultiplier: 0.58,
      slowDuration: 1.2,
    );
    _addWorldPulse(
      position: center,
      color: const Color(0xFFFF3B4F),
      maxRadius: 226,
    );
  }

  void _triggerSevengarUltimate() {
    final targets = _pickThunderTargets(count: 8);
    final centers = <Vector2>[
      for (final target in targets) target.position.clone(),
    ];
    if (centers.isEmpty) {
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi * 2 / 6;
        centers.add(
          player.position + Vector2(math.cos(angle), math.sin(angle)) * 122,
        );
      }
    }

    for (final center in centers) {
      _damageEnemiesInRadius(
        origin: center,
        radius: 74,
        damage: math.max(4, (_weaponDamage * 2.08).ceil()),
        bossDamageMultiplier: 0.46,
        color: const Color(0xFFFFD166),
        knockback: 34,
      );
      _expandingRings.add(
        _ExpandingRing(
          center: center,
          radius: 88,
          color: const Color(0xFFFFD166),
          strokeWidth: 5,
        ),
      );
    }
    _addWorldPulse(
      position: player.position.clone(),
      color: const Color(0xFFFFD166),
      maxRadius: 172,
    );
  }

  bool get _hasWeaponUltimate {
    return switch (weaponRuntimeStats?.weaponId) {
      'wooden_stick' ||
      'bounce_ball' ||
      'frost_staff' ||
      'mini_grenade' ||
      'star_core_cannon' =>
        true,
      _ => false,
    };
  }

  void triggerWeaponUltimate() {
    if (_finished ||
        !_hasWeaponUltimate ||
        _weaponUltimateCharge < _weaponUltimateRequiredCharge ||
        controller.isLevelUpVisible) {
      return;
    }

    _weaponUltimateCharge = 0;
    final direction = _currentChargedUltimateDirection();
    switch (weaponRuntimeStats?.weaponId) {
      case 'wooden_stick':
        _triggerWoodenStickUltimate(direction);
      case 'bounce_ball':
        _triggerBounceBallUltimate(direction);
      case 'frost_staff':
        _triggerFrostStaffUltimate();
      case 'mini_grenade':
        _triggerMiniGrenadeUltimate(direction);
      case 'star_core_cannon':
        _triggerStarCoreCannonUltimate();
    }
    _playHaptic(_GameHaptic.heavy);
    _syncHud(force: true);
  }

  void _triggerWoodenStickUltimate(Vector2 direction) {
    final origin = player.position.clone();
    _damageEnemiesInRadius(
      origin: origin,
      radius: 170,
      damage: math.max(4, (_weaponDamage * 2.2).ceil()),
      bossDamageMultiplier: 0.48,
      color: const Color(0xFFD9A441),
      knockback: 76,
    );
    for (var i = 0; i < 6; i++) {
      final angle = math.pi * 2 * i / 6;
      final nextDirection = Vector2(math.cos(angle), math.sin(angle));
      _meleeSweeps.add(
        _MeleeSweepEffect(
          origin: origin + nextDirection * 20,
          direction: nextDirection,
          radius: 124,
          arc: 1.35,
          color: const Color(0xFFD9A441),
        ),
      );
      _weaponUltimateImages.add(
        _WeaponUltimateImage(
          center: origin + nextDirection * 62,
          size: 48,
          color: const Color(0xFFD9A441),
          direction: nextDirection,
        ),
      );
    }
    _expandingRings.add(
      _ExpandingRing(
        center: origin.clone(),
        radius: 180,
        color: const Color(0xFFFFD36E),
        strokeWidth: 5,
      ),
    );
    _addWorldPulse(
      position: origin,
      color: const Color(0xFFFFD36E),
      maxRadius: 190,
    );
  }

  void _triggerBounceBallUltimate(Vector2 direction) {
    const projectileCount = 8;
    final baseAngle = math.atan2(direction.y, direction.x);
    for (var i = 0; i < projectileCount; i++) {
      final angle = baseAngle + math.pi * 2 * i / projectileCount;
      final nextDirection = Vector2(math.cos(angle), math.sin(angle));
      _spawnProjectile(
        direction: nextDirection,
        position: player.position + nextDirection * 36,
        damage: math.max(2, (_weaponDamage * 1.28).ceil()),
        speed: 500,
        range: math.max(_weaponRange * 3.6, 620),
        style: ProjectileVisualStyle.forKind('weapon_bounce'),
        image: _projectileImage,
        skillTag: 'weapon_bounce',
        motionType: ProjectileMotionType.bouncing,
        bouncesRemaining: 6,
      );
      _weaponUltimateImages.add(
        _WeaponUltimateImage(
          center: player.position + nextDirection * 44,
          size: 34,
          color: const Color(0xFFFFC857),
          direction: nextDirection,
          duration: 0.34,
        ),
      );
    }
    _addWorldPulse(
      position: player.position.clone(),
      color: const Color(0xFFFFC857),
      maxRadius: 142,
    );
  }

  void _triggerFrostStaffUltimate() {
    final origin = player.position.clone();
    _damageEnemiesInRadius(
      origin: origin,
      radius: 205,
      damage: math.max(3, (_weaponDamage * 1.85).ceil()),
      bossDamageMultiplier: 0.42,
      color: const Color(0xFF9BD3FF),
      slowMultiplier: 0.34,
      slowDuration: 2.6,
      knockback: 20,
    );
    for (var i = 0; i < 10; i++) {
      final angle = math.pi * 2 * i / 10;
      final nextDirection = Vector2(math.cos(angle), math.sin(angle));
      _spawnProjectile(
        direction: nextDirection,
        position: origin + nextDirection * 34,
        damage: math.max(1, (_weaponDamage * 0.78).ceil()),
        speed: 430,
        range: 260,
        style: ProjectileVisualStyle.forKind('控制'),
        image: _projectileImage,
        skillTag: 'weapon_frost_ultimate',
        pierceRemaining: 1,
      );
    }
    _addGroundField(
      _GroundEffectField(
        type: _GroundEffectType.frostInferno,
        center: origin.clone(),
        radius: 132,
        duration: 2.2,
        tickInterval: 0.36,
        damage: math.max(1, (_weaponDamage * 0.42).ceil()),
        bossDamageMultiplier: 0.30,
        color: const Color(0xFF9BD3FF),
        slowMultiplier: 0.46,
      ),
    );
    for (final radius in const [112.0, 166.0, 214.0]) {
      _expandingRings.add(
        _ExpandingRing(
          center: origin.clone(),
          radius: radius,
          color: const Color(0xFFC7F7FF),
          strokeWidth: 4,
        ),
      );
    }
  }

  void _triggerMiniGrenadeUltimate(Vector2 direction) {
    final targets = _pickThunderTargets(count: 5);
    final centers = <Vector2>[
      for (final target in targets) target.position.clone(),
    ];
    if (centers.isEmpty) {
      final baseAngle = math.atan2(direction.y, direction.x);
      for (var i = 0; i < 5; i++) {
        final offsetAngle = baseAngle - 0.74 + 0.37 * i;
        centers.add(
          player.position +
              Vector2(math.cos(offsetAngle), math.sin(offsetAngle)) *
                  (128 + i * 18),
        );
      }
    }

    for (var i = 0; i < centers.length; i++) {
      _delayedWeaponBlasts.add(
        _DelayedWeaponBlast(
          center: centers[i],
          radius: math.max(94, _weaponAreaRadius * 1.22),
          damage: math.max(5, (_weaponDamage * 1.95).ceil()),
          color: const Color(0xFFFF8A4C),
          delay: 0.18 + i * 0.13,
          warningDuration: 0.18 + i * 0.13,
          bossDamageMultiplier: 0.44,
          knockback: 44,
          imageSize: 54,
        ),
      );
    }
    _addWorldPulse(
      position: player.position.clone(),
      color: const Color(0xFFFF8A4C),
      maxRadius: 124,
    );
  }

  void _triggerStarCoreCannonUltimate() {
    final clusterTargets = _pickThunderTargets(count: 1);
    final target = clusterTargets.isEmpty ? null : clusterTargets.first;
    final center = target?.position.clone() ??
        _nearestEnemy(maxDistance: math.max(size.x, size.y) * 0.9)
            ?.position
            .clone() ??
        player.position.clone();
    _blackHoles.add(
      _BlackHoleField(
        center: center.clone(),
        radius: 215,
        duration: 1.65,
        damage: math.max(2, (_weaponDamage * 0.72).ceil()),
        explosionDamage: math.max(10, (_weaponDamage * 3.75).ceil()),
        pull: 190,
        color: const Color(0xFFFFD166),
      ),
    );
    _delayedWeaponBlasts.add(
      _DelayedWeaponBlast(
        center: center.clone(),
        radius: 188,
        damage: math.max(8, (_weaponDamage * 2.25).ceil()),
        color: const Color(0xFFFFD166),
        delay: 1.0,
        warningDuration: 1.0,
        bossDamageMultiplier: 0.38,
        slowMultiplier: 0.62,
        slowDuration: 0.9,
        knockback: 28,
        imageSize: 76,
      ),
    );
    _weaponUltimateImages.add(
      _WeaponUltimateImage(
        center: center,
        size: 82,
        color: const Color(0xFFFFD166),
        duration: 1.05,
        spinTurns: 1.8,
      ),
    );
    _addWorldPulse(
      position: center,
      color: const Color(0xFFFFD166),
      maxRadius: 220,
    );
  }

  Vector2 _currentChargedUltimateDirection() {
    final moveDirection = controller.moveDirection;
    if (moveDirection.length2 > 0.01) {
      return moveDirection.normalized();
    }

    final target = _nearestEnemy(maxDistance: math.max(size.x, size.y) * 0.8);
    if (target != null) {
      final direction = target.position - player.position;
      if (direction.length2 > 0.01) {
        direction.normalize();
        _lastAimDirection = direction.clone();
        return direction;
      }
    }

    if (_lastAimDirection.length2 > 0.01) {
      return _lastAimDirection.normalized();
    }
    return Vector2(0, 1);
  }

  void _syncHud({bool force = false}) {
    if (!force && _hudTimer < 0.18) {
      return;
    }
    _hudTimer = 0;
    controller.updateHud(
      HudSnapshot(
        hp: player.hp,
        maxHp: player.maxHp,
        exp: _exp,
        requiredExp: _requiredExp,
        level: _level,
        stageName: stageName,
        stageChapter: stageChapter,
        stageIndex: stageIndex,
        elapsedSeconds: _elapsed.floor(),
        killCount: _killCount,
        maxBattleSeconds: config.balance.maxBattleSeconds,
        coins: _coins,
        stageEnemyCount: stageEnemyCount,
        bossTimeSeconds: bossTimeSeconds,
        isBossSpawned: _bossSpawned,
        ultimateCharge: _chargedUltimateCharge,
        ultimateChargeRequired: _chargedUltimateRequiredCharge,
        weaponUltimateCharge: _weaponUltimateCharge,
        weaponUltimateChargeRequired: _weaponUltimateRequiredCharge,
        hasWeaponUltimate: _hasWeaponUltimate,
      ),
    );
  }
}

class _WorldPulse {
  _WorldPulse({
    required this.position,
    required this.color,
    required this.maxRadius,
  });

  final Vector2 position;
  final Color color;
  final double maxRadius;
  double age = 0;
  static const double _duration = 0.42;

  double get progress => (age / _duration).clamp(0, 1).toDouble();

  bool get isDone => age >= _duration;
}

class _ChargedUltimateBeam {
  _ChargedUltimateBeam({
    required Vector2 baseDirection,
    required this.length,
    required this.width,
    this.duration = 1.45,
    this.damageInterval = 0.10,
    this.spinTurns = 5,
    this.normalHpDamageRatio = 0.50,
    this.bossHpDamageRatio = 0.10,
    this.glowColor = const Color(0xFFFFD36E),
    this.bodyColor = const Color(0xFFFFF2A6),
    this.coreColor = const Color(0xFFFFFFFF),
    this.pulseColor = const Color(0xFFFFF2A6),
  }) : _baseAngle = math.atan2(baseDirection.y, baseDirection.x);

  final double _baseAngle;
  final double length;
  final double width;
  final double duration;
  final double damageInterval;
  final double spinTurns;
  final double normalHpDamageRatio;
  final double bossHpDamageRatio;
  final Color glowColor;
  final Color bodyColor;
  final Color coreColor;
  final Color pulseColor;
  double age = 0;
  double damageTimer = 0;

  double get progress => (age / duration).clamp(0, 1).toDouble();

  Vector2 get direction {
    final angle = _baseAngle + progress * math.pi * 2 * spinTurns;
    return Vector2(math.cos(angle), math.sin(angle));
  }

  bool get isDone => age >= duration;
}

class _WeaponUltimateImage {
  _WeaponUltimateImage({
    required this.center,
    required this.size,
    required this.color,
    Vector2? direction,
    this.duration = 0.42,
    this.spinTurns = 0.75,
  }) : _baseAngle =
            direction == null ? 0 : math.atan2(direction.y, direction.x);

  final Vector2 center;
  final double size;
  final Color color;
  final double duration;
  final double spinTurns;
  final double _baseAngle;
  double age = 0;

  double get progress => (age / duration).clamp(0, 1).toDouble();

  double get angle => _baseAngle + progress * math.pi * 2 * spinTurns;

  bool get isDone => age >= duration;
}

class _DelayedWeaponBlast {
  _DelayedWeaponBlast({
    required this.center,
    required this.radius,
    required this.damage,
    required this.color,
    required this.delay,
    required this.warningDuration,
    required this.imageSize,
    this.bossDamageMultiplier = 0.45,
    this.slowMultiplier = 1,
    this.slowDuration = 0,
    this.knockback = 0,
  });

  final Vector2 center;
  final double radius;
  final int damage;
  final Color color;
  final double warningDuration;
  final double imageSize;
  final double bossDamageMultiplier;
  final double slowMultiplier;
  final double slowDuration;
  final double knockback;
  double delay;
  double age = 0;
  bool hasExploded = false;

  double get warningProgress {
    if (warningDuration <= 0) {
      return 1;
    }
    return (age / warningDuration).clamp(0, 1).toDouble();
  }

  bool get isDone => hasExploded && age >= warningDuration + 0.7;
}

class _ThunderStrike {
  _ThunderStrike({
    required this.position,
    required this.radius,
  });

  final Vector2 position;
  final double radius;
  double age = 0;
  static const double _duration = 0.28;

  double get progress => (age / _duration).clamp(0, 1).toDouble();

  bool get isDone => age >= _duration;
}

class _EffectFrameGrid {
  const _EffectFrameGrid({
    required this.columns,
    required this.rows,
  });

  final int columns;
  final int rows;

  int get frameCount => columns * rows;
}

class _ThunderTargetScore implements Comparable<_ThunderTargetScore> {
  const _ThunderTargetScore({
    required this.enemy,
    required this.nearbyCount,
    required this.playerDistanceSquared,
  });

  final EnemyComponent enemy;
  final int nearbyCount;
  final double playerDistanceSquared;

  @override
  int compareTo(_ThunderTargetScore other) {
    final byCluster = other.nearbyCount.compareTo(nearbyCount);
    if (byCluster != 0) {
      return byCluster;
    }
    return playerDistanceSquared.compareTo(other.playerDistanceSquared);
  }
}

class _BlackHoleField {
  _BlackHoleField({
    required this.center,
    required this.radius,
    required this.duration,
    required this.damage,
    required this.explosionDamage,
    required this.pull,
    required this.color,
  });

  final Vector2 center;
  final double radius;
  final double duration;
  final int damage;
  final int explosionDamage;
  final double pull;
  final Color color;
  double age = 0;
  double damageTimer = 0;

  double get progress => (age / duration).clamp(0, 1).toDouble();

  bool get isDone => age >= duration;
}

enum _GroundEffectType { fire, poison, frostInferno }

class _GroundEffectField {
  _GroundEffectField({
    required this.type,
    required this.center,
    required this.radius,
    required this.duration,
    required this.tickInterval,
    required this.damage,
    required this.bossDamageMultiplier,
    required this.color,
    this.slowMultiplier = 1,
    this.firstHitExplosionDamage = 0,
  }) : tickTimer = 0;

  final _GroundEffectType type;
  final Vector2 center;
  final double radius;
  final double duration;
  final double tickInterval;
  final int damage;
  final double bossDamageMultiplier;
  final Color color;
  final double slowMultiplier;
  final int firstHitExplosionDamage;
  final Set<EnemyComponent> firstHitEnemies = {};
  double age = 0;
  double tickTimer;

  double get progress => (age / duration).clamp(0, 1).toDouble();

  bool get isDone => age >= duration;
}

class _ExpandingRing {
  _ExpandingRing({
    required this.center,
    required this.radius,
    required this.color,
    required this.strokeWidth,
  });

  final Vector2 center;
  final double radius;
  final Color color;
  final double strokeWidth;
  double age = 0;
  static const double _duration = 0.48;

  double get progress => (age / _duration).clamp(0, 1).toDouble();

  bool get isDone => age >= _duration;
}

class _MeleeSweepEffect {
  _MeleeSweepEffect({
    required this.origin,
    required this.direction,
    required this.radius,
    required this.arc,
    required this.color,
  });

  final Vector2 origin;
  final Vector2 direction;
  final double radius;
  final double arc;
  final Color color;
  double age = 0;
  static const double _duration = 0.22;

  double get progress => (age / _duration).clamp(0, 1).toDouble();

  bool get isDone => age >= _duration;
}

class _StageMapTheme {
  const _StageMapTheme({
    required this.screenBackground,
    required this.ground,
    required this.groundAlt,
    required this.gridLine,
    required this.groundOverlay,
    required this.obstacles,
  });

  final Color screenBackground;
  final Color ground;
  final Color groundAlt;
  final Color gridLine;
  final Color groundOverlay;
  final List<_StageObstacle> obstacles;

  static const _carAsset =
      'assets/game/grass_game/images/obstacles/obstacle_abandoned_car.png';
  static const _barrierAsset =
      'assets/game/grass_game/images/obstacles/obstacle_concrete_barrier.png';
  static const _leafyTreeAsset =
      'assets/game/grass_game/images/obstacles/obstacle_leafy_tree.png';
  static const _deadTreeAsset =
      'assets/game/grass_game/images/obstacles/obstacle_dead_tree.png';
  static const _boulderAsset =
      'assets/game/grass_game/images/obstacles/obstacle_mossy_boulders.png';
  static const _crystalRockAsset =
      'assets/game/grass_game/images/obstacles/obstacle_crystal_rock.png';

  static _StageMapTheme forChapter(int chapter) {
    return switch (chapter.clamp(1, 10)) {
      1 => farm,
      2 => highway,
      3 => city,
      4 => cave,
      5 => forest,
      6 => ocean,
      7 => infected,
      8 => skeleton,
      9 => alien,
      _ => cosmos,
    };
  }

  static const farm = _StageMapTheme(
    screenBackground: Color(0xFF172315),
    ground: Color(0xFF2F4D27),
    groundAlt: Color(0xFF37592D),
    gridLine: Color(0x263E7A38),
    groundOverlay: Color(0x77132012),
    obstacles: [
      _StageObstacle(
        rect: Rect.fromLTWH(-420, -250, 220, 54),
        color: Color(0xCC6C4B2A),
        strokeColor: Color(0xAAE0B36B),
        detailColor: Color(0x66442D18),
        assetPath: _barrierAsset,
        visualScale: 1.18,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(230, -250, 170, 122),
        color: Color(0xCC79452F),
        strokeColor: Color(0xAAE27B56),
        detailColor: Color(0x665A2418),
        assetPath: _deadTreeAsset,
        visualScale: 1.35,
        visualOffsetY: -16,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(-360, 160, 150, 62),
        color: Color(0xCC8B7340),
        strokeColor: Color(0xAAE2CE7E),
        assetPath: _boulderAsset,
        visualScale: 1.25,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(190, 170, 250, 52),
        color: Color(0xCC5C4329),
        strokeColor: Color(0xAAE0B36B),
        assetPath: _barrierAsset,
        visualScale: 1.08,
        rotation: -0.08,
      ),
    ],
  );

  static const highway = _StageMapTheme(
    screenBackground: Color(0xFF171817),
    ground: Color(0xFF2E3334),
    groundAlt: Color(0xFF363B3C),
    gridLine: Color(0x263E4547),
    groundOverlay: Color(0x8820201B),
    obstacles: [
      _StageObstacle(
        rect: Rect.fromLTWH(-440, -260, 210, 74),
        color: Color(0xCC51565A),
        strokeColor: Color(0xAAAEB6BA),
        detailColor: Color(0x6640474B),
        assetPath: _barrierAsset,
        visualScale: 1.14,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(210, -220, 260, 62),
        color: Color(0xCC7D4A24),
        strokeColor: Color(0xAAFFB06D),
        assetPath: _carAsset,
        visualScale: 1.26,
        rotation: 0.05,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(-320, 150, 190, 74),
        color: Color(0xCC4F5960),
        strokeColor: Color(0xAAAEB6BA),
        assetPath: _barrierAsset,
        visualScale: 1.18,
        rotation: -0.06,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(170, 170, 160, 95),
        color: Color(0xCC7E3127),
        strokeColor: Color(0xAAFF8B6C),
        detailColor: Color(0x665A1F19),
        assetPath: _carAsset,
        visualScale: 1.34,
        rotation: -0.14,
      ),
    ],
  );

  static const city = _StageMapTheme(
    screenBackground: Color(0xFF12171B),
    ground: Color(0xFF242B31),
    groundAlt: Color(0xFF2B333A),
    gridLine: Color(0x263D596C),
    groundOverlay: Color(0x8820262B),
    obstacles: [
      _StageObstacle(
        rect: Rect.fromLTWH(-430, -270, 190, 118),
        color: Color(0xCC4C555C),
        strokeColor: Color(0xAA9EB1BD),
        assetPath: _carAsset,
        visualScale: 1.28,
        rotation: -0.1,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(250, -260, 145, 145),
        color: Color(0xCC38424A),
        strokeColor: Color(0xAA8CA3B4),
        detailColor: Color(0x66303A42),
        assetPath: _boulderAsset,
        visualScale: 1.22,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(-330, 170, 235, 72),
        color: Color(0xCC50312C),
        strokeColor: Color(0xAAA86155),
        assetPath: _barrierAsset,
        visualScale: 1.14,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(170, 160, 245, 76),
        color: Color(0xCC4B5054),
        strokeColor: Color(0xAA9EB1BD),
        assetPath: _barrierAsset,
        visualScale: 1.12,
        rotation: 0.06,
      ),
    ],
  );

  static const cave = _StageMapTheme(
    screenBackground: Color(0xFF11151A),
    ground: Color(0xFF222A30),
    groundAlt: Color(0xFF283238),
    gridLine: Color(0x244B6680),
    groundOverlay: Color(0x99101418),
    obstacles: [
      _StageObstacle(
        rect: Rect.fromLTWH(-430, -230, 245, 88),
        color: Color(0xCC3D3F44),
        strokeColor: Color(0xAA8293A0),
        detailColor: Color(0x664B6D78),
        assetPath: _boulderAsset,
        visualScale: 1.14,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(220, -255, 165, 165),
        color: Color(0xCC30343A),
        strokeColor: Color(0xAA7D8FA0),
        assetPath: _crystalRockAsset,
        visualScale: 1.24,
        visualOffsetY: -8,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(-320, 150, 160, 135),
        color: Color(0xCC33373D),
        strokeColor: Color(0xAA7D8FA0),
        assetPath: _boulderAsset,
        visualScale: 1.2,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(170, 180, 285, 62),
        color: Color(0xCC47545B),
        strokeColor: Color(0xAA87C6D2),
        assetPath: _barrierAsset,
        visualScale: 1.08,
      ),
    ],
  );

  static const forest = _StageMapTheme(
    screenBackground: Color(0xFF111F18),
    ground: Color(0xFF1F3B2A),
    groundAlt: Color(0xFF264533),
    gridLine: Color(0x253A7C56),
    groundOverlay: Color(0x88131F16),
    obstacles: [
      _StageObstacle(
        rect: Rect.fromLTWH(-420, -250, 170, 150),
        color: Color(0xCC3A2B1E),
        strokeColor: Color(0xAA8DA56B),
        detailColor: Color(0x664E7B4A),
        assetPath: _deadTreeAsset,
        visualScale: 1.35,
        visualOffsetY: -14,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(230, -245, 190, 135),
        color: Color(0xCC2D442A),
        strokeColor: Color(0xAA8ED46F),
        assetPath: _leafyTreeAsset,
        visualScale: 1.34,
        visualOffsetY: -20,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(-360, 175, 270, 64),
        color: Color(0xCC3A2B1E),
        strokeColor: Color(0xAA8DA56B),
        assetPath: _barrierAsset,
        visualScale: 1.06,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(150, 155, 160, 150),
        color: Color(0xCC263C27),
        strokeColor: Color(0xAA8ED46F),
        detailColor: Color(0x665FCB70),
        assetPath: _leafyTreeAsset,
        visualScale: 1.38,
        visualOffsetY: -22,
      ),
    ],
  );

  static const ocean = _StageMapTheme(
    screenBackground: Color(0xFF0D1F24),
    ground: Color(0xFF183D45),
    groundAlt: Color(0xFF204B55),
    gridLine: Color(0x2652A8B4),
    groundOverlay: Color(0x88102024),
    obstacles: [
      _StageObstacle(
        rect: Rect.fromLTWH(-435, -250, 245, 58),
        color: Color(0xCC5B4933),
        strokeColor: Color(0xAAC4A36B),
        assetPath: _deadTreeAsset,
        visualScale: 1.08,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(220, -250, 170, 130),
        color: Color(0xCC37515B),
        strokeColor: Color(0xAA83D6E2),
        detailColor: Color(0x66337C88),
        assetPath: _crystalRockAsset,
        visualScale: 1.22,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(-310, 165, 170, 95),
        color: Color(0xCC5B4933),
        strokeColor: Color(0xAAC4A36B),
        assetPath: _boulderAsset,
        visualScale: 1.2,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(160, 170, 250, 68),
        color: Color(0xCC284E57),
        strokeColor: Color(0xAA83D6E2),
        assetPath: _barrierAsset,
        visualScale: 1.08,
        rotation: 0.08,
      ),
    ],
  );

  static const infected = _StageMapTheme(
    screenBackground: Color(0xFF1B1717),
    ground: Color(0xFF34292A),
    groundAlt: Color(0xFF3B3031),
    gridLine: Color(0x265F3B3B),
    groundOverlay: Color(0x991B1212),
    obstacles: [
      _StageObstacle(
        rect: Rect.fromLTWH(-430, -250, 195, 90),
        color: Color(0xCCDDD5BE),
        strokeColor: Color(0xAAFFEEE0),
        detailColor: Color(0x66B84040),
        assetPath: _deadTreeAsset,
        visualScale: 1.24,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(230, -240, 220, 70),
        color: Color(0xCC8C2F2B),
        strokeColor: Color(0xAAFF7A6C),
        assetPath: _carAsset,
        visualScale: 1.24,
        rotation: -0.08,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(-330, 165, 250, 70),
        color: Color(0xCC4F4F55),
        strokeColor: Color(0xAAAEB0B8),
        assetPath: _barrierAsset,
        visualScale: 1.08,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(150, 155, 170, 130),
        color: Color(0xCC34363A),
        strokeColor: Color(0xAAAEB0B8),
        detailColor: Color(0x66B84040),
        assetPath: _boulderAsset,
        visualScale: 1.2,
      ),
    ],
  );

  static const skeleton = _StageMapTheme(
    screenBackground: Color(0xFF1E1B16),
    ground: Color(0xFF4A3E2A),
    groundAlt: Color(0xFF554833),
    gridLine: Color(0x267D6F52),
    groundOverlay: Color(0x88201912),
    obstacles: [
      _StageObstacle(
        rect: Rect.fromLTWH(-430, -240, 220, 80),
        color: Color(0xCCB9AC86),
        strokeColor: Color(0xAAE7D9AF),
        assetPath: _barrierAsset,
        visualScale: 1.12,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(230, -245, 165, 150),
        color: Color(0xCC6E654E),
        strokeColor: Color(0xAAD9CFAF),
        detailColor: Color(0x667BDAFF),
        assetPath: _crystalRockAsset,
        visualScale: 1.2,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(-320, 165, 180, 115),
        color: Color(0xCCB9AC86),
        strokeColor: Color(0xAAE7D9AF),
        assetPath: _boulderAsset,
        visualScale: 1.2,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(170, 170, 250, 62),
        color: Color(0xCC615846),
        strokeColor: Color(0xAAD9CFAF),
        assetPath: _deadTreeAsset,
        visualScale: 1.08,
      ),
    ],
  );

  static const alien = _StageMapTheme(
    screenBackground: Color(0xFF131625),
    ground: Color(0xFF252842),
    groundAlt: Color(0xFF2E3150),
    gridLine: Color(0x265E64B6),
    groundOverlay: Color(0x9910182A),
    obstacles: [
      _StageObstacle(
        rect: Rect.fromLTWH(-430, -245, 205, 110),
        color: Color(0xCC353A59),
        strokeColor: Color(0xAA8BA1FF),
        detailColor: Color(0x667C4DFF),
        assetPath: _crystalRockAsset,
        visualScale: 1.18,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(230, -250, 180, 128),
        color: Color(0xCC4B3560),
        strokeColor: Color(0xAACE8BFF),
        assetPath: _boulderAsset,
        visualScale: 1.2,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(-330, 175, 240, 66),
        color: Color(0xCC2E405A),
        strokeColor: Color(0xAA7FE7FF),
        assetPath: _barrierAsset,
        visualScale: 1.08,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(170, 165, 150, 145),
        color: Color(0xCC4B3560),
        strokeColor: Color(0xAACE8BFF),
        detailColor: Color(0x667FE7FF),
        assetPath: _crystalRockAsset,
        visualScale: 1.22,
      ),
    ],
  );

  static const cosmos = _StageMapTheme(
    screenBackground: Color(0xFF0D1020),
    ground: Color(0xFF20243B),
    groundAlt: Color(0xFF292D49),
    gridLine: Color(0x265F6BFF),
    groundOverlay: Color(0xAA0B0E20),
    obstacles: [
      _StageObstacle(
        rect: Rect.fromLTWH(-420, -250, 220, 70),
        color: Color(0xCC2E345F),
        strokeColor: Color(0xAA8EA1FF),
        detailColor: Color(0x668B4DFF),
        assetPath: _crystalRockAsset,
        visualScale: 1.16,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(230, -245, 170, 150),
        color: Color(0xCC4B2E5F),
        strokeColor: Color(0xAAD98BFF),
        assetPath: _boulderAsset,
        visualScale: 1.2,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(-330, 170, 170, 135),
        color: Color(0xCC293D57),
        strokeColor: Color(0xAA7FE7FF),
        assetPath: _crystalRockAsset,
        visualScale: 1.2,
      ),
      _StageObstacle(
        rect: Rect.fromLTWH(155, 175, 290, 58),
        color: Color(0xCC383D66),
        strokeColor: Color(0xAA8EA1FF),
        assetPath: _barrierAsset,
        visualScale: 1.04,
      ),
    ],
  );
}

class _StageObstacle {
  const _StageObstacle({
    required this.rect,
    required this.color,
    required this.strokeColor,
    this.detailColor,
    this.assetPath,
    this.visualScale = 1.35,
    this.visualOffsetY = 0,
    this.rotation = 0,
  });

  final Rect rect;
  final Color color;
  final Color strokeColor;
  final Color? detailColor;
  final String? assetPath;
  final double visualScale;
  final double visualOffsetY;
  final double rotation;
  double get radius => 8;
  Rect get visualRect {
    final size = math.max(rect.width, rect.height) * visualScale;
    return Rect.fromCenter(
      center: rect.center.translate(0, visualOffsetY),
      width: size,
      height: size,
    );
  }
}

class _CompanionRuntimeVariant {
  const _CompanionRuntimeVariant({
    required this.id,
    required this.animationSet,
    required this.color,
    required this.accentColor,
  });

  final String id;
  final CompanionAnimationSet animationSet;
  final Color color;
  final Color accentColor;
}

class _DropRoll {
  const _DropRoll(this.value, this.tier);

  final int value;
  final DropVisualTier tier;
}

enum _GameHaptic { light, medium, heavy, damage }
