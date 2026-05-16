import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

import '../components/enemy_component.dart';
import '../components/exp_gem_component.dart';
import '../components/muzzle_flash_component.dart';
import '../components/player_component.dart';
import '../components/projectile_component.dart';
import '../snapshots/hud_snapshot.dart';
import 'grass_game_runtime_controller.dart';
import 'grass_game_runtime_state.dart';

class GrassSurvivorGame extends FlameGame {
  GrassSurvivorGame({
    required this.config,
    required this.controller,
    this.playerMaxHp = 100,
    this.playerMoveSpeedMultiplier = 1,
    this.playerSpriteSheetAssetPath =
        'assets/game/grass_game/images/player/player_soldier_walk_sheet.png',
    this.weaponDamage = 1,
    this.weaponCooldownMultiplier = 1,
    this.weaponFireIntervalSeconds = 0.8,
    this.weaponKind = '步枪',
    this.weaponProjectileAssetPath,
    this.weaponMuzzleFlashAssetPath,
    this.weaponFireSoundAssetPath,
    this.bossTimeSeconds = 300,
    this.bossMaxHp = 420,
    this.stageRewardExp = 0,
    this.stageRewardCoins = 0,
    this.stageEnemyCount = 100,
    this.stageEnemyStrengthMultiplier = 1,
    this.stageEnemyTypes = const ['basic', 'fast', 'tank'],
    this.bossSpriteSheetAssetPath =
        'assets/game/grass_game/images/bosses/boss_tiger_walk.png',
    this.bossDeathAssetPath,
  }) : state = GrassGameRuntimeState.initial(
          configVersion: config.version,
        );

  final GrassGameConfig config;
  final GrassGameRuntimeController controller;
  final int playerMaxHp;
  final double playerMoveSpeedMultiplier;
  final String playerSpriteSheetAssetPath;
  final int weaponDamage;
  final double weaponCooldownMultiplier;
  final double weaponFireIntervalSeconds;
  final String weaponKind;
  final String? weaponProjectileAssetPath;
  final String? weaponMuzzleFlashAssetPath;
  final String? weaponFireSoundAssetPath;
  final int bossTimeSeconds;
  final int bossMaxHp;
  final int stageRewardExp;
  final int stageRewardCoins;
  final int stageEnemyCount;
  final double stageEnemyStrengthMultiplier;
  final List<String> stageEnemyTypes;
  final String bossSpriteSheetAssetPath;
  final String? bossDeathAssetPath;
  GrassGameRuntimeState state;

  late final PlayerComponent player;

  final math.Random _random = math.Random();
  final List<EnemyComponent> _enemies = [];
  final List<ProjectileComponent> _projectiles = [];
  final List<ExpGemComponent> _gems = [];
  final Map<String, EnemyAnimationSet> _enemyAnimations = {};
  late final PlayerAnimationSet _playerAnimation;
  late final DropIconSet _dropIcons;
  Image? _projectileImage;
  Image? _muzzleFlashImage;
  AudioPool? _fireSoundPool;

