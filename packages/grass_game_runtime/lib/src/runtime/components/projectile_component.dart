import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame/components.dart';

class ProjectileComponent extends CircleComponent {
  ProjectileComponent({
    required this.damage,
    required this.velocity,
    required this.maxTravelDistance,
    required Vector2 position,
    required this.visualStyle,
    this.image,
    this.skillTag,
    this.pierceRemaining = 0,
  }) : super(
          radius: visualStyle.collisionRadius,
          anchor: Anchor.center,
          position: position,
          paint: ui.Paint()..color = const ui.Color(0xFFE8FFF2),
        ) {
    _direction = velocity.length2 == 0 ? Vector2(1, 0) : velocity.normalized();
    _angle = math.atan2(_direction.y, _direction.x);
    _previousPosition = position.clone();
    _imagePaint = ui.Paint()
      ..filterQuality = ui.FilterQuality.none
      ..colorFilter = visualStyle.tint == null
          ? null
          : ui.ColorFilter.mode(visualStyle.tint!, ui.BlendMode.srcATop);
    _trailPaint = ui.Paint()
      ..color = visualStyle.trailColor.withAlpha(130)
      ..strokeWidth = visualStyle.trailWidth
      ..strokeCap = ui.StrokeCap.round;
    _glowPaint = ui.Paint()..color = visualStyle.glowColor;
    _corePaint = ui.Paint()..color = visualStyle.coreColor;
    _highlightPaint = ui.Paint()..color = const ui.Color(0xEFFFFFFF);
  }

  final int damage;
  final Vector2 velocity;
  final double maxTravelDistance;
  final ProjectileVisualStyle visualStyle;
  final ui.Image? image;
  final String? skillTag;
  int pierceRemaining;
  double age = 0;
  double _travelDistance = 0;
  late final double _angle;
  late final Vector2 _direction;
  late Vector2 _previousPosition;
  late final ui.Paint _imagePaint;
  late final ui.Paint _trailPaint;
  late final ui.Paint _glowPaint;
  late final ui.Paint _corePaint;
  late final ui.Paint _highlightPaint;

  bool get hasExceededRange => _travelDistance >= maxTravelDistance;

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;
    final step = velocity * dt;
    _previousPosition = position.clone();
    position += step;
    _travelDistance += step.length;
  }

  @override
  void render(ui.Canvas canvas) {
    _drawTrail(canvas);
    final projectileImage = image;
    if (projectileImage == null) {
      _drawFallbackProjectile(canvas);
      return;
    }

    canvas.save();
    canvas.rotate(_angle);
    canvas.drawImageRect(
      projectileImage,
      ui.Rect.fromLTWH(
        0,
        0,
        projectileImage.width.toDouble(),
        projectileImage.height.toDouble(),
      ),
      ui.Rect.fromCenter(
        center: ui.Offset.zero,
        width: visualStyle.imageWidth,
        height: visualStyle.imageHeight,
      ),
      _imagePaint,
    );
    canvas.restore();
  }

  void _drawTrail(ui.Canvas canvas) {
    final delta = _previousPosition - position;
    final fallbackTrail = -_direction * visualStyle.trailLength;
    final localTrail = delta.length2 > 1 ? delta : fallbackTrail;
    final start = ui.Offset(localTrail.x, localTrail.y);
    final end = ui.Offset.zero;
    canvas.drawLine(start, end, _trailPaint);
    canvas.drawCircle(ui.Offset.zero, visualStyle.glowRadius, _glowPaint);
  }

  void _drawFallbackProjectile(ui.Canvas canvas) {
    canvas.save();
    canvas.rotate(_angle);
    _drawCore(canvas);
    canvas.restore();
  }

  void _drawCore(ui.Canvas canvas) {
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
          center: ui.Offset.zero,
          width: visualStyle.coreLength,
          height: visualStyle.coreWidth,
        ),
        ui.Radius.circular(visualStyle.coreWidth),
      ),
      _corePaint,
    );
    canvas.drawCircle(
      ui.Offset(visualStyle.coreLength * 0.24, 0),
      visualStyle.coreWidth * 0.33,
      _highlightPaint,
    );
  }
}

class ProjectileVisualStyle {
  const ProjectileVisualStyle({
    required this.collisionRadius,
    required this.imageWidth,
    required this.imageHeight,
    required this.coreLength,
    required this.coreWidth,
    required this.trailLength,
    required this.trailWidth,
    required this.glowRadius,
    required this.coreColor,
    required this.trailColor,
    required this.glowColor,
    this.tint,
  });

