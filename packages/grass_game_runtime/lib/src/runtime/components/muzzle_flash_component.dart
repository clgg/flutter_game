import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame/components.dart';

class MuzzleFlashComponent extends SpriteComponent {
  MuzzleFlashComponent({
    required ui.Image image,
    required Vector2 position,
    required Vector2 direction,
  }) : super(
          sprite: Sprite(image),
          anchor: Anchor.center,
          position: position,
          size: Vector2.all(42),
          angle: math.atan2(direction.y, direction.x),
        );

  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= 0.08) {
      removeFromParent();
    }
  }
}
