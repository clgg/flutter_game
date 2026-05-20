import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';

void main() {
  test('bouncing projectile reflects from visible bounds', () {
    final projectile = ProjectileComponent(
      damage: 1,
      velocity: Vector2(100, 0),
      maxTravelDistance: 300,
      position: Vector2(105, 50),
      visualStyle: ProjectileVisualStyle.forKind('weapon_bounce'),
      motionType: ProjectileMotionType.bouncing,
      bouncesRemaining: 1,
    );

    final bounced = projectile.bounceInside(
      const ui.Rect.fromLTRB(0, 0, 100, 100),
    );

    expect(bounced, isTrue);
    expect(projectile.position.x, 100);
    expect(projectile.velocity.x, isNegative);
    expect(projectile.isDone, isFalse);
  });

  test('boomerang projectile returns after outbound distance', () {
    final projectile = ProjectileComponent(
      damage: 1,
      velocity: Vector2(100, 0),
      maxTravelDistance: 100,
      position: Vector2.zero(),
      visualStyle: ProjectileVisualStyle.forKind('weapon_boomerang'),
      motionType: ProjectileMotionType.boomerang,
      origin: Vector2.zero(),
    );

    projectile.update(0.6);
    projectile.update(0.01);

    expect(projectile.isReturning, isTrue);
    expect(projectile.velocity.x, isNegative);
  });
}
