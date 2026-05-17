import 'dart:ui' as ui;

import 'package:flame/components.dart';

enum DropVisualTier {
  normal,
  high,
  rare,
}

class DropIconSet {
  const DropIconSet({
    required this.expLow,
    required this.expMid,
    required this.expHigh,
    required this.coinSmall,
    required this.coinMedium,
    required this.coinLarge,
  });

  final ui.Image expLow;
  final ui.Image expMid;
  final ui.Image expHigh;
  final ui.Image coinSmall;
  final ui.Image coinMedium;
  final ui.Image coinLarge;

  ui.Image expIconFor(DropVisualTier tier) {
    return switch (tier) {
      DropVisualTier.normal => expLow,
      DropVisualTier.high => expMid,
      DropVisualTier.rare => expHigh,
    };
  }

  ui.Image coinIconFor(DropVisualTier tier) {
    return switch (tier) {
      DropVisualTier.normal => coinSmall,
      DropVisualTier.high => coinMedium,
      DropVisualTier.rare => coinLarge,
    };
  }
}

class ExpGemComponent extends CircleComponent {
  ExpGemComponent({
    required this.exp,
    required this.coins,
    required this.icons,
    required Vector2 position,
    this.expTier = DropVisualTier.normal,
    this.coinTier = DropVisualTier.normal,
  })  : rareExpChargeUnits = exp > 0 && expTier == DropVisualTier.rare ? 1 : 0,
        super(
          radius: 8,
          anchor: Anchor.center,
          position: position,
        );

  int exp;
  int coins;
  final DropIconSet icons;
  DropVisualTier expTier;
  DropVisualTier coinTier;
  int rareExpChargeUnits;
  bool isAttracted = false;
  double _age = 0;

  static final ui.Paint _expTrailPaint = ui.Paint()
    ..color = const ui.Color(0x668FE388)
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeWidth = 3;
  static final ui.Paint _coinTrailPaint = ui.Paint()
    ..color = const ui.Color(0x66FFD36E)
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeWidth = 3;
  static final ui.Paint _imagePaint = ui.Paint()
    ..filterQuality = ui.FilterQuality.low;

  double get age => _age;

  bool get isRare {
    return exp > 0
        ? expTier == DropVisualTier.rare
        : coinTier == DropVisualTier.rare;
  }

  bool get isExpDrop => exp > 0;

  void absorb({
    required int addedExp,
    required int addedCoins,
    required DropVisualTier addedExpTier,
    required DropVisualTier addedCoinTier,
  }) {
    exp += addedExp;
    coins += addedCoins;
    if (addedExp > 0 && addedExpTier == DropVisualTier.rare) {
      rareExpChargeUnits++;
    }
    expTier = _maxTier(expTier, addedExpTier);
    coinTier = _maxTier(coinTier, addedCoinTier);
    radius = _visualRadius;
  }

  void moveToward(Vector2 target, double dt) {
    final direction = target - position;
    if (direction.length2 == 0) {
      return;
    }
    direction.normalize();
    position += direction * (isAttracted ? 260 : 120) * dt;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
  }

  @override
  void render(ui.Canvas canvas) {
    final tier = exp > 0 ? expTier : coinTier;
    final tierScale = switch (tier) {
      DropVisualTier.normal => 1.0,
      DropVisualTier.high => 1.16,
      DropVisualTier.rare => 1.34,
    };
    canvas.save();
    if (isAttracted) {
      final trailPaint = exp > 0 ? _expTrailPaint : _coinTrailPaint;
      canvas.drawLine(
          const ui.Offset(0, 8), const ui.Offset(0, 18), trailPaint);
    }
    final iconSize = 10.0 * tierScale;
    if (exp > 0) {
      _drawImage(
        canvas,
        icons.expIconFor(expTier),
        ui.Rect.fromCenter(
          center: ui.Offset.zero,
          width: iconSize,
          height: iconSize,
        ),
      );
    }
    if (coins > 0) {
      _drawImage(
        canvas,
        icons.coinIconFor(coinTier),
        ui.Rect.fromCenter(
          center: ui.Offset.zero,
          width: iconSize,
          height: iconSize,
        ),
      );
    }
    canvas.restore();
  }

  void _drawImage(ui.Canvas canvas, ui.Image image, ui.Rect dst) {
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      dst,
      _imagePaint,
    );
  }

  double get _visualRadius {
    final tier = exp > 0 ? expTier : coinTier;
    return switch (tier) {
      DropVisualTier.normal => 8,
      DropVisualTier.high => 10,
      DropVisualTier.rare => 12,
    };
  }

  DropVisualTier _maxTier(DropVisualTier first, DropVisualTier second) {
    return first.index >= second.index ? first : second;
  }
}
