import 'dart:ui' as ui;

import 'package:flame/components.dart';

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

  ui.Image expIconFor(int exp) {
    if (exp >= 5) {
      return expHigh;
    }
    if (exp >= 3) {
      return expMid;
    }
    return expLow;
  }

  ui.Image coinIconFor(int coins) {
    if (coins >= 8) {
      return coinLarge;
    }
    if (coins >= 4) {
      return coinMedium;
    }
    return coinSmall;
  }
}

class ExpGemComponent extends CircleComponent {
  ExpGemComponent({
    required this.exp,
    required this.coins,
    required this.icons,
    required Vector2 position,
  }) : super(
          radius: 10,
          anchor: Anchor.center,
          position: position,
        );

  final int exp;
  final int coins;
  final DropIconSet icons;
  bool isAttracted = false;

  void moveToward(Vector2 target, double dt) {
    final direction = target - position;
    if (direction.length2 == 0) {
      return;
    }
    direction.normalize();
    position += direction * (isAttracted ? 260 : 120) * dt;
  }

  @override
  void render(ui.Canvas canvas) {
    final glowPaint = ui.Paint()
      ..color =
          exp > 0 ? const ui.Color(0x338FE388) : const ui.Color(0x33FFD36E);
    canvas.drawCircle(
      ui.Offset.zero,
      radius + 5,
      glowPaint,
    );
    const iconSize = 14.0;
    if (exp > 0) {
      _drawImage(
        canvas,
        icons.expIconFor(exp),
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
        icons.coinIconFor(coins),
        ui.Rect.fromCenter(
          center: ui.Offset.zero,
          width: iconSize,
          height: iconSize,
        ),
      );
    }
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
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
  }
}
