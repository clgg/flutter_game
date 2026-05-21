import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grass_game_domain/grass_game_domain.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';
import 'package:grass_game_ui/grass_game_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
    });

    test('hero characters expose balance stats and assets', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = GrassGameProgressController.defaults();
      await controller.loadSavedProgress();

      final expected = <String, (String, int, double, double)>{
        'runner': ('Male', 130, 1.0, 1.0),
        'guard': ('Female', 105, 1.125, 0.95),
        'scout': ('Robot', 150, 0.875, 1.08),
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
          'assets/game/grass_game/images/guaishou/${id}_walk_8dir_sheet.png',
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
