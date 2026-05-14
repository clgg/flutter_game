import 'dart:ui';

import 'package:flame/components.dart';

import '../game/grass_game_runtime_controller.dart';

class PlayerComponent extends CircleComponent {
  PlayerComponent({
    required this.controller,
    required this.moveSpeed,
  }) : super(
          radius: 18,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFF49D17D),
        );

  final GrassGameRuntimeController controller;
  final double moveSpeed;
  final Paint _outlinePaint = Paint()
    ..color = const Color(0xFFE8FFF2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  Vector2 _gameSize = Vector2.zero();
  bool _hasInitialPosition = false;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _gameSize = size;
    if (!_hasInitialPosition && size.x > 0 && size.y > 0) {
      position = size / 2;
      _hasInitialPosition = true;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (controller.moveDirection.isZero()) {
      return;
    }

    position += controller.moveDirection * moveSpeed * dt;
    if (_gameSize.x <= 0 || _gameSize.y <= 0) {
      return;
    }

    position
      ..x = position.x.clamp(radius, _gameSize.x - radius).toDouble()
      ..y = position.y.clamp(radius, _gameSize.y - radius).toDouble();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset.zero, radius, _outlinePaint);
  }
}
