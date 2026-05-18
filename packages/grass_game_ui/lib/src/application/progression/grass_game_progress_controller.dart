import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:grass_game_domain/grass_game_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weapon_catalog.dart';
import 'weapon_definition.dart';
export 'weapon_definition.dart';

class GameStageDefinition {
  const GameStageDefinition({
    required this.id,
    required this.chapter,
    required this.stage,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.enemyCount,
    required this.enemyStrengthMultiplier,
    required this.enemyTypes,
    required this.bossTimeSeconds,
    required this.rewardExp,
    required this.rewardCoins,
    required this.bossId,
    required this.bossName,
    required this.bossSpriteSheetAssetPath,
    required this.bossDeathAssetPath,
    this.isDeathmatch = false,
  });

  final String id;
  final int chapter;
  final int stage;
  final String name;
  final String description;
  final int difficulty;
  final int enemyCount;
  final double enemyStrengthMultiplier;
  final List<String> enemyTypes;
  final int bossTimeSeconds;
  final int rewardExp;
  final int rewardCoins;
  final String bossId;
  final String bossName;
  final String bossSpriteSheetAssetPath;
  final String bossDeathAssetPath;
  final bool isDeathmatch;
}

class CharacterDefinition {
  const CharacterDefinition({
    required this.id,
    required this.name,
    required this.role,
    required this.baseHp,
    required this.baseSpeedMultiplier,
    required this.baseAttackMultiplier,
    required this.colorValue,
    required this.avatarAssetPath,
    required this.walkPreviewAssetPath,
    required this.gameSpriteSheetAssetPath,
    required this.isOwned,
  });

  final String id;
  final String name;
  final String role;
  final int baseHp;
  final double baseSpeedMultiplier;
  final double baseAttackMultiplier;
  final int colorValue;
  final String avatarAssetPath;
  final String walkPreviewAssetPath;
  final String gameSpriteSheetAssetPath;
  final bool isOwned;
}

class WeaponProgress {
  const WeaponProgress({
    required this.weaponId,
    required this.isOwned,
    required this.level,
  });

  final String weaponId;
  final bool isOwned;
  final int level;

  WeaponProgress copyWith({
    bool? isOwned,
    int? level,
  }) {
    return WeaponProgress(
      weaponId: weaponId,
      isOwned: isOwned ?? this.isOwned,
      level: level ?? this.level,
    );
  }
}

class GameLoadoutSnapshot {
  const GameLoadoutSnapshot({
    required this.character,
    required this.weapon,
    required this.weaponProgress,
    required this.profileLevel,
    required this.stage,
  });

  final CharacterDefinition character;
  final WeaponDefinition weapon;
  final WeaponProgress weaponProgress;
  final int profileLevel;
  final GameStageDefinition stage;

  static const int _profileHpGainPerLevel = 8;
  static const double _profileSpeedGainPerLevel = 0.006;
  static const double _profileSpeedGainCap = 0.18;
  static const double _profileAttackGainPerLevel = 0.015;
  static const double _weaponDamageGainPerLevel = 0.09;
  static const double _weaponCooldownGainPerLevel = 0.055;
  static const double _weaponCooldownMinMultiplier = 0.42;

  int get playerMaxHp {
    return character.baseHp + (profileLevel - 1) * _profileHpGainPerLevel;
  }

  double get playerMoveSpeedMultiplier {
    return character.baseSpeedMultiplier +
        math.min(
          _profileSpeedGainCap,
          (profileLevel - 1) * _profileSpeedGainPerLevel,
        );
  }

  String get playerSpriteSheetAssetPath => character.gameSpriteSheetAssetPath;

  int get weaponDamage {
    final weaponMultiplier =
        1 + (weaponProgress.level - 1) * _weaponDamageGainPerLevel;
    final profileMultiplier =
        1 + (profileLevel - 1) * _profileAttackGainPerLevel;
    final multiplier =
        character.baseAttackMultiplier * weaponMultiplier * profileMultiplier;
    return math.max(1, (weapon.damage * multiplier).round());
  }

  double get weaponCooldownMultiplier {
    final multiplier =
        1 + (weaponProgress.level - 1) * _weaponCooldownGainPerLevel;
    return math.max(_weaponCooldownMinMultiplier, 1 / multiplier);
  }

  double get weaponFireIntervalSeconds {
    return 60 / weapon.fireRateRoundsPerMinute;
  }
}