  factory ProjectileVisualStyle.forKind(String kind) {
    return switch (kind) {
      'star_projectile' => const ProjectileVisualStyle(
          collisionRadius: 4,
          imageWidth: 26,
          imageHeight: 18,
          coreLength: 20,
          coreWidth: 5,
          trailLength: 44,
          trailWidth: 4,
          glowRadius: 10,
          coreColor: ui.Color(0xFFFFFFFF),
          trailColor: ui.Color(0xFF8FD7FF),
          glowColor: ui.Color(0x558FD7FF),
        ),
      '霰弹枪' => const ProjectileVisualStyle(
          collisionRadius: 6,
          imageWidth: 34,
          imageHeight: 24,
          coreLength: 18,
          coreWidth: 8,
          trailLength: 18,
          trailWidth: 5,
          glowRadius: 9,
          coreColor: ui.Color(0xFFFFC6BD),
          trailColor: ui.Color(0xFFFFA69E),
          glowColor: ui.Color(0x44FFA69E),
        ),
      '火焰喷射器' => const ProjectileVisualStyle(
          collisionRadius: 8,
          imageWidth: 42,
          imageHeight: 30,
          coreLength: 24,
          coreWidth: 12,
          trailLength: 28,
          trailWidth: 10,
          glowRadius: 14,
          coreColor: ui.Color(0xFFFFE16A),
          trailColor: ui.Color(0xFFFF6B3A),
          glowColor: ui.Color(0x66FF6B3A),
        ),
      '近战' => const ProjectileVisualStyle(
          collisionRadius: 10,
          imageWidth: 46,
          imageHeight: 34,
          coreLength: 34,
          coreWidth: 12,
          trailLength: 24,
          trailWidth: 8,
          glowRadius: 13,
          coreColor: ui.Color(0xFFFFD36E),
          trailColor: ui.Color(0xFFFFA84A),
          glowColor: ui.Color(0x55FFD36E),
        ),
      '投射' => const ProjectileVisualStyle(
          collisionRadius: 6,
          imageWidth: 34,
          imageHeight: 24,
          coreLength: 26,
          coreWidth: 7,
          trailLength: 38,
          trailWidth: 4,
          glowRadius: 10,
          coreColor: ui.Color(0xFFE8FFF2),
          trailColor: ui.Color(0xFF8FD7FF),
          glowColor: ui.Color(0x448FD7FF),
        ),
      '枪械' => const ProjectileVisualStyle(
          collisionRadius: 5,
          imageWidth: 32,
          imageHeight: 22,
          coreLength: 24,
          coreWidth: 6,
          trailLength: 32,
          trailWidth: 4,
          glowRadius: 8,
          coreColor: ui.Color(0xFFFFE16A),
          trailColor: ui.Color(0xFFFF8A4C),
          glowColor: ui.Color(0x44FF8A4C),
        ),
      '能量' => const ProjectileVisualStyle(
          collisionRadius: 7,
          imageWidth: 38,
          imageHeight: 26,
          coreLength: 28,
          coreWidth: 8,
          trailLength: 42,
          trailWidth: 5,
          glowRadius: 13,
          coreColor: ui.Color(0xFFE8D8FF),
          trailColor: ui.Color(0xFFB68CFF),
          glowColor: ui.Color(0x66B68CFF),
        ),
      '爆破' => const ProjectileVisualStyle(
          collisionRadius: 9,
          imageWidth: 40,
          imageHeight: 32,
          coreLength: 24,
          coreWidth: 12,
          trailLength: 24,
          trailWidth: 7,
          glowRadius: 12,
          coreColor: ui.Color(0xFFFFD166),
          trailColor: ui.Color(0xFFFF6B35),
          glowColor: ui.Color(0x55FFD166),
        ),
      '控制' => const ProjectileVisualStyle(
          collisionRadius: 7,
          imageWidth: 36,
          imageHeight: 26,
          coreLength: 26,
          coreWidth: 8,
          trailLength: 36,
          trailWidth: 5,
          glowRadius: 12,
          coreColor: ui.Color(0xFFE0F6FF),
          trailColor: ui.Color(0xFF9BD3FF),
          glowColor: ui.Color(0x669BD3FF),
        ),
      '迫击炮' || '榴弹发射器' || '步兵用发射器' => const ProjectileVisualStyle(
          collisionRadius: 8,
          imageWidth: 34,
          imageHeight: 34,
          coreLength: 20,
          coreWidth: 11,
          trailLength: 22,
          trailWidth: 6,
          glowRadius: 10,
          coreColor: ui.Color(0xFFDDE5DF),
          trailColor: ui.Color(0xFFFFD166),
          glowColor: ui.Color(0x44FFD166),
        ),
      '反坦克步枪' => const ProjectileVisualStyle(
          collisionRadius: 6,
          imageWidth: 42,
          imageHeight: 24,
          coreLength: 30,
          coreWidth: 7,
          trailLength: 42,
          trailWidth: 4,
          glowRadius: 10,
          coreColor: ui.Color(0xFFFFD166),
          trailColor: ui.Color(0xFFFFE8A3),
          glowColor: ui.Color(0x44FFD166),
        ),
      '冲锋枪' || '突击步枪' || '机枪' => const ProjectileVisualStyle(
          collisionRadius: 5,
          imageWidth: 30,
          imageHeight: 20,
          coreLength: 24,
          coreWidth: 6,
          trailLength: 34,
          trailWidth: 4,
          glowRadius: 8,
          coreColor: ui.Color(0xFFFFF1A8),
          trailColor: ui.Color(0xFFFFC857),
          glowColor: ui.Color(0x33FFC857),
        ),
      _ => const ProjectileVisualStyle(
          collisionRadius: 5,
          imageWidth: 30,
          imageHeight: 22,
          coreLength: 24,
          coreWidth: 6,
          trailLength: 30,
          trailWidth: 4,
          glowRadius: 8,
          coreColor: ui.Color(0xFFE8FFF2),
          trailColor: ui.Color(0xFF7FDBFF),
          glowColor: ui.Color(0x337FDBFF),
        ),
    };
  }

  final double collisionRadius;
  final double imageWidth;
  final double imageHeight;
  final double coreLength;
  final double coreWidth;
  final double trailLength;
  final double trailWidth;
  final double glowRadius;
  final ui.Color coreColor;
  final ui.Color trailColor;
  final ui.Color glowColor;
  final ui.Color? tint;
}