  final Paint _backgroundPaint = Paint()..color = const Color(0xFF102418);
  final Paint _gridPaint = Paint()
    ..color = const Color(0x1FE8FFF2)
    ..strokeWidth = 1;
  final Paint _attackRangeFillPaint = Paint()
    ..color = const Color(0x1427D6FF)
    ..style = PaintingStyle.fill;
  final Paint _attackRangeStrokePaint = Paint()
    ..color = const Color(0x9927D6FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static const double _attackRange = 260 * 0.8;

  double _elapsed = 0;
  double _spawnTimer = 0;
  double _weaponTimer = 0;
  double _hudTimer = 0;
  int _killCount = 0;
  int _level = 1;
  int _exp = 0;
  int _coins = 0;
  int _battleExpCollected = 0;
  int _pendingLevelUps = 0;
  late int _weaponDamage = weaponDamage;
  late double _cooldownMultiplier = weaponCooldownMultiplier;
  bool _finished = false;
  bool _bossSpawned = false;

  @override
  Color backgroundColor() => const Color(0xFF102418);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadPlayerAnimation();
    await _loadEnemyAnimations();
    await _loadDropIcons();
    await _loadWeaponEffects();
    controller.start();

    player = PlayerComponent(
      controller: controller,
      moveSpeed: config.balance.playerMoveSpeed * playerMoveSpeedMultiplier,
      maxHp: playerMaxHp,
      animationSet: _playerAnimation,
    );

    await add(player);
    _syncHud(force: true);
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
      ..addAll({
        'basic': EnemyAnimationSet(
          image: await _loadImage(
            'assets/game/grass_game/images/animals/PNG/Without_shadow/Sheep_animation_without_shadow.png',
          ),
          displaySize: Vector2.all(42),
        ),
        'fast': EnemyAnimationSet(
          image: await _loadImage(
            'assets/game/grass_game/images/animals/PNG/Without_shadow/Chick_animation_without_shadow.png',
          ),
          displaySize: Vector2.all(32),
        ),
        'tank': EnemyAnimationSet(
          image: await _loadImage(
            'assets/game/grass_game/images/animals/PNG/Without_shadow/Bull_animation_without_shadow.png',
          ),
          displaySize: Vector2.all(66),
        ),
        'boss': EnemyAnimationSet(
          image: await _loadImage(bossSpriteSheetAssetPath),
          displaySize: Vector2.all(104),
        ),
      });
  }

  Future<void> _loadDropIcons() async {
    _dropIcons = DropIconSet(
      expLow: await _loadImage(
        'assets/game/grass_game/images/exp/exp_low.webp',
      ),
      expMid: await _loadImage(
        'assets/game/grass_game/images/exp/exp_mid.webp',
      ),
      expHigh: await _loadImage(
        'assets/game/grass_game/images/exp/exp_high.webp',
      ),
      coinSmall: await _loadImage(
        'assets/game/grass_game/images/coins/coin_small.webp',
      ),
      coinMedium: await _loadImage(
        'assets/game/grass_game/images/coins/coin_medium.webp',
      ),
      coinLarge: await _loadImage(
        'assets/game/grass_game/images/coins/coin_large.webp',
      ),
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
      _fireSoundPool = await FlameAudio.createPool(
        fireSoundPath.split('/').last,
        minPlayers: 1,
        maxPlayers: 8,
      );
    }
  }

  @override
  void onRemove() {
    final fireSoundPool = _fireSoundPool;
    if (fireSoundPool != null) {
      unawaited(fireSoundPool.dispose());
    }
    super.onRemove();
  }