class GrassGameProgressController extends ChangeNotifier {
  static const deathmatchStageId = 'deathmatch';

  GrassGameProgressController({
    required this.characters,
    required this.weapons,
    required Map<String, WeaponProgress> weaponProgress,
    required this.coins,
    required this.profileLevel,
    required this.profileExp,
    required this.selectedCharacterId,
    required this.selectedWeaponId,
    required this.selectedStageId,
    required Set<String> completedStageIds,
  })  : _weaponProgress = Map.of(weaponProgress),
        _completedStageIds = Set.of(completedStageIds);

  factory GrassGameProgressController.defaults() {
    final weapons = _limitWeaponsPerStar(grassGameWeaponCatalog, limit: 20);

    final controller = GrassGameProgressController(
      characters: const [
        CharacterDefinition(
          id: 'runner',
          name: 'Male',
          role: 'HP 130 · SPD 8 · ATK 1.00',
          baseHp: 130,
          baseSpeedMultiplier: 1,
          baseAttackMultiplier: 1,
          colorValue: 0xFF49D17D,
          avatarAssetPath:
              'assets/game/grass_game/images/player/avatar_soldier.png',
          walkPreviewAssetPath:
              'assets/game/grass_game/images/player/preview_male_walk.gif',
          gameSpriteSheetAssetPath:
              'assets/game/grass_game/images/player/player_soldier_walk_sheet.png',
          isOwned: true,
        ),
        CharacterDefinition(
          id: 'guard',
          name: 'Female',
          role: 'HP 105 · SPD 9 · ATK 0.95',
          baseHp: 105,
          baseSpeedMultiplier: 1.125,
          baseAttackMultiplier: 0.95,
          colorValue: 0xFFFF6B6B,
          avatarAssetPath:
              'assets/game/grass_game/images/player/avatar_female.png',
          walkPreviewAssetPath:
              'assets/game/grass_game/images/player/preview_female_walk.gif',
          gameSpriteSheetAssetPath:
              'assets/game/grass_game/images/player/player_female_walk_sheet.png',
          isOwned: true,
        ),
        CharacterDefinition(
          id: 'scout',
          name: 'Robot',
          role: 'HP 150 · SPD 7 · ATK 1.08',
          baseHp: 150,
          baseSpeedMultiplier: 0.875,
          baseAttackMultiplier: 1.08,
          colorValue: 0xFFFFC857,
          avatarAssetPath:
              'assets/game/grass_game/images/player/avatar_robot.png',
          walkPreviewAssetPath:
              'assets/game/grass_game/images/player/preview_robot_walk.gif',
          gameSpriteSheetAssetPath:
              'assets/game/grass_game/images/player/player_robot_walk_sheet.png',
          isOwned: true,
        ),
        CharacterDefinition(
          id: 'aotuman',
          name: '凹凸曼',
          role: 'HP 220 · SPD 9 · ATK 1.05',
          baseHp: 220,
          baseSpeedMultiplier: 1.125,
          baseAttackMultiplier: 1.05,
          colorValue: 0xFFE63946,
          avatarAssetPath:
              'assets/game/grass_game/images/player/avatar_aotuman.png',
          walkPreviewAssetPath:
              'assets/game/grass_game/images/player/preview_aotuman_walk.gif',
          gameSpriteSheetAssetPath:
              'assets/game/grass_game/images/player/player_aotuman_walk_sheet.png',
          isOwned: true,
        ),
        CharacterDefinition(
          id: 'aomeijia',
          name: '奥美家',
          role: 'HP 170 · SPD 10 · ATK 0.96',
          baseHp: 170,
          baseSpeedMultiplier: 1.25,
          baseAttackMultiplier: 0.96,
          colorValue: 0xFF27D6FF,
          avatarAssetPath:
              'assets/game/grass_game/images/player/avatar_aomeijia.png',
          walkPreviewAssetPath:
              'assets/game/grass_game/images/player/preview_aomeijia_walk.gif',
          gameSpriteSheetAssetPath:
              'assets/game/grass_game/images/player/player_aomeijia_sword_walk_sheet.png',
          isOwned: true,
        ),
        CharacterDefinition(
          id: 'jingangman',
          name: '金刚曼',
          role: 'HP 320 · SPD 8 · ATK 1.18',
          baseHp: 320,
          baseSpeedMultiplier: 1,
          baseAttackMultiplier: 1.18,
          colorValue: 0xFFB65B4A,
          avatarAssetPath:
              'assets/game/grass_game/images/player/avatar_jingangman.png',
          walkPreviewAssetPath:
              'assets/game/grass_game/images/player/preview_jingangman_walk.gif',
          gameSpriteSheetAssetPath:
              'assets/game/grass_game/images/player/player_dark_cosmic_knight_walk_sheet.png',
          isOwned: true,
        ),
        CharacterDefinition(
          id: 'beliya',
          name: '贝利牙',
          role: 'HP 260 · SPD 9 · ATK 1.12',
          baseHp: 260,
          baseSpeedMultiplier: 1.125,
          baseAttackMultiplier: 1.12,
          colorValue: 0xFFFF3B4F,
          avatarAssetPath:
              'assets/game/grass_game/images/player/avatar_beliya.png',
          walkPreviewAssetPath:
              'assets/game/grass_game/images/player/preview_beliya_walk.gif',
          gameSpriteSheetAssetPath:
              'assets/game/grass_game/images/player/player_beliya_dark_cape_walk_sheet.png',
          isOwned: true,
        ),
        CharacterDefinition(
          id: 'sevengar',
          name: '赛文加',
          role: 'HP 430 · SPD 6 · ATK 1.28',
          baseHp: 430,
          baseSpeedMultiplier: 0.75,
          baseAttackMultiplier: 1.28,
          colorValue: 0xFFB8C2CC,
          avatarAssetPath:
              'assets/game/grass_game/images/player/avatar_sevengar.png',
          walkPreviewAssetPath:
              'assets/game/grass_game/images/player/preview_sevengar_walk.gif',
          gameSpriteSheetAssetPath:
              'assets/game/grass_game/images/player/player_round_robot_walk_sheet.png',
          isOwned: true,
        ),
      ],
      weapons: weapons,
      weaponProgress: {
        for (final weapon in weapons)
          weapon.id: WeaponProgress(
            weaponId: weapon.id,
            isOwned: weapon.buyCost == 0,
            level: 1,
          ),
      },
      coins: 320,
      profileLevel: 1,
      profileExp: 0,
      selectedCharacterId: 'runner',
      selectedWeaponId: weapons.first.id,
      selectedStageId: _stages.first.id,
      completedStageIds: const {},
    );
    unawaited(controller.restore());
    return controller;
  }

