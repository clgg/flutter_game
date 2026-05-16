import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame/components.dart';

import '../game/grass_game_runtime_controller.dart';

enum PlayerFacing {
  front,
  back,
  left,
  right,
}

class PlayerAnimationSet {
  PlayerAnimationSet({
    required ui.Image image,
    required this.displaySize,
  })  : _image = image,
        _frameSize = Vector2(
          image.width / _columns,
          image.height / _rows,
        );

  static const int _columns = 6;
  static const int _rows = 4;

  final ui.Image _image;
  final Vector2 _frameSize;
  final Vector2 displaySize;

  Map<PlayerFacing, SpriteAnimation> createWalkAnimations() {
    return {
      PlayerFacing.front: _createWalkAnimation(0),
      PlayerFacing.back: _createWalkAnimation(1),
      PlayerFacing.left: _createWalkAnimation(2),
      PlayerFacing.right: _createWalkAnimation(3),
    };
  }

  SpriteAnimation _createWalkAnimation(int row) {
    return SpriteAnimation.fromFrameData(
      _image,
      SpriteAnimationData.sequenced(
        amount: _columns,
        stepTime: 0.1,
        textureSize: _frameSize,
        texturePosition: Vector2(0, _frameSize.y * row),
      ),
    );
  }
}

class PlayerComponent extends SpriteAnimationComponent {
  PlayerComponent({
    required this.controller,
    required this.moveSpeed,
    required this.maxHp,
    required PlayerAnimationSet? animationSet,
  })  : _animations = animationSet?.createWalkAnimations(),
        super(
          anchor: Anchor.center,
          playing: false,
          size: animationSet?.displaySize ?? Vector2.all(38),
        ) {
    animation = _animations?[PlayerFacing.front];
  }

  final GrassGameRuntimeController controller;
  double moveSpeed;
  final int maxHp;
  late int hp = maxHp;
  double pickupRange = 90;
  double get collisionRadius => math.min(size.x, size.y) * 0.28;
  final Map<PlayerFacing, SpriteAnimation>? _animations;
  final ui.Paint _fallbackPaint = ui.Paint()
    ..color = const ui.Color(0xFF49D17D);
  final ui.Paint _outlinePaint = ui.Paint()
    ..color = const ui.Color(0xFFE8FFF2)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 3;
  double _hitCooldown = 0;
  bool _hasInitialPosition = false;
  bool _isMoving = false;
  PlayerFacing _facing = PlayerFacing.front;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_hasInitialPosition) {
      position = Vector2.zero();
      _hasInitialPosition = true;
    }
  }

  @override
  void update(double dt) {
    final moveDirection = controller.moveDirection;
    final isMoving = !moveDirection.isZero();
    if (isMoving) {
      _setFacing(moveDirection);
      playing = true;
      _isMoving = true;
    } else if (_isMoving || playing) {
      animationTicker?.reset();
      playing = false;
      _isMoving = false;
    }

    super.update(dt);
    if (_hitCooldown > 0) {
      _hitCooldown -= dt;
    }
    if (!isMoving) {
      return;
    }

    position += moveDirection * moveSpeed * dt;
  }

  void _setFacing(Vector2 direction) {
    final nextFacing = direction.x.abs() > direction.y.abs()
        ? direction.x > 0
            ? PlayerFacing.right
            : PlayerFacing.left
        : direction.y > 0
            ? PlayerFacing.front
            : PlayerFacing.back;
    if (nextFacing == _facing) {
      return;
    }
    _facing = nextFacing;
    final nextAnimation = _animations?[nextFacing];
    if (nextAnimation != null) {
      animation = nextAnimation;
    }
  }

  void faceToward(Vector2 target) {
    if (!controller.moveDirection.isZero()) {
      return;
    }
    final direction = target - position;
    if (direction.length2 == 0) {
      return;
    }
    _setFacing(direction);
    animationTicker?.reset();
    playing = false;
  }

  bool takeDamage(int value) {
    if (_hitCooldown > 0) {
      return false;
    }
    hp = (hp - value).clamp(0, maxHp);
    _hitCooldown = 0.5;
    return true;
  }

  bool get isDead => hp <= 0;

  @override
  void render(ui.Canvas canvas) {
    if (animation == null) {
      canvas.drawCircle(ui.Offset.zero, collisionRadius, _fallbackPaint);
      canvas.drawCircle(ui.Offset.zero, collisionRadius, _outlinePaint);
      return;
    }
    super.render(canvas);
  }
}
