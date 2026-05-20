import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'enemy_component.dart';

class CompanionAnimationSet {
  CompanionAnimationSet({
    required ui.Image image,
    required this.displaySize,
  }) : _delegate = EnemyAnimationSet(
          image: image,
          displaySize: displaySize,
        );

  final EnemyAnimationSet _delegate;
  final Vector2 displaySize;

  Map<EnemyFacing, SpriteAnimation> createWalkAnimations() {
    return _delegate.createWalkAnimations();
  }
}

class CompanionComponent extends SpriteAnimationComponent {
  CompanionComponent({
    required this.companionId,
    required this.slotIndex,
    required this.moveSpeed,
    required this.remainingLifetime,
    required CompanionAnimationSet animationSet,
    required Vector2 position,
  })  : _walkAnimations = animationSet.createWalkAnimations(),
        super(
          anchor: Anchor.center,
          position: position,
          size: animationSet.displaySize,
        ) {
    animation = _walkAnimations[EnemyFacing.front];
  }

  final String companionId;
  final int slotIndex;
  final double moveSpeed;
  double remainingLifetime;
  double attackTimer = 0;
  final Map<EnemyFacing, SpriteAnimation> _walkAnimations;
  EnemyFacing _facing = EnemyFacing.front;
  double _facingLockSeconds = 0;
  double _dashTimer = 0;
  Vector2 _dashVelocity = Vector2.zero();

  bool get isExpired => remainingLifetime <= 0;

  @override
  void update(double dt) {
    super.update(dt);
    remainingLifetime -= dt;
    attackTimer -= dt;
    if (_facingLockSeconds > 0) {
      _facingLockSeconds -= dt;
    }
    if (_dashTimer <= 0) {
      return;
    }
    final step = math.min(dt, _dashTimer);
    position += _dashVelocity * step;
    _dashTimer -= step;
    if (_dashTimer <= 0) {
      _dashVelocity = Vector2.zero();
    }
  }

  void moveToward(Vector2 target, double dt) {
    final delta = target - position;
    if (delta.length2 < 4) {
      playing = false;
      return;
    }

    _setFacing(delta);
    playing = true;
    final distance = delta.length;
    delta.scale(1 / distance);
    position += delta * math.min(distance, moveSpeed * dt);
  }

  void faceToward(Vector2 target) {
    final delta = target - position;
    if (delta.length2 > 0.0001) {
      _setFacing(delta);
    }
  }

  void refreshLifetime(double lifetime) {
    remainingLifetime = math.max(remainingLifetime, lifetime);
  }

  void dash(Vector2 direction, {required double speed, required double time}) {
    if (direction.length2 <= 0.0001 || time <= 0) {
      return;
    }
    final normalized = direction.normalized();
    _setFacing(normalized);
    _dashVelocity = normalized * speed;
    _dashTimer = time;
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
    _facingLockSeconds = 0.14;
    final nextAnimation = _walkAnimations[nextFacing];
    if (nextAnimation != null) {
      animation = nextAnimation;
    }
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
}