  static List<WeaponDefinition> _limitWeaponsPerStar(
    List<WeaponDefinition> weapons, {
    required int limit,
  }) {
    final countsByStar = <int, int>{};
    final selected = <WeaponDefinition>[];
    for (final weapon in weapons) {
      final count = countsByStar[weapon.maxStars] ?? 0;
      if (count >= limit) {
        continue;
      }
      countsByStar[weapon.maxStars] = count + 1;
      selected.add(weapon);
    }
    return selected;
  }

  static const _storagePrefix = 'grass_game_progress.';
  static const _coinsKey = '${_storagePrefix}coins';
  static const _profileLevelKey = '${_storagePrefix}profile_level';
  static const _profileExpKey = '${_storagePrefix}profile_exp';
  static const _selectedCharacterKey = '${_storagePrefix}selected_character';
  static const _selectedWeaponKey = '${_storagePrefix}selected_weapon';
  static const _selectedStageKey = '${_storagePrefix}selected_stage';
  static const _ownedWeaponsKey = '${_storagePrefix}owned_weapons';
  static const _weaponLevelsKey = '${_storagePrefix}weapon_levels';
  static const _completedStagesKey = '${_storagePrefix}completed_stages';
  static const _weaponUpgradeMinBaseCost = 70;
  static const _weaponUpgradeBuyCostRatio = 0.12;
  static const _weaponUpgradeCostGrowth = 1.16;

  static final List<GameStageDefinition> _stages = [
    for (var chapter = 1; chapter <= 10; chapter++)
      for (var stage = 1; stage <= 5 + (chapter % 4); stage++)
        _createStage(chapter, stage),
    _deathmatchStage,
  ];

  static const List<String> _deathmatchEnemyTypes = [
    'guaishou_black_armored_beetle',
    'guaishou_black_white_armor',
    'guaishou_blue_antenna_alien',
    'guaishou_gold_snail_mouth',
    'guaishou_gray_block_head',
    'guaishou_horned_brute',
    'guaishou_insect_claw',
    'guaishou_red_gold_spear_alien',
    'guaishou_shell_kaiju',
    'guaishou_silver_mask_rifle',
    'guaishou_spiked_mane_beast',
    'guaishou_winged_dragon',
  ];

