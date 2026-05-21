import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

enum EnemyFacing {
  front,
  frontRight,
  right,
  backRight,
  back,
  backLeft,
  left,
  frontLeft,
}

class EnemyAnimationSet {
  EnemyAnimationSet({
    required ui.Image image,
    required this.displaySize,
  })  : _image = image,
        _columns = math.max(1, (image.width / _cellSize).round()),
        _rowCount = (image.height / _cellSize).round(),
        _frameSize = Vector2.all(_cellSize);

  static const double _cellSize = 128;
  static const int _rows = 8;

  final ui.Image _image;
  final int _columns;
  final int _rowCount;
  final Vector2 _frameSize;
  final Vector2 displaySize;

  Map<EnemyFacing, SpriteAnimation> createWalkAnimations() {
    if (_rowCount >= _rows) {
      return {
        EnemyFacing.front: _createAnimation(4),
        EnemyFacing.frontRight: _createAnimation(7),
        EnemyFacing.right: _createAnimation(7),
        EnemyFacing.backRight: _createAnimation(7),
        EnemyFacing.back: _createAnimation(5),
        EnemyFacing.backLeft: _createAnimation(6),
        EnemyFacing.left: _createAnimation(6),
        EnemyFacing.frontLeft: _createAnimation(6),
      };
    }
    return {
      EnemyFacing.front: _createAnimation(0),
      EnemyFacing.back: _createAnimation(1),
      EnemyFacing.left: _createAnimation(2),
      EnemyFacing.right: _createAnimation(3),
      EnemyFacing.frontRight: _createAnimation(3),
      EnemyFacing.backRight: _createAnimation(3),
      EnemyFacing.backLeft: _createAnimation(2),
      EnemyFacing.frontLeft: _createAnimation(2),
    };
  }

  Map<EnemyFacing, SpriteAnimation> createAttackAnimations() {
    if (_rowCount >= _rows) {
      return {
        EnemyFacing.front: _createAnimation(0),
        EnemyFacing.frontRight: _createAnimation(3),
        EnemyFacing.right: _createAnimation(3),
        EnemyFacing.backRight: _createAnimation(3),
        EnemyFacing.back: _createAnimation(1),
        EnemyFacing.backLeft: _createAnimation(2),
        EnemyFacing.left: _createAnimation(2),
        EnemyFacing.frontLeft: _createAnimation(2),
      };
    }
    return const {};
  }

