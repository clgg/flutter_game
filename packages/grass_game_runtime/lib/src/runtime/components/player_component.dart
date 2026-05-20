import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame/components.dart';

import '../game/grass_game_runtime_controller.dart';

enum PlayerFacing {
  front,
  frontRight,
  right,
  backRight,
  back,
  backLeft,
  left,
  frontLeft,
}

class PlayerAnimationSet {
  PlayerAnimationSet({
    required ui.Image image,
    required this.displaySize,
  })  : _image = image,
        _columns = math.max(1, (image.width / _cellSize).round()),
        _rowCount = (image.height / _cellSize).round(),
        _frameSize = Vector2.all(_cellSize);

  static const double _cellSize = 128;

  final ui.Image _image;
  final int _columns;
  final int _rowCount;
  final Vector2 _frameSize;
  final Vector2 displaySize;

  Map<PlayerFacing, SpriteAnimation> createWalkAnimations() {
    if (_rowCount >= 8) {
      return {
        PlayerFacing.front: _createWalkAnimation(0),
        PlayerFacing.frontRight: _createWalkAnimation(1),
        PlayerFacing.right: _createWalkAnimation(2),
        PlayerFacing.backRight: _createWalkAnimation(3),
        PlayerFacing.back: _createWalkAnimation(4),
        PlayerFacing.backLeft: _createWalkAnimation(5),
        PlayerFacing.left: _createWalkAnimation(6),
        PlayerFacing.frontLeft: _createWalkAnimation(7),
      };
    }
    return {
      PlayerFacing.front: _createWalkAnimation(0),
      PlayerFacing.back: _createWalkAnimation(1),
      PlayerFacing.left: _createWalkAnimation(2),
      PlayerFacing.right: _createWalkAnimation(3),
      PlayerFacing.frontRight: _createWalkAnimation(3),
      PlayerFacing.backRight: _createWalkAnimation(3),
      PlayerFacing.backLeft: _createWalkAnimation(2),
      PlayerFacing.frontLeft: _createWalkAnimation(2),
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
  final ui.Paint _hpBackPaint = ui.Paint()..color = const ui.Color(0x99000000);
  final ui.Paint _hpFillPaint = ui.Paint()..color = const ui.Color(0xFFFF5B6F);
  final ui.Paint _hpBorderPaint = ui.Paint()
    ..color = const ui.Color(0xDDE8FFF2)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1;
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
    final nextFacing = _facingForDirection(direction);
    if (nextFacing == _facing) {
      return;
    }
    _facing = nextFacing;
    final nextAnimation = _animations?[nextFacing];
    if (nextAnimation != null) {
      animation = nextAnimation;
    }
  }

  PlayerFacing _facingForDirection(Vector2 direction) {
    final angle = math.atan2(direction.y, direction.x);
    final sector = ((angle + math.pi / 8) / (math.pi / 4)).floor() & 7;
    return switch (sector) {
      0 => PlayerFacing.right,
      1 => PlayerFacing.frontRight,
      2 => PlayerFacing.front,
      3 => PlayerFacing.frontLeft,
      4 => PlayerFacing.left,
      5 => PlayerFacing.backLeft,
      6 => PlayerFacing.back,
      _ => PlayerFacing.backRight,
    };
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

  int heal(int value) {
    if (value <= 0 || hp >= maxHp) {
      return 0;
    }
    final previousHp = hp;
    hp = (hp + value).clamp(0, maxHp);
    return hp - previousHp;
  }

  bool get isDead => hp <= 0;

  @override
  void render(ui.Canvas canvas) {
    if (animation == null) {
      canvas.drawCircle(ui.Offset.zero, collisionRadius, _fallbackPaint);
      canvas.drawCircle(ui.Offset.zero, collisionRadius, _outlinePaint);
      _drawHealthBar(canvas);
      return;
    }
    super.render(canvas);
    _drawHealthBar(canvas);
  }

  void _drawHealthBar(ui.Canvas canvas) {
    final hpRatio = maxHp == 0 ? 0.0 : (hp / maxHp).clamp(0, 1).toDouble();
    final barWidth = size.x * 0.72;
    const barHeight = 5.0;
    const top = -10.0;
    final left = (size.x - barWidth) / 2;
    final backRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(left, top, barWidth, barHeight),
      const ui.Radius.circular(999),
    );
    final fillRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(left, top, barWidth * hpRatio, barHeight),
      const ui.Radius.circular(999),
    );
    canvas
      ..drawRRect(backRect, _hpBackPaint)
      ..drawRRect(fillRect, _hpFillPaint)
      ..drawRRect(backRect, _hpBorderPaint);
  }
}