  static const GameStageDefinition _deathmatchStage = GameStageDefinition(
    id: deathmatchStageId,
    chapter: 11,
    stage: 1,
    name: '死斗模式',
    description:
        'Endless melee survival. Guaishou become stronger every minute.',
    difficulty: 99,
    enemyCount: 0,
    enemyStrengthMultiplier: 1.25,
    enemyTypes: _deathmatchEnemyTypes,
    bossTimeSeconds: 600,
    rewardExp: 0,
    rewardCoins: 0,
    bossId: 'deathmatch',
    bossName: 'Endless',
    bossSpriteSheetAssetPath:
        'assets/game/grass_game/images/bosses/boss_tiger_walk.png',
    bossDeathAssetPath:
        'assets/game/grass_game/images/bosses/boss_tiger_dead.png',
    isDeathmatch: true,
  );

  static GameStageDefinition _createStage(int chapter, int stage) {
    if (chapter == 1 && stage <= 5) {
      return _createEarlyStage(stage);
    }

    const bossIds = [
      'tiger',
      'crocodile',
      'zombie',
      'skeleton',
      'trex',
      'dragon',
    ];
    const bossNames = [
      'Tiger',
      'Crocodile',
      'Zombie',
      'Skeleton',
      'T-Rex',
      'Wyvern',
    ];
    final bossIndex = (chapter + stage - 2) % bossIds.length;
    final enemyTypes = <String>[
      'basic',
      'lamb',
      'piglet',
      if (chapter >= 2 || stage >= 2) 'calf',
      if (chapter >= 2 || stage >= 3) 'fast',
      if (chapter >= 3 || stage >= 3) 'rooster',
      if (chapter >= 4 || stage >= 4) 'turkey',
      if (chapter >= 4 || stage >= 5) 'tank',
    ];
    final bossTimeSeconds = 220 + chapter * 9 + stage * 11;
    return GameStageDefinition(
      id: 'c${chapter}_s$stage',
      chapter: chapter,
      stage: stage,
      name: 'Chapter $chapter-$stage',
      description:
          'Clear wave ${chapter * 10 + stage} and defeat ${bossNames[bossIndex]}.',
      difficulty: chapter * 10 + stage,
      enemyCount: (56 + chapter * 13 + stage * 6) * 4,
      enemyStrengthMultiplier: double.parse(
        (0.96 + (chapter - 1) * 0.16 + (stage - 1) * 0.055).toStringAsFixed(2),
      ),
      enemyTypes: enemyTypes,
      bossTimeSeconds: bossTimeSeconds,
      rewardExp: 135 + chapter * 26 + stage * 10,
      rewardCoins: 65 + chapter * 13 + stage * 8,
      bossId: bossIds[bossIndex],
      bossName: bossNames[bossIndex],
      bossSpriteSheetAssetPath:
          'assets/game/grass_game/images/bosses/boss_${bossIds[bossIndex]}_walk.png',
      bossDeathAssetPath:
          'assets/game/grass_game/images/bosses/boss_${bossIds[bossIndex]}_dead.png',
    );
  }

  static GameStageDefinition _createEarlyStage(int stage) {
    const bossIds = ['tiger', 'crocodile', 'zombie', 'skeleton', 'trex'];
    const bossNames = ['Tiger', 'Crocodile', 'Zombie', 'Skeleton', 'T-Rex'];
    const enemyCounts = [150, 210, 280, 350, 430];
    const bossTimes = [145, 170, 200, 230, 260];
    const strength = [0.78, 0.9, 1.02, 1.16, 1.3];
    const rewardExp = [90, 115, 145, 180, 225];
    const rewardCoins = [60, 85, 115, 155, 210];
    final index = stage - 1;
    final enemyTypes = <String>[
      'basic',
      'lamb',
      'piglet',
      if (stage >= 2) 'calf',
      if (stage >= 2) 'fast',
      if (stage >= 3) 'rooster',
      if (stage >= 4) 'turkey',
      if (stage >= 4) 'tank',
    ];
    return GameStageDefinition(
      id: 'c1_s$stage',
      chapter: 1,
      stage: stage,
      name: 'Chapter 1-$stage',
      description: switch (stage) {
        1 => 'Learn movement, collect EXP, and defeat the first Tiger.',
        2 => 'Fast enemies enter the field. Keep moving.',
        3 => 'Weapon upgrades begin to matter against denser waves.',
        4 => 'Tank enemies test your damage and spacing.',
        _ => 'First real challenge before Chapter 2 unlocks.',
      },
      difficulty: 10 + stage,
      enemyCount: enemyCounts[index],
      enemyStrengthMultiplier: strength[index],
      enemyTypes: enemyTypes,
      bossTimeSeconds: bossTimes[index],
      rewardExp: rewardExp[index],
      rewardCoins: rewardCoins[index],
      bossId: bossIds[index],
      bossName: bossNames[index],
      bossSpriteSheetAssetPath:
          'assets/game/grass_game/images/bosses/boss_${bossIds[index]}_walk.png',
      bossDeathAssetPath:
          'assets/game/grass_game/images/bosses/boss_${bossIds[index]}_dead.png',
    );
  }

