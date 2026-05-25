import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grass_game_domain/grass_game_domain.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';
import 'package:grass_game_ui/grass_game_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GrassGameProgressController', () {
    test('locks the next stage until the current stage is cleared', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      final firstStageId = controller.selectedStageId;
      final nextStageId = controller.nextStageId;

      expect(nextStageId, isNotNull);
      expect(controller.canSelectStage(firstStageId), isTrue);
      expect(controller.canSelectStage(nextStageId!), isFalse);
      expect(controller.selectStage(nextStageId), isFalse);

      controller.applyBattleResult(
        const GameResult(
          survivalSeconds: 300,
          killCount: 100,
          level: 8,
          isWin: true,
          coinsEarned: 25,
          characterExpEarned: 80,
        ),
      );

      expect(controller.isStageCompleted(firstStageId), isTrue);
      expect(controller.canSelectStage(nextStageId), isTrue);
      expect(controller.selectStage(nextStageId), isTrue);
    });

    test('does not unlock next stage after a failed run', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      final firstStageId = controller.selectedStageId;
      final nextStageId = controller.nextStageId!;

      controller.applyBattleResult(
        const GameResult(
          survivalSeconds: 80,
          killCount: 20,
          level: 3,
          isWin: false,
          coinsEarned: 12,
          characterExpEarned: 0,
        ),
      );

      expect(controller.isStageCompleted(firstStageId), isFalse);
      expect(controller.canSelectStage(nextStageId), isFalse);
    });

    test('buys and upgrades an owned weapon with persisted state shape',
        () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();
      final weapon = controller.weapons.firstWhere(
        (item) => !controller.progressFor(item.id).isOwned,
      );

      controller.coins = weapon.buyCost;

      expect(controller.buyWeapon(weapon.id), isTrue);
      expect(controller.selectedWeaponId, weapon.id);
      expect(controller.coins, 0);
      expect(controller.progressFor(weapon.id).isOwned, isTrue);
      expect(controller.upgradeWeapon(weapon.id), isFalse);

      final upgradeCost = controller.upgradeCost(weapon.id);
      controller.coins = upgradeCost;

      expect(controller.upgradeWeapon(weapon.id), isTrue);
      expect(controller.coins, 0);
      expect(controller.progressFor(weapon.id).level, 2);

      await controller.saveProgress();
      final restored = GrassGameProgressController.defaults();
      await restored.loadSavedProgress();

      expect(restored.selectedWeaponId, weapon.id);
      expect(restored.progressFor(weapon.id).isOwned, isTrue);
      expect(restored.progressFor(weapon.id).level, 2);
    });

    test('crafts recipe weapon without consuming material weapons', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      final material = controller.weapons.firstWhere(
        (item) => item.id == 'bounce_ball',
      );
      final crafted = controller.weapons.firstWhere(
        (item) => item.id == 'ball_hammer',
      );

      controller.coins = material.buyCost + controller.craftCost(crafted.id);

      expect(controller.buyWeapon(material.id), isTrue);
      expect(controller.canCraftWeapon(crafted.id), isTrue);
      expect(controller.craftWeapon(crafted.id), isTrue);
      expect(controller.progressFor(crafted.id).isOwned, isTrue);
      expect(controller.progressFor(crafted.id).isCrafted, isTrue);
      expect(controller.progressFor('wooden_stick').isOwned, isTrue);
      expect(controller.progressFor(material.id).isOwned, isTrue);
      expect(controller.selectedWeaponId, crafted.id);
    });

    test('restores invalid selected stage to the first playable stage',
        () async {
      SharedPreferences.setMockInitialValues({
        'grass_game_progress.selected_stage': 'c1_s3',
        'grass_game_progress.completed_stages': <String>[],
      });
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      expect(controller.selectedStageId, 'c1_s1');
    });

    test('loadout applies hero level and weapon upgrade scaling', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      final weapon = controller.selectedWeapon;
      final baseDamage = weapon.baseDamage;
      controller.profileLevel = 3;
      controller.coins = controller.upgradeCost(weapon.id);

      expect(controller.upgradeCost(weapon.id), 70);
      expect(controller.upgradeWeapon(weapon.id), isTrue);
      expect(controller.upgradeCost(weapon.id), 82);

      final loadout = controller.currentLoadout;
      expect(loadout.playerMaxHp, controller.selectedCharacter.baseHp + 16);
      expect(loadout.weaponDamage, (baseDamage * 1.10 * 1.03).round());
      expect(loadout.weaponAttacksPerSecond, closeTo(1.2 * 1.03, 0.001));
      expect(loadout.weaponRuntimeStats.attackPattern, 'meleeSweep');
      expect(loadout.weaponRuntimeStats.range, closeTo(70 * 1.03, 0.001));
    });

    test('early stage rewards follow in-run growth economy targets', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      final earlyStages = [
        for (var stage = 1; stage <= 5; stage++)
          controller.stages.firstWhere((item) => item.id == 'c1_s$stage'),
      ];

      expect(earlyStages.map((stage) => stage.enemyCount),
          [150, 210, 280, 350, 430]);
      expect(earlyStages.map((stage) => stage.bossTimeSeconds),
          [145, 170, 200, 230, 260]);
      expect(earlyStages.map((stage) => stage.enemyStrengthMultiplier),
          [0.78, 0.9, 1.02, 1.16, 1.3]);
      expect(earlyStages.map((stage) => stage.rewardCoins),
          [60, 85, 115, 155, 210]);
      expect(earlyStages.map((stage) => stage.rewardExp),
          [90, 115, 145, 180, 225]);
      expect(earlyStages.map((stage) => stage.themeId),
          ['farm', 'farm', 'farm', 'farm', 'farm']);
      expect(earlyStages.map((stage) => stage.themeName), [
        'Infected Farm',
        'Infected Farm',
        'Infected Farm',
        'Infected Farm',
        'Infected Farm'
      ]);
      expect(
        earlyStages.every(
          (stage) =>
              File(stage.sceneAssetPath).existsSync() &&
              File(stage.battlefieldAssetPath).existsSync(),
        ),
        isTrue,
      );
      expect(earlyStages.take(4).map((stage) => stage.bossId), [
        'random_guaishou',
        'random_guaishou',
        'random_guaishou',
        'random_guaishou'
      ]);
      expect(earlyStages.last.bossId, 'guaishou_cyber_crocodile_boss');
      expect(earlyStages.last.bossName, 'Cyber Crocodile');
      expect(
        File(
          'assets/game/grass_game/images/guaishou/'
          'guaishou_cyber_crocodile_boss_walk_8dir_sheet.png',
        ).existsSync(),
        isTrue,
      );
    });

    test('chapter finale stages use themed boss sprites', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      const expectedBossIds = {
        1: 'guaishou_cyber_crocodile_boss',
        2: 'guaishou_highway_juggernaut_boss',
        3: 'guaishou_city_core_guardian_boss',
        4: 'guaishou_cave_crystal_brute_boss',
        5: 'guaishou_forest_spore_titan_boss',
        6: 'guaishou_ocean_shell_leviathan_boss',
        7: 'guaishou_infected_plague_beetle_boss',
        8: 'guaishou_bone_wasteland_reaper_boss',
        9: 'guaishou_alien_landing_overlord_boss',
        10: 'guaishou_cosmic_rift_dragon_boss',
      };

      for (final entry in expectedBossIds.entries) {
        final chapterStages = controller.stagesForChapter(entry.key);
        final finale = chapterStages.reduce(
          (value, element) => value.stage > element.stage ? value : element,
        );
        expect(finale.bossId, entry.value);
        expect(
          File(
            'assets/game/grass_game/images/guaishou/'
            '${entry.value}_walk_8dir_sheet.png',
          ).existsSync(),
          isTrue,
        );
      }
    });

    test('hero characters expose balance stats and assets', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      final expected = <String, (String, int, double, double)>{
        'runner': ('Male', 130, 1.0, 1.0),
        'guard': ('Female', 105, 1.125, 0.95),
        'aotuman': ('凹凸曼', 220, 1.125, 1.05),
        'aomeijia': ('奥美家', 170, 1.25, 0.96),
        'jingangman': ('金刚曼', 320, 1.0, 1.18),
        'beliya': ('贝利牙', 260, 1.125, 1.12),
        'sevengar': ('赛文加', 430, 0.75, 1.28),
      };

      for (final entry in expected.entries) {
        final character = controller.characters.firstWhere(
          (item) => item.id == entry.key,
        );
        expect(character.name, entry.value.$1);
        expect(character.baseHp, entry.value.$2);
        expect(character.baseSpeedMultiplier, closeTo(entry.value.$3, 0.001));
        expect(character.baseAttackMultiplier, closeTo(entry.value.$4, 0.001));
        expect(character.isOwned, isTrue);
        expect(File(character.avatarAssetPath).existsSync(), isTrue);
        expect(File(character.walkPreviewAssetPath).existsSync(), isTrue);
        expect(File(character.gameSpriteSheetAssetPath).existsSync(), isTrue);
      }
    });

    test('hero walk sheets use 8 direction 6 frame fixed grid', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      for (final character in controller.characters) {
        final bytes = await rootBundle.load(character.gameSpriteSheetAssetPath);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        addTearDown(frame.image.dispose);

        expect(
          frame.image.width,
          768,
          reason: '${character.id} must be 6 columns x 128px',
        );
        expect(
          frame.image.height,
          1024,
          reason: '${character.id} must be 8 rows x 128px',
        );
        expect(
          await _maxHorizontalFrameCenterDrift(frame.image),
          lessThanOrEqualTo(2),
          reason: '${character.id} walk frames must stay centered in each cell',
        );
        expect(
          await _whitePixelRatio(frame.image),
          lessThanOrEqualTo(0.035),
          reason:
              '${character.id} walk sheet must not keep white background noise',
        );
      }
    });

    test('skill effect sheets use transparent padded fixed grids', () async {
      const effects = {
        'assets/game/grass_game/images/effects/skill_fire_flame_sheet.png': (
          6,
          6
        ),
        'assets/game/grass_game/images/effects/skill_ice_crystal_sheet.png': (
          6,
          5
        ),
        'assets/game/grass_game/images/effects/'
            'skill_thunder_lightning_sheet.png': (6, 5),
        'assets/game/grass_game/images/effects/skill_poison_spore_sheet.png': (
          6,
          5
        ),
        'assets/game/grass_game/images/effects/'
            'skill_void_black_hole_sheet.png': (6, 5),
        'assets/game/grass_game/images/effects/skill_orbit_blade_sheet.png': (
          8,
          1
        ),
        'assets/game/grass_game/images/effects/skill_ultimate_beam_sheet.png': (
          8,
          1
        ),
      };

      for (final entry in effects.entries) {
        final bytes = await rootBundle.load(entry.key);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        addTearDown(frame.image.dispose);

        final columns = entry.value.$1;
        final rows = entry.value.$2;
        expect(frame.image.width % columns, 0, reason: entry.key);
        expect(frame.image.height % rows, 0, reason: entry.key);
        expect(
          await _fixedGridFrameEdgesAreTransparent(
            frame.image,
            columns: columns,
            rows: rows,
          ),
          isTrue,
          reason: '$entry must keep transparent padding around each frame',
        );
      }
    });

    test('themed boss walk sheets use transparent 8 direction grids', () async {
      const bossIds = [
        'guaishou_cyber_crocodile_boss',
        'guaishou_highway_juggernaut_boss',
        'guaishou_city_core_guardian_boss',
        'guaishou_cave_crystal_brute_boss',
        'guaishou_forest_spore_titan_boss',
        'guaishou_ocean_shell_leviathan_boss',
        'guaishou_infected_plague_beetle_boss',
        'guaishou_bone_wasteland_reaper_boss',
        'guaishou_alien_landing_overlord_boss',
        'guaishou_cosmic_rift_dragon_boss',
      ];

      for (final bossId in bossIds) {
        final assetPath =
            'assets/game/grass_game/images/guaishou/${bossId}_walk_8dir_sheet.png';
        final bytes = await rootBundle.load(assetPath);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        addTearDown(frame.image.dispose);

        expect(frame.image.width, 768, reason: bossId);
        expect(frame.image.height, 1024, reason: bossId);
        expect(
          await _maxHorizontalFrameCenterDrift(frame.image),
          lessThanOrEqualTo(2),
          reason: '$bossId walk frames must stay centered in each cell',
        );
        expect(
          await _fixedGridFrameEdgesAreTransparent(
            frame.image,
            columns: 6,
            rows: 8,
          ),
          isTrue,
          reason: '$bossId must keep transparent cell edges',
        );
      }
    });

    test('weapon catalog follows craft-focused survivor design', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      expect(controller.weapons, hasLength(18));
      expect(controller.selectedWeaponId, 'wooden_stick');
      expect(controller.selectedWeapon.attackPattern,
          WeaponAttackPattern.meleeSweep);
      expect(
        controller.weapons.where((weapon) => weapon.recipe != null),
        hasLength(7),
      );
      expect(
        controller.weapons.map((weapon) => weapon.id),
        containsAll([
          'wooden_stick',
          'bounce_ball',
          'scatter_blunder',
          'mini_grenade',
          'storm_hammer',
          'star_core_cannon',
        ]),
      );
    });

    test('deathmatch stage is always selectable with guaishou pool', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      final deathmatch = controller.stages.firstWhere(
        (stage) => stage.id == 'deathmatch',
      );

      expect(deathmatch.isDeathmatch, isTrue);
      expect(deathmatch.chapter, 11);
      expect(deathmatch.enemyTypes.length, 12);
      expect(deathmatch.enemyTypes.every((id) => id.startsWith('guaishou_')),
          isTrue);
      expect(controller.canSelectStage(deathmatch.id), isTrue);
      expect(controller.selectStage(deathmatch.id), isTrue);
      expect(controller.currentLoadout.stage.isDeathmatch, isTrue);

      for (final id in deathmatch.enemyTypes) {
        final walkSheet = File(
          'assets/game/grass_game/images/guaishou/${id}_walk_8dir_sheet.webp',
        );
        expect(walkSheet.existsSync(), isTrue);
      }
    });

    test('campaign next stage never advances into deathmatch', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      final campaignStages =
          controller.stages.where((stage) => !stage.isDeathmatch).toList();
      expect(campaignStages, isNotEmpty);

      for (final stage in campaignStages) {
        expect(controller.selectStage(stage.id), isTrue);
        controller.applyBattleResult(
          const GameResult(
            survivalSeconds: 300,
            killCount: 100,
            level: 8,
            isWin: true,
            coinsEarned: 25,
            characterExpEarned: 80,
          ),
        );
      }

      expect(controller.selectedStage.isDeathmatch, isFalse);
      expect(controller.nextStageId, isNull);
      expect(controller.hasNextStage, isFalse);
      expect(controller.selectNextStage(), isFalse);
      expect(controller.selectedStage.isDeathmatch, isFalse);
      expect(
        controller
            .canSelectStage(GrassGameProgressController.deathmatchStageId),
        isTrue,
      );
    });

    test('all configured weapon attack patterns are supported by runtime',
        () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      final configuredPatterns =
          controller.weapons.map((weapon) => weapon.attackPattern.name).toSet();

      expect(
        configuredPatterns
            .difference(GrassSurvivorGame.supportedWeaponAttackPatterns),
        isEmpty,
      );
    });
  });
}

