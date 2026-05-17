import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
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