  final List<CharacterDefinition> characters;
  final List<WeaponDefinition> weapons;
  final Map<String, WeaponProgress> _weaponProgress;

  int coins;
  int profileLevel;
  int profileExp;
  String selectedCharacterId;
  String selectedWeaponId;
  String selectedStageId;
  final Set<String> _completedStageIds;

  List<GameStageDefinition> get stages => List.unmodifiable(_stages);

  GameStageDefinition get selectedStage {
    return _stages.firstWhere((item) => item.id == selectedStageId);
  }

  bool isStageCompleted(String stageId) => _completedStageIds.contains(stageId);

  String? get nextStageId {
    final index = _stages.indexWhere((item) => item.id == selectedStageId);
    if (index < 0 || index >= _stages.length - 1) {
      return null;
    }
    return _stages[index + 1].id;
  }

  bool get hasNextStage => nextStageId != null;

  bool canSelectStage(String stageId) {
    final index = _stages.indexWhere((item) => item.id == stageId);
    if (index < 0) {
      return false;
    }
    if (_stages[index].isDeathmatch || index == 0) {
      return true;
    }
    return _completedStageIds.contains(_stages[index - 1].id);
  }

  List<GameStageDefinition> stagesForChapter(int chapter) {
    return _stages.where((item) => item.chapter == chapter).toList();
  }

  int get requiredProfileExp {
    return (100 * math.pow(1.1, profileLevel - 1)).floor();
  }

  double get profileExpProgress {
    return requiredProfileExp == 0 ? 0 : profileExp / requiredProfileExp;
  }

  CharacterDefinition get selectedCharacter {
    return characters.firstWhere((item) => item.id == selectedCharacterId);
  }

  WeaponDefinition get selectedWeapon {
    return weapons.firstWhere((item) => item.id == selectedWeaponId);
  }

  WeaponProgress progressFor(String weaponId) {
    return _weaponProgress[weaponId] ??
        WeaponProgress(weaponId: weaponId, isOwned: false, level: 1);
  }

  GameLoadoutSnapshot get currentLoadout {
    return GameLoadoutSnapshot(
      character: selectedCharacter,
      weapon: selectedWeapon,
      weaponProgress: progressFor(selectedWeaponId),
      profileLevel: profileLevel,
      stage: selectedStage,
    );
  }

  bool selectCharacter(String id) {
    final character = characters.firstWhere((item) => item.id == id);
    if (!character.isOwned) {
      return false;
    }
    selectedCharacterId = id;
    unawaited(save());
    notifyListeners();
    return true;
  }

  bool selectWeapon(String id) {
    final progress = progressFor(id);
    if (!progress.isOwned) {
      return false;
    }
    selectedWeaponId = id;
    unawaited(save());
    notifyListeners();
    return true;
  }

  bool selectStage(String id) {
    if (!canSelectStage(id)) {
      return false;
    }
    selectedStageId = id;
    unawaited(save());
    notifyListeners();
    return true;
  }

  bool selectNextStage() {
    final id = nextStageId;
    if (id == null) {
      return false;
    }
    return selectStage(id);
  }

  int upgradeCost(String weaponId) {
    final progress = progressFor(weaponId);
    final weapon = weapons.firstWhere((item) => item.id == weaponId);
    final baseCost = math.max(
      _weaponUpgradeMinBaseCost,
      (weapon.buyCost * _weaponUpgradeBuyCostRatio).round(),
    );
    return (baseCost * math.pow(_weaponUpgradeCostGrowth, progress.level - 1))
        .ceil();
  }