Future<double> _maxHorizontalFrameCenterDrift(ui.Image image) async {
  const cellSize = 128;
  const columns = 6;
  const rows = 8;
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (bytes == null) {
    return double.infinity;
  }

  var maxDrift = 0.0;
  for (var row = 0; row < rows; row++) {
    final centers = <double>[];
    for (var column = 0; column < columns; column++) {
      var minX = cellSize;
      var maxX = -1;
      for (var y = row * cellSize; y < (row + 1) * cellSize; y++) {
        for (var x = column * cellSize; x < (column + 1) * cellSize; x++) {
          final offset = (y * image.width + x) * 4;
          final alpha = bytes.getUint8(offset + 3);
          if (alpha <= 16) {
            continue;
          }
          final localX = x - column * cellSize;
          if (localX < minX) {
            minX = localX;
          }
          if (localX > maxX) {
            maxX = localX;
          }
        }
      }
      if (maxX >= 0) {
        centers.add((minX + maxX) / 2);
      }
    }
    if (centers.isEmpty) {
      continue;
    }
    centers.sort();
    final drift = centers.last - centers.first;
    if (drift > maxDrift) {
      maxDrift = drift;
    }
  }
  return maxDrift;
}

Future<bool> _fixedGridFrameEdgesAreTransparent(
  ui.Image image, {
  required int columns,
  required int rows,
}) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (bytes == null) {
    return false;
  }
  final cellWidth = image.width ~/ columns;
  final cellHeight = image.height ~/ rows;

  for (var row = 0; row < rows; row++) {
    for (var column = 0; column < columns; column++) {
      final left = column * cellWidth;
      final right = (column + 1) * cellWidth - 1;
      final top = row * cellHeight;
      final bottom = (row + 1) * cellHeight - 1;
      for (var x = left; x <= right; x++) {
        if (_alphaAt(bytes, image.width, x, top) > 0 ||
            _alphaAt(bytes, image.width, x, bottom) > 0) {
          return false;
        }
      }
      for (var y = top + 1; y < bottom; y++) {
        if (_alphaAt(bytes, image.width, left, y) > 0 ||
            _alphaAt(bytes, image.width, right, y) > 0) {
          return false;
        }
      }
    }
  }
  return true;
}

int _alphaAt(ByteData bytes, int imageWidth, int x, int y) {
  return bytes.getUint8((y * imageWidth + x) * 4 + 3);
}

Future<double> _whitePixelRatio(ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (bytes == null) {
    return 1;
  }

  var visiblePixels = 0;
  var whitePixels = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final offset = (y * image.width + x) * 4;
      final red = bytes.getUint8(offset);
      final green = bytes.getUint8(offset + 1);
      final blue = bytes.getUint8(offset + 2);
      final alpha = bytes.getUint8(offset + 3);
      if (alpha <= 8) {
        continue;
      }
      visiblePixels++;
      if (red > 235 && green > 235 && blue > 235) {
        whitePixels++;
      }
    }
  }
  if (visiblePixels == 0) {
    return 1;
  }
  return whitePixels / visiblePixels;
}
