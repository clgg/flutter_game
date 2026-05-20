import 'dart:ui' as ui;

import 'package:flame/components.dart';

enum DropVisualTier {
  normal,
  high,
  rare,
}

enum DropPayloadKind {
  exp,
  coin,
  health,
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
    this.healing = 0,
    this.expTier = DropVisualTier.normal,
    this.coinTier = DropVisualTier.normal,
  })  : rareExpChargeUnits = exp > 0 && expTier == DropVisualTier.rare ? 1 : 0,
        super(
          radius: 6,
          anchor: Anchor.center,
          position: position,
        );

  int exp;
  int coins;
  int healing;
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
  static final ui.Paint _healthTrailPaint = ui.Paint()
    ..color = const ui.Color(0x66FF6B7E)
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeWidth = 3;
  static final ui.Paint _healthPackPaint = ui.Paint()
    ..color = const ui.Color(0xFFE84855);
  static final ui.Paint _healthPackShadePaint = ui.Paint()
    ..color = const ui.Color(0xFFB62D3D);
  static final ui.Paint _healthCrossPaint = ui.Paint()
    ..color = const ui.Color(0xFFFFFFFF);
  static final ui.Paint _imagePaint = ui.Paint()
    ..filterQuality = ui.FilterQuality.low;

  double get age => _age;

  bool get isRare {
    return switch (payloadKind) {
      DropPayloadKind.exp => expTier == DropVisualTier.rare,
      DropPayloadKind.coin => coinTier == DropVisualTier.rare,
      DropPayloadKind.health => false,
    };
  }

  bool get isExpDrop => payloadKind == DropPayloadKind.exp;

  bool get isHealthDrop => payloadKind == DropPayloadKind.health;

  DropPayloadKind get payloadKind {
    if (exp > 0) {
      return DropPayloadKind.exp;
    }
    if (coins > 0) {
      return DropPayloadKind.coin;
    }
    return DropPayloadKind.health;
  }

  void absorb({
    required int addedExp,
    required int addedCoins,
    required DropVisualTier addedExpTier,
    required DropVisualTier addedCoinTier,
    int addedHealing = 0,
  }) {
    exp += addedExp;
    coins += addedCoins;
    healing += addedHealing;
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
    final tier = payloadKind == DropPayloadKind.exp ? expTier : coinTier;
    final tierScale = switch (tier) {
      DropVisualTier.normal => 1.0,
      DropVisualTier.high => 1.16,
      DropVisualTier.rare => 1.34,
    };
    canvas.save();
    if (isAttracted) {
      final trailPaint = switch (payloadKind) {
        DropPayloadKind.exp => _expTrailPaint,
        DropPayloadKind.coin => _coinTrailPaint,
        DropPayloadKind.health => _healthTrailPaint,
      };
      canvas.drawLine(
          const ui.Offset(0, 8), const ui.Offset(0, 18), trailPaint);
    }
    final iconSize = 10.0 * tierScale;
    if (payloadKind == DropPayloadKind.exp) {
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
    if (payloadKind == DropPayloadKind.coin) {
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
    if (payloadKind == DropPayloadKind.health) {
      _drawHealthPack(canvas);
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

  void _drawHealthPack(ui.Canvas canvas) {
    const size = 14.0;
    final packRect = ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(-size / 2, -size / 2, size, size),
      const ui.Radius.circular(3),
    );
    final shadeRect = ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(-size / 2, 1, size, size / 2 - 1),
      const ui.Radius.circular(3),
    );
    canvas
      ..drawRRect(packRect, _healthPackPaint)
      ..drawRRect(shadeRect, _healthPackShadePaint)
      ..drawRect(const ui.Rect.fromLTWH(-2, -5, 4, 10), _healthCrossPaint)
      ..drawRect(const ui.Rect.fromLTWH(-5, -2, 10, 4), _healthCrossPaint);
  }

  double get _visualRadius {
    if (payloadKind == DropPayloadKind.health) {
      return 9;
    }
    final tier = payloadKind == DropPayloadKind.exp ? expTier : coinTier;
    return switch (tier) {
      DropVisualTier.normal => 6,
      DropVisualTier.high => 7.5,
      DropVisualTier.rare => 9,
    };
  }

  DropVisualTier _maxTier(DropVisualTier first, DropVisualTier second) {
    return first.index >= second.index ? first : second;
  }
}