  @override
  void update(double dt) {
    final scaledDt = dt * controller.timeScale;
    if (_finished || !controller.state.isRunning) {
      super.update(0);
      return;
    }

    super.update(scaledDt);
    _elapsed += scaledDt;
    _spawnTimer += scaledDt;
    _weaponTimer += scaledDt;
    _hudTimer += scaledDt;

    _spawnEnemies();
    _moveEnemies(scaledDt);
    _resolveEnemySeparation();
    _resolveEnemyPlayerSeparation();
    _faceNearestEnemy();
    _fireWeapon();
    _resolveProjectileHits();
    _resolvePlayerHits();
    _updateGems(scaledDt);
    _checkBattleEnd();
    _syncHud();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Offset.zero & Size(size.x, size.y), _backgroundPaint);
    canvas.save();
    final cameraOffset = _cameraOffset;
    canvas.translate(cameraOffset.x, cameraOffset.y);
    _drawGrid(canvas);
    _drawAttackRange(canvas);
    super.render(canvas);
    canvas.restore();
  }

  void _drawGrid(Canvas canvas) {
    const cellSize = 32.0;
    final left = player.position.x - size.x / 2;
    final right = player.position.x + size.x / 2;
    final top = player.position.y - size.y / 2;
    final bottom = player.position.y + size.y / 2;
    final startX = (left / cellSize).floor() * cellSize;
    final startY = (top / cellSize).floor() * cellSize;

    for (var x = startX; x <= right; x += cellSize) {
      canvas.drawLine(Offset(x, top), Offset(x, bottom), _gridPaint);
    }
    for (var y = startY; y <= bottom; y += cellSize) {
      canvas.drawLine(Offset(left, y), Offset(right, y), _gridPaint);
    }
  }

  Vector2 get _cameraOffset {
    return Vector2(
        size.x / 2 - player.position.x, size.y / 2 - player.position.y);
  }

  void _drawAttackRange(Canvas canvas) {
    final center = Offset(player.position.x, player.position.y);
    canvas.drawCircle(center, _attackRange, _attackRangeFillPaint);
    canvas.drawCircle(center, _attackRange, _attackRangeStrokePaint);
  }

  void _spawnEnemies() {
    if (_bossSpawned) {
      return;
    }
    if (_killCount >= stageEnemyCount) {
      _spawnBoss();
      return;
    }
    final wave = _activeWave();
    if (wave == null || _spawnTimer < wave.spawnIntervalSeconds) {
      return;
    }
    _spawnTimer = 0;

    final enemyId = _enemyIdForWave(wave.enemyId);
    final enemyConfig = _enemyConfig(enemyId) ?? config.enemies.first;
    final enemy = EnemyComponent(
      enemyId: enemyConfig.id,
      maxHp: math.max(
        1,
        (enemyConfig.hp * stageEnemyStrengthMultiplier).round(),
      ),
      moveSpeed: enemyConfig.moveSpeed *
          math.min(1.45, 0.92 + stageEnemyStrengthMultiplier * 0.08),
      expDrop: enemyConfig.expDrop,
      position: _randomSpawnPosition(),
      animationSet: _enemyAnimations[enemyConfig.id],
    );
    _enemies.add(enemy);
    add(enemy);
  }

  String _enemyIdForWave(String fallbackEnemyId) {
    if (stageEnemyTypes.isEmpty) {
      return fallbackEnemyId;
    }
    if (stageEnemyTypes.contains(fallbackEnemyId)) {
      return fallbackEnemyId;
    }
    final elapsedBucket = (_elapsed ~/ 30).clamp(0, stageEnemyTypes.length - 1);
    return stageEnemyTypes[elapsedBucket];
  }

  void _spawnBoss() {
    if (_bossSpawned) {
      return;
    }
    _bossSpawned = true;
    final boss = EnemyComponent(
      enemyId: 'boss',
      maxHp: bossMaxHp + _level * 24,
      moveSpeed: 34,
      expDrop: 25,
      position: _randomSpawnPosition(),
      animationSet: _enemyAnimations['boss'],
    );
    _enemies.add(boss);
    add(boss);
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
    return null;
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
    final cooldown = math.max(
      0.06,
      weaponFireIntervalSeconds * _cooldownMultiplier,
    );
    if (_weaponTimer < cooldown || _enemies.isEmpty) {
      return;
    }

    final target = _nearestEnemy(maxDistance: _attackRange);
    if (target == null) {
      return;
    }

    _weaponTimer = 0;
    final direction = target.position - player.position;
    if (direction.length2 == 0) {
      return;
    }
    direction.normalize();
    final spawnPosition = player.position + direction * 34;
    final projectile = ProjectileComponent(
      damage: _weaponDamage,
      maxTravelDistance: _attackRange,
      velocity: direction * 380,
      position: spawnPosition,
      visualStyle: ProjectileVisualStyle.forKind(weaponKind),
      image: _projectileImage,
    );
    _projectiles.add(projectile);
    add(projectile);

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

  void _playFireSound(double cooldown) {
    final pool = _fireSoundPool;
    if (pool == null) {
      return;
    }

    final volume = cooldown < 0.12 ? 0.18 : 0.34;
    unawaited(pool.start(volume: volume));
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
    for (final enemy in _enemies) {
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

  void _moveEnemies(double dt) {
    for (final enemy in _enemies) {
      enemy.moveToward(player.position, dt);
    }
  }

  void _resolveEnemySeparation() {
    for (var i = 0; i < _enemies.length; i++) {
      final first = _enemies[i];
      for (var j = i + 1; j < _enemies.length; j++) {
        final second = _enemies[j];
        final minDistance = first.collisionRadius + second.collisionRadius + 2;
        final delta = second.position - first.position;
        final distanceSquared = delta.length2;
        if (distanceSquared >= minDistance * minDistance) {
          continue;
        }

        final direction = _safeDirection(delta, i + j);
        final distance =
            distanceSquared <= 0 ? 0.0 : math.sqrt(distanceSquared);
        final push = (minDistance - distance) / 2;
        first.position -= direction * push;
        second.position += direction * push;
      }
    }
  }

  void _resolveEnemyPlayerSeparation() {
    for (final enemy in _enemies) {
      final minDistance = enemy.collisionRadius + player.collisionRadius;
      final delta = enemy.position - player.position;
      final distanceSquared = delta.length2;
      if (distanceSquared >= minDistance * minDistance) {
        continue;
      }

      final direction = _safeDirection(delta, _enemies.indexOf(enemy));
      final distance = distanceSquared <= 0 ? 0.0 : math.sqrt(distanceSquared);
      final push = minDistance - distance;
      enemy.position += direction * push;
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
    final removedProjectiles = <ProjectileComponent>[];
    final removedEnemies = <EnemyComponent>[];

    for (final projectile in _projectiles) {
      if (projectile.hasExceededRange ||
          projectile.age > 1.8 ||
          !_isInsideProjectileBounds(projectile)) {
        removedProjectiles.add(projectile);
        continue;
      }

      for (final enemy in _enemies) {
        if (enemy.isDead) {
          continue;
        }
        final hitDistance = projectile.radius + enemy.collisionRadius;
        if (projectile.position.distanceToSquared(enemy.position) >
            hitDistance * hitDistance) {
          continue;
        }

        enemy.takeDamage(projectile.damage);
        removedProjectiles.add(projectile);
        if (enemy.isDead) {
          removedEnemies.add(enemy);
          if (enemy.enemyId == 'boss') {
            _finish(isWin: true);
            return;
          }
        }
        break;
      }
    }

    for (final projectile in removedProjectiles.toSet()) {
      _projectiles.remove(projectile);
      projectile.removeFromParent();
    }
    for (final enemy in removedEnemies.toSet()) {
      _killCount++;
      _spawnGem(enemy);
      _enemies.remove(enemy);
      enemy.removeFromParent();
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

  void _spawnGem(EnemyComponent enemy) {
    final expGem = ExpGemComponent(
      exp: _rollExpDrop(),
      coins: 0,
      icons: _dropIcons,
      position: _randomDropPosition(enemy.position),
    );
    _gems.add(expGem);
    add(expGem);

    final coins = _rollCoinDrop();
    if (coins <= 0) {
      return;
    }

    final coinGem = ExpGemComponent(
      exp: 0,
      coins: coins,
      icons: _dropIcons,
      position: _randomDropPosition(enemy.position),
    );
    _gems.add(coinGem);
    add(coinGem);
  }

  int _rollExpDrop() {
    final roll = _random.nextDouble();
    if (roll < 0.01) {
      return 5;
    }
    if (roll < 0.11) {
      return 3;
    }
    return 1;
  }

  int _rollCoinDrop() {
    if (_random.nextDouble() >= 0.5) {
      return 0;
    }

    final roll = _random.nextDouble();
    if (roll < 0.01) {
      return 8 + _random.nextInt(3);
    }
    if (roll < 0.11) {
      return 4 + _random.nextInt(4);
    }
    return 1 + _random.nextInt(3);
  }

  Vector2 _randomDropPosition(Vector2 origin) {
    final angle = _random.nextDouble() * math.pi * 2;
    final distance = 8 + _random.nextDouble() * 22;
    return origin + Vector2(math.cos(angle), math.sin(angle)) * distance;
  }

  void _resolvePlayerHits() {
    for (final enemy in _enemies) {
      final hitDistance = enemy.collisionRadius + player.collisionRadius;
      if (enemy.position.distanceToSquared(player.position) >
          hitDistance * hitDistance) {
        continue;
      }
      if (player.takeDamage(8) && player.isDead) {
        _finish(isWin: false);
        return;
      }
    }
  }

  void _updateGems(double dt) {
    final collected = <ExpGemComponent>[];
    for (final gem in _gems) {
      final pickupDistance = player.pickupRange;
      if (gem.position.distanceToSquared(player.position) <=
          pickupDistance * pickupDistance) {
        gem.isAttracted = true;
      }
      if (gem.isAttracted) {
        gem.moveToward(player.position, dt);
      }
      final collectDistance = player.collisionRadius + gem.radius;
      if (gem.position.distanceToSquared(player.position) <=
          collectDistance * collectDistance) {
        collected.add(gem);
      }
    }

    for (final gem in collected) {
      _gems.remove(gem);
      gem.removeFromParent();
      _coins += gem.coins;
      _battleExpCollected += gem.exp;
      _addExp(gem.exp);
    }
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
    controller.setPendingLevelUps(_pendingLevelUps);
    _syncHud(force: true);
  }

  void openLevelUpChoices() {
    if (_pendingLevelUps <= 0 ||
        controller.levelUpOptions.isNotEmpty ||
        _finished) {
      return;
    }
    final selector = const SkillOptionSelector();
    controller.showLevelUp(selector.selectOptions(config.skills));
    pauseEngine();
  }

  int get _requiredExp {
    return (config.balance.baseExpToLevelUp * math.pow(_level, 1.45)).floor();
  }

  void applySkill(String skillId) {
    switch (skillId) {
      case 'boots':
        player.moveSpeed *= 1.12;
      case 'magnet':
        player.pickupRange *= 1.22;
      case 'haste':
        _cooldownMultiplier *= 0.9;
      case 'might':
        _weaponDamage += 1;
      case 'arrow':
        _weaponDamage += 1;
        _cooldownMultiplier *= 0.94;
    }

    if (_pendingLevelUps > 0) {
      _pendingLevelUps--;
    }
    controller.setPendingLevelUps(_pendingLevelUps);
    controller.clearLevelUp();
    resumeEngine();
    _syncHud(force: true);
  }

  void _checkBattleEnd() {
    if (_elapsed >= bossTimeSeconds && !_bossSpawned) {
      _spawnBoss();
    }
  }

  void _finish({required bool isWin}) {
    if (_finished) {
      return;
    }
    _finished = true;
    pauseEngine();
    controller.finish(
      GameResult(
        survivalSeconds: _elapsed.floor(),
        killCount: _killCount,
        level: _level,
        isWin: isWin,
        coinsEarned: _coins + (isWin ? stageRewardCoins : 0),
        characterExpEarned: isWin ? _battleExpCollected + stageRewardExp : 0,
      ),
    );
    _syncHud(force: true);
  }

  void finishEarly() {
    _finish(isWin: false);
  }

  void _syncHud({bool force = false}) {
    if (!force && _hudTimer < 0.1) {
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
        elapsedSeconds: _elapsed.floor(),
        killCount: _killCount,
        maxBattleSeconds: config.balance.maxBattleSeconds,
        coins: _coins,
      ),
    );
  }
}
