import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grass_game_domain/grass_game_domain.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';

void main() {
  test('rare exp drops carry one charged ultimate unit', () async {
    final icons = await _testIcons();

    final rareDrop = ExpGemComponent(
      exp: 12,
      coins: 0,
      icons: icons,
      expTier: DropVisualTier.rare,
      position: Vector2.zero(),
    );
    final normalDrop = ExpGemComponent(
      exp: 2,
      coins: 0,
      icons: icons,
      position: Vector2.zero(),
    );

    expect(rareDrop.rareExpChargeUnits, 1);
    expect(normalDrop.rareExpChargeUnits, 0);

    normalDrop.absorb(
      addedExp: 8,
      addedCoins: 0,
      addedExpTier: DropVisualTier.rare,
      addedCoinTier: DropVisualTier.normal,
    );

    expect(normalDrop.rareExpChargeUnits, 1);
  });

  test('health drops keep separate payload and can merge healing', () async {
    final icons = await _testIcons();

    final healthDrop = ExpGemComponent(
      exp: 0,
      coins: 0,
      healing: 50,
      icons: icons,
      position: Vector2.zero(),
    );

    expect(healthDrop.payloadKind, DropPayloadKind.health);
    expect(healthDrop.isHealthDrop, isTrue);
    expect(healthDrop.isExpDrop, isFalse);
    expect(healthDrop.isRare, isFalse);

    healthDrop.absorb(
      addedExp: 0,
      addedCoins: 0,
      addedHealing: 50,
      addedExpTier: DropVisualTier.normal,
      addedCoinTier: DropVisualTier.normal,
    );

    expect(healthDrop.healing, 100);
    expect(healthDrop.payloadKind, DropPayloadKind.health);
  });

  test('player healing clamps at max hp', () {
    final player = PlayerComponent(
      controller: GrassGameRuntimeController(),
      moveSpeed: 0,
      maxHp: 100,
      animationSet: null,
    );

    expect(player.takeDamage(80), isTrue);
    expect(player.hp, 20);
    expect(player.heal(50), 50);
    expect(player.hp, 70);
    expect(player.heal(50), 30);
    expect(player.hp, 100);
    expect(player.heal(50), 0);
    expect(player.hp, 100);
  });

  test('game keeps selected character id for charged ultimate variants', () {
    final game = GrassSurvivorGame(
      config: GrassGameConfig.defaults,
      controller: GrassGameRuntimeController(),
      playerCharacterId: 'beliya',
    );

    expect(game.playerCharacterId, 'beliya');
  });

  test('enemy switches to attack animation and returns to walk', () async {
    final animationSet = EnemyAnimationSet(
      image: await _testSpriteSheetImage(),
      displaySize: Vector2.all(32),
    );
    final enemy = EnemyComponent(
      enemyId: 'guaishou_feral_hound',
      maxHp: 10,
      moveSpeed: 0,
      expDrop: 0,
      position: Vector2.zero(),
      animationSet: animationSet,
    );

    expect(enemy.isAttackAnimationActive, isFalse);
    enemy.triggerAttackAnimation();
    expect(enemy.isAttackAnimationActive, isTrue);

    enemy.update(0.4);
    expect(enemy.isAttackAnimationActive, isFalse);
  });
}

Future<DropIconSet> _testIcons() async {
  final image = await _testImage();
  return DropIconSet(
    expLow: image,
    expMid: image,
    expHigh: image,
    coinSmall: image,
    coinMedium: image,
    coinLarge: image,
  );
}

Future<ui.Image> _testImage() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 1, 1),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  return recorder.endRecording().toImage(1, 1);
}

Future<ui.Image> _testSpriteSheetImage() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  for (var row = 0; row < 8; row++) {
    for (var column = 0; column < 6; column++) {
      canvas.drawRect(
        ui.Rect.fromLTWH(column.toDouble(), row.toDouble(), 1, 1),
        ui.Paint()
          ..color = ui.Color.fromARGB(
            255,
            32 + row * 20,
            48 + column * 20,
            120,
          ),
      );
    }
  }
  return recorder.endRecording().toImage(6, 8);
}
