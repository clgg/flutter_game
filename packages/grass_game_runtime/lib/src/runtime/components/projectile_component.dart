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
  }) : super(
          radius: visualStyle.collisionRadius,
          anchor: Anchor.center,
          position: position,
          paint: ui.Paint()..color = const ui.Color(0xFFE8FFF2),
        ) {
    _direction = velocity.length2 == 0 ? Vector2(1, 0) : velocity.normalized();
    _angle = math.atan2(_direction.y, _direction.x);
    _previousPosition = position.clone();
  }

  final int damage;
  final Vector2 velocity;
  final double maxTravelDistance;
  final ProjectileVisualStyle visualStyle;
  final ui.Image? image;
  double age = 0;
  double _travelDistance = 0;
  late final double _angle;
  late final Vector2 _direction;
  late Vector2 _previousPosition;

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
      ui.Paint()
        ..filterQuality = ui.FilterQuality.none
        ..colorFilter = visualStyle.tint == null
            ? null
            : ui.ColorFilter.mode(visualStyle.tint!, ui.BlendMode.srcATop),
    );
    canvas.restore();
  }

  void _drawTrail(ui.Canvas canvas) {
    final delta = _previousPosition - position;
    final fallbackTrail = -_direction * visualStyle.trailLength;
    final localTrail = delta.length2 > 1 ? delta : fallbackTrail;
    final start = ui.Offset(localTrail.x, localTrail.y);
    final end = ui.Offset.zero;
    final paint = ui.Paint()
      ..strokeWidth = visualStyle.trailWidth
      ..strokeCap = ui.StrokeCap.round
      ..shader = ui.Gradient.linear(
        start,
        end,
        [
          visualStyle.trailColor.withAlpha(0),
          visualStyle.trailColor.withAlpha(110),
          visualStyle.coreColor.withAlpha(230),
        ],
        const [0, 0.58, 1],
      );
    canvas.drawLine(start, end, paint);

    final glowPaint = ui.Paint()
      ..color = visualStyle.glowColor
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    canvas.drawCircle(ui.Offset.zero, visualStyle.glowRadius, glowPaint);
  }

  void _drawFallbackProjectile(ui.Canvas canvas) {
    canvas.save();
    canvas.rotate(_angle);
    _drawCore(canvas);
    canvas.restore();
  }

  void _drawCore(ui.Canvas canvas) {
    final paint = ui.Paint()..color = visualStyle.coreColor;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
          center: ui.Offset.zero,
          width: visualStyle.coreLength,
          height: visualStyle.coreWidth,
        ),
        ui.Radius.circular(visualStyle.coreWidth),
      ),
      paint,
    );
    final highlightPaint = ui.Paint()..color = const ui.Color(0xEFFFFFFF);
    canvas.drawCircle(
      ui.Offset(visualStyle.coreLength * 0.24, 0),
      visualStyle.coreWidth * 0.33,
      highlightPaint,
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