  SpriteAnimation _createAnimation(int row) {
    return SpriteAnimation.fromFrameData(
      _image,
      SpriteAnimationData.sequenced(
        amount: _columns,
        stepTime: 0.12,
        textureSize: _frameSize,
        texturePosition: Vector2(0, _frameSize.y * row),
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
    double? collisionRadiusOverride,
    Vector2? sizeOverride,
    this.meleeDamageMin = 8,
    this.meleeDamageMax = 8,
  })  : hp = maxHp,
        collisionRadius = collisionRadiusOverride ??
            (enemyId == 'boss'
                ? 34
                : enemyId == 'tank'
                    ? 20
                    : enemyId == 'turkey' || enemyId == 'calf'
                        ? 17
                        : enemyId == 'fast'
                            ? 11
                            : enemyId.startsWith('guaishou_')
                                ? 28
                                : 14),
        _fallbackPaint = ui.Paint()..color = _colorFor(enemyId),
        _walkAnimations = animationSet?.createWalkAnimations(),
        _attackAnimations = animationSet?.createAttackAnimations(),
        super(
          anchor: Anchor.center,
          position: position,
          size: sizeOverride ??
              animationSet?.displaySize ??
              Vector2.all(enemyId == 'boss'
                  ? 82
                  : enemyId == 'tank'
                      ? 44
                      : 34),
        ) {
    animation = _walkAnimations?[EnemyFacing.front];
  }

  final String enemyId;
  int maxHp;
  double moveSpeed;
  final int expDrop;
  double collisionRadius;
  int meleeDamageMin;
  int meleeDamageMax;
  final ui.Paint _fallbackPaint;
  final Map<EnemyFacing, SpriteAnimation>? _walkAnimations;
  final Map<EnemyFacing, SpriteAnimation>? _attackAnimations;
  int hp;
  EnemyFacing _facing = EnemyFacing.front;
  double _facingLockSeconds = 0;
  double _attackAnimationSeconds = 0;
  double _slowTimer = 0;
  double _slowMultiplier = 1;

  bool get isDead => hp <= 0;
  bool get isAttackAnimationActive => _attackAnimationSeconds > 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_attackAnimationSeconds <= 0) {
      return;
    }
    _attackAnimationSeconds -= dt;
    if (_attackAnimationSeconds <= 0) {
      _setWalkAnimation();
    }
  }

  void moveToward(Vector2 target, double dt) {
    if (_slowTimer > 0) {
      _slowTimer -= dt;
      if (_slowTimer <= 0) {
        _slowMultiplier = 1;
      }
    }
    final direction = target - position;
    if (direction.length2 == 0) {
      return;
    }
    if (_facingLockSeconds > 0) {
      _facingLockSeconds -= dt;
    }
    _setFacing(direction);
    direction.normalize();
    position += direction * moveSpeed * _slowMultiplier * dt;
  }

  void _setFacing(Vector2 direction) {
    if (_facingLockSeconds > 0) {
      return;
    }

    final nextFacing = _facingForDirection(direction);
    if (nextFacing == _facing) {
      return;
    }
    _facing = nextFacing;
    _facingLockSeconds = 0.18;
    if (_attackAnimationSeconds > 0) {
      return;
    }
    _setWalkAnimation();
  }

  void triggerAttackAnimation() {
    final nextAnimation = _attackAnimations?[_facing];
    if (nextAnimation != null) {
      animation = nextAnimation;
      animationTicker?.reset();
      _attackAnimationSeconds = 0.34;
      return;
    }
    _attackAnimationSeconds = 0.18;
  }

  void _setWalkAnimation() {
    final nextAnimation = _walkAnimations?[_facing];
    if (nextAnimation != null) {
      animation = nextAnimation;
    }
    _attackAnimationSeconds = 0;
  }

  EnemyFacing _facingForDirection(Vector2 direction) {
    final angle = math.atan2(direction.y, direction.x);
    final sector = ((angle + math.pi / 8) / (math.pi / 4)).floor() & 7;
    return switch (sector) {
      0 => EnemyFacing.right,
      1 => EnemyFacing.frontRight,
      2 => EnemyFacing.front,
      3 => EnemyFacing.frontLeft,
      4 => EnemyFacing.left,
      5 => EnemyFacing.backLeft,
      6 => EnemyFacing.back,
      _ => EnemyFacing.backRight,
    };
  }

  void takeDamage(int value) {
    hp -= value;
  }

  void applySlow({
    required double multiplier,
    required double duration,
  }) {
    final nextMultiplier = multiplier.clamp(0.05, 1).toDouble();
    if (nextMultiplier < _slowMultiplier || duration > _slowTimer) {
      _slowMultiplier = nextMultiplier;
      _slowTimer = duration;
    }
  }

  void applyBuff({
    required double hpMultiplier,
    required double speedMultiplier,
    required double sizeMultiplier,
    required double damageMultiplier,
  }) {
    final nextMaxHp = (maxHp * hpMultiplier).ceil();
    hp += nextMaxHp - maxHp;
    maxHp = nextMaxHp;
    moveSpeed *= speedMultiplier;
    size *= sizeMultiplier;
    collisionRadius *= sizeMultiplier;
    meleeDamageMin = (meleeDamageMin * damageMultiplier).ceil();
    meleeDamageMax = (meleeDamageMax * damageMultiplier).ceil();
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
      'lamb' => const ui.Color(0xFFE8FFF2),
      'piglet' => const ui.Color(0xFFFF9BB0),
      'calf' => const ui.Color(0xFF9BD3FF),
      'rooster' => const ui.Color(0xFFFF6B6B),
      'turkey' => const ui.Color(0xFFB68CFF),
      'tank' => const ui.Color(0xFFFF6B6B),
      'boss' => const ui.Color(0xFFE8FFF2),
      final id when id.startsWith('guaishou_') => const ui.Color(0xFFFF5B6F),
      _ => const ui.Color(0xFF7FDBFF),
    };
  }
}