  bool buyWeapon(String weaponId) {
    final weapon = weapons.firstWhere((item) => item.id == weaponId);
    final progress = progressFor(weaponId);
    if (progress.isOwned || coins < weapon.buyCost) {
      return false;
    }
    coins -= weapon.buyCost;
    _weaponProgress[weaponId] = progress.copyWith(isOwned: true);
    selectedWeaponId = weaponId;
    unawaited(save());
    notifyListeners();
    return true;
  }

  bool upgradeWeapon(String weaponId) {
    final progress = progressFor(weaponId);
    final cost = upgradeCost(weaponId);
    if (!progress.isOwned || coins < cost) {
      return false;
    }
    coins -= cost;
    _weaponProgress[weaponId] = progress.copyWith(level: progress.level + 1);
    unawaited(save());
    notifyListeners();
    return true;
  }

  void applyBattleResult(GameResult result) {
    coins += result.coinsEarned;
    if (result.isWin) {
      _completedStageIds.add(selectedStageId);
    }
    if (result.characterExpEarned > 0) {
      profileExp += result.characterExpEarned;
      while (profileExp >= requiredProfileExp) {
        profileExp -= requiredProfileExp;
        profileLevel++;
      }
    }
    unawaited(save());
    notifyListeners();
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    coins = math.max(0, prefs.getInt(_coinsKey) ?? coins);
    profileLevel = math.max(1, prefs.getInt(_profileLevelKey) ?? profileLevel);
    profileExp = math.max(0, prefs.getInt(_profileExpKey) ?? profileExp);

    final savedCharacterId = prefs.getString(_selectedCharacterKey);
    if (savedCharacterId != null &&
        characters.any((item) => item.id == savedCharacterId)) {
      selectedCharacterId = savedCharacterId;
    }

    final savedStageId = prefs.getString(_selectedStageKey);

    final ownedWeapons = prefs.getStringList(_ownedWeaponsKey) ?? const [];
    final weaponLevels = _decodeWeaponLevels(
      prefs.getStringList(_weaponLevelsKey) ?? const [],
    );
    for (final weapon in weapons) {
      final progress = progressFor(weapon.id);
      _weaponProgress[weapon.id] = progress.copyWith(
        isOwned: progress.isOwned || ownedWeapons.contains(weapon.id),
        level: math.max(1, weaponLevels[weapon.id] ?? progress.level),
      );
    }
    final savedWeaponId = prefs.getString(_selectedWeaponKey);
    if (savedWeaponId != null && progressFor(savedWeaponId).isOwned) {
      selectedWeaponId = savedWeaponId;
    }
    _completedStageIds
      ..clear()
      ..addAll(
        (prefs.getStringList(_completedStagesKey) ?? const []).where(
          (id) => _stages.any((item) => item.id == id),
        ),
      );
    if (savedStageId != null &&
        _stages.any((item) => item.id == savedStageId) &&
        canSelectStage(savedStageId)) {
      selectedStageId = savedStageId;
    } else if (!canSelectStage(selectedStageId)) {
      selectedStageId = _stages.first.id;
    }
    notifyListeners();
  }

  Future<void> loadSavedProgress() => restore();

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, coins);
    await prefs.setInt(_profileLevelKey, profileLevel);
    await prefs.setInt(_profileExpKey, profileExp);
    await prefs.setString(_selectedCharacterKey, selectedCharacterId);
    await prefs.setString(_selectedWeaponKey, selectedWeaponId);
    await prefs.setString(_selectedStageKey, selectedStageId);
    await prefs.setStringList(
      _ownedWeaponsKey,
      [
        for (final entry in _weaponProgress.entries)
          if (entry.value.isOwned) entry.key,
      ]..sort(),
    );
    await prefs.setStringList(
      _weaponLevelsKey,
      [
        for (final entry in _weaponProgress.entries)
          '${entry.key}:${entry.value.level}',
      ],
    );
    await prefs.setStringList(
      _completedStagesKey,
      _completedStageIds.toList()..sort(),
    );
  }

  Future<void> saveProgress() => save();

  Map<String, int> _decodeWeaponLevels(List<String> values) {
    return {
      for (final value in values)
        if (value.split(':') case [final id, final level])
          id: int.tryParse(level) ?? 1,
    };
  }
}
