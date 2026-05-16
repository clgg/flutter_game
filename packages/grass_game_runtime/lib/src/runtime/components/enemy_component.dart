import 'dart:ui' as ui;

import 'package:flame/components.dart';

enum EnemyFacing {
  front,
  back,
  left,
  right,
}

class EnemyAnimationSet {
  EnemyAnimationSet({
    required ui.Image image,
    required this.displaySize,
  })  : _image = image,
        _frameSize = Vector2(
          image.width / _columns,
          image.height / _rows,
        );

  static const int _columns = 6;
  static const int _walkFrames = 4;
  static const int _rows = 8;
  static const int _walkRowOffset = 4;

  final ui.Image _image;
  final Vector2 _frameSize;
  final Vector2 displaySize;

  Map<EnemyFacing, SpriteAnimation> createWalkAnimations() {
    return {
      EnemyFacing.front: _createWalkAnimation(0),
      EnemyFacing.back: _createWalkAnimation(1),
      EnemyFacing.left: _createWalkAnimation(2),
      EnemyFacing.right: _createWalkAnimation(3),
    };
  }

  SpriteAnimation _createWalkAnimation(int directionRow) {
    return SpriteAnimation.fromFrameData(
      _image,
      SpriteAnimationData.sequenced(
        amount: _walkFrames,
        stepTime: 0.12,
        textureSize: _frameSize,
        texturePosition:
            Vector2(0, _frameSize.y * (_walkRowOffset + directionRow)),
      ),
    );
  }
}

class EnemyComponent extends SpriteAnimationComponent {
  EnemyComponent({
    required this.enemyId,
    required this.maxHp,
    required this.moveSpeed,
    required this.expDrop,
    required Vector2 position,
    EnemyAnimationSet? animationSet,
  })  : hp = maxHp,
        collisionRadius = enemyId == 'boss'
            ? 34
            : enemyId == 'tank'
                ? 20
                : 14,
        _fallbackPaint = ui.Paint()..color = _colorFor(enemyId),
        _animations = animationSet?.createWalkAnimations(),
        super(
          anchor: Anchor.center,
          position: position,
          size: animationSet?.displaySize ??
              Vector2.all(enemyId == 'boss'
                  ? 82
                  : enemyId == 'tank'
                      ? 44
                      : 34),
        ) {
    animation = _animations?[EnemyFacing.front];
  }

  final String enemyId;
  final int maxHp;
  final double moveSpeed;
  final int expDrop;
  final double collisionRadius;
  final ui.Paint _fallbackPaint;
  final Map<EnemyFacing, SpriteAnimation>? _animations;
  int hp;
  EnemyFacing _facing = EnemyFacing.front;
  double _facingLockSeconds = 0;

  bool get isDead => hp <= 0;

  void moveToward(Vector2 target, double dt) {
    final direction = target - position;
    if (direction.length2 == 0) {
      return;
    }
    if (_facingLockSeconds > 0) {
      _facingLockSeconds -= dt;
    }
    _setFacing(direction);
    direction.normalize();
    position += direction * moveSpeed * dt;
  }

  void _setFacing(Vector2 direction) {
    if (_facingLockSeconds > 0) {
      return;
    }

    final absX = direction.x.abs();
    final absY = direction.y.abs();
    final axisDelta = (absX - absY).abs();
    if (axisDelta < 8) {
      return;
    }

    final nextFacing = absX > absY
        ? direction.x > 0
            ? EnemyFacing.right
            : EnemyFacing.left
        : direction.y > 0
            ? EnemyFacing.front
            : EnemyFacing.back;
    if (nextFacing == _facing) {
      return;
    }
    _facing = nextFacing;
    _facingLockSeconds = 0.18;
    final nextAnimation = _animations?[nextFacing];
    if (nextAnimation != null) {
      animation = nextAnimation;
    }
  }

  void takeDamage(int value) {
    hp -= value;
  }

  @override
  void render(ui.Canvas canvas) {
    if (animation == null) {
      canvas.drawCircle(
        ui.Offset(size.x / 2, size.y / 2),
        collisionRadius,
        _fallbackPaint,
      );
    } else {
      super.render(canvas);
    }
    final hpRatio = (hp / maxHp).clamp(0, 1).toDouble();
    final bgPaint = ui.Paint()..color = const ui.Color(0x66000000);
    final hpPaint = ui.Paint()..color = const ui.Color(0xFFE8FFF2);
    final barRect = ui.Rect.fromLTWH(
      size.x / 2 - collisionRadius,
      -8,
      collisionRadius * 2,
      3,
    );
    canvas.drawRect(barRect, bgPaint);
    canvas.drawRect(
      ui.Rect.fromLTWH(barRect.left, barRect.top, barRect.width * hpRatio, 3),
      hpPaint,
    );
  }

  static ui.Color _colorFor(String enemyId) {
    return switch (enemyId) {
      'fast' => const ui.Color(0xFFFFC857),
      'tank' => const ui.Color(0xFFFF6B6B),
      'boss' => const ui.Color(0xFFE8FFF2),
      _ => const ui.Color(0xFF7FDBFF),
    };
  }
}
