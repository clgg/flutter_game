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
}

class CharacterDefinition {
  const CharacterDefinition({
    required this.id,
    required this.name,
    required this.role,
    required this.baseHp,
    required this.baseSpeedMultiplier,
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

  int get playerMaxHp => character.baseHp + (profileLevel - 1) * 4;

  double get playerMoveSpeedMultiplier {
    return character.baseSpeedMultiplier + (profileLevel - 1) * 0.01;
  }

  String get playerSpriteSheetAssetPath => character.gameSpriteSheetAssetPath;

  int get weaponDamage => weapon.damage + (weaponProgress.level - 1) * 2;

  double get weaponCooldownMultiplier {
    return math.max(0.55, 1 - (weaponProgress.level - 1) * 0.06);
  }

  double get weaponFireIntervalSeconds {
    return 60 / weapon.fireRateRoundsPerMinute;
  }
}

class GrassGameProgressController extends ChangeNotifier {
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
    const weapons = grassGameWeaponCatalog;

    final controller = GrassGameProgressController(
      characters: const [
        CharacterDefinition(
          id: 'runner',
          name: 'Male',
          role: 'Balanced',
          baseHp: 100,
          baseSpeedMultiplier: 1,
          colorValue: 0xFF49D17D,
          avatarAssetPath:
              'assets/game/grass_game/images/player/avatar_soldier.webp',
          walkPreviewAssetPath:
              'assets/game/grass_game/images/player/preview_male_walk.gif',
          gameSpriteSheetAssetPath:
              'assets/game/grass_game/images/player/player_soldier_walk_sheet.png',
          isOwned: true,
        ),
        CharacterDefinition(
          id: 'guard',
          name: 'Female',
          role: 'High HP',
          baseHp: 124,
          baseSpeedMultiplier: 0.92,
          colorValue: 0xFFFF6B6B,
          avatarAssetPath:
              'assets/game/grass_game/images/player/avatar_female.webp',
          walkPreviewAssetPath:
              'assets/game/grass_game/images/player/preview_female_walk.gif',
          gameSpriteSheetAssetPath:
              'assets/game/grass_game/images/player/player_female_walk_sheet.png',
          isOwned: true,
        ),
        CharacterDefinition(
          id: 'scout',
          name: 'Robot',
          role: 'Fast',
          baseHp: 84,
          baseSpeedMultiplier: 1.16,
          colorValue: 0xFFFFC857,
          avatarAssetPath:
              'assets/game/grass_game/images/player/avatar_robot.webp',
          walkPreviewAssetPath:
              'assets/game/grass_game/images/player/preview_robot_walk.gif',
          gameSpriteSheetAssetPath:
              'assets/game/grass_game/images/player/player_robot_walk_sheet.png',
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
      coins: 10160,
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

  static final List<GameStageDefinition> _stages = [
    for (var chapter = 1; chapter <= 10; chapter++)
      for (var stage = 1; stage <= 5 + (chapter % 4); stage++)
        _createStage(chapter, stage),
  ];

  static GameStageDefinition _createStage(int chapter, int stage) {
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
      if (chapter >= 2 || stage >= 3) 'fast',
      if (chapter >= 4 || stage >= 5) 'tank',
    ];
    final bossTimeSeconds = 210 + chapter * 8 + stage * 10;
    return GameStageDefinition(
      id: 'c${chapter}_s$stage',
      chapter: chapter,
      stage: stage,
      name: 'Chapter $chapter-$stage',
      description:
          'Clear wave ${chapter * 10 + stage} and defeat ${bossNames[bossIndex]}.',
      difficulty: chapter * 10 + stage,
      enemyCount: 70 + chapter * 16 + stage * 7,
      enemyStrengthMultiplier: double.parse(
          (1 + (chapter - 1) * 0.18 + (stage - 1) * 0.05).toStringAsFixed(2)),
      enemyTypes: enemyTypes,
      bossTimeSeconds: bossTimeSeconds,
      rewardExp: 80 + chapter * 18 + stage * 6,
      rewardCoins: 25 + chapter * 5 + stage * 2,
      bossId: bossIds[bossIndex],
      bossName: bossNames[bossIndex],
      bossSpriteSheetAssetPath:
          'assets/game/grass_game/images/bosses/boss_${bossIds[bossIndex]}_walk.png',
      bossDeathAssetPath:
          'assets/game/grass_game/images/bosses/boss_${bossIds[bossIndex]}_dead.png',
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

  void selectStage(String id) {
    selectedStageId = id;
    unawaited(save());
    notifyListeners();
  }

  int upgradeCost(String weaponId) {
    final progress = progressFor(weaponId);
    return 70 + progress.level * 45;
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
    if (savedStageId != null &&
        _stages.any((item) => item.id == savedStageId)) {
      selectedStageId = savedStageId;
    }

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
