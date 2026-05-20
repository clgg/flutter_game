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
        _rowCount = (image.height / (image.width / _columns)).round(),
        _frameSize = Vector2.all(image.width / _columns);

  static const int _columns = 6;
  static const int _walkFrames = 4;
  static const int _attackFrames = 4;
  static const int _rows = 8;
  static const int _attackRowOffset = 0;
  static const int _walkRowOffset = 4;

  final ui.Image _image;
  final int _rowCount;
  final Vector2 _frameSize;
  final Vector2 displaySize;

  Map<EnemyFacing, SpriteAnimation> createWalkAnimations() {
    if (_rowCount >= _rows) {
      return {
        EnemyFacing.front: _createAnimation(_walkRowOffset, 0, _walkFrames),
        EnemyFacing.frontRight:
            _createAnimation(_walkRowOffset, 1, _walkFrames),
        EnemyFacing.right: _createAnimation(_walkRowOffset, 2, _walkFrames),
        EnemyFacing.backRight: _createAnimation(_walkRowOffset, 3, _walkFrames),
        EnemyFacing.back: _createAnimation(_walkRowOffset, 4, _walkFrames),
        EnemyFacing.backLeft: _createAnimation(_walkRowOffset, 5, _walkFrames),
        EnemyFacing.left: _createAnimation(_walkRowOffset, 6, _walkFrames),
        EnemyFacing.frontLeft: _createAnimation(_walkRowOffset, 7, _walkFrames),
      };
    }
    return {
      EnemyFacing.front: _createAnimation(0, 0, _walkFrames),
      EnemyFacing.back: _createAnimation(0, 1, _walkFrames),
      EnemyFacing.left: _createAnimation(0, 2, _walkFrames),
      EnemyFacing.right: _createAnimation(0, 3, _walkFrames),
      EnemyFacing.frontRight: _createAnimation(0, 3, _walkFrames),
      EnemyFacing.backRight: _createAnimation(0, 3, _walkFrames),
      EnemyFacing.backLeft: _createAnimation(0, 2, _walkFrames),
      EnemyFacing.frontLeft: _createAnimation(0, 2, _walkFrames),
    };
  }

  Map<EnemyFacing, SpriteAnimation> createAttackAnimations() {
    if (_rowCount < _rows) {
      return const {};
    }
    return {
      EnemyFacing.front:
          _createAnimation(_attackRowOffset, 0, _attackFrames, loop: false),
      EnemyFacing.frontRight:
          _createAnimation(_attackRowOffset, 1, _attackFrames, loop: false),
      EnemyFacing.right:
          _createAnimation(_attackRowOffset, 2, _attackFrames, loop: false),
      EnemyFacing.backRight:
          _createAnimation(_attackRowOffset, 3, _attackFrames, loop: false),
      EnemyFacing.back:
          _createAnimation(_attackRowOffset, 4, _attackFrames, loop: false),
      EnemyFacing.backLeft:
          _createAnimation(_attackRowOffset, 5, _attackFrames, loop: false),
      EnemyFacing.left:
          _createAnimation(_attackRowOffset, 6, _attackFrames, loop: false),
      EnemyFacing.frontLeft:
          _createAnimation(_attackRowOffset, 7, _attackFrames, loop: false),
    };
  }

  SpriteAnimation _createAnimation(
    int rowOffset,
    int directionRow,
    int frameCount, {
    bool loop = true,
  }) {
    return SpriteAnimation.fromFrameData(
      _image,
      SpriteAnimationData.sequenced(
        amount: frameCount,
        stepTime: loop ? 0.12 : 0.08,
        textureSize: _frameSize,
        texturePosition: Vector2(0, _frameSize.y * (rowOffset + directionRow)),
        loop: loop,
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
