import 'dart:math' as math;

import 'package:flutter/material.dart';

class OdtSplashAnimation extends StatefulWidget {
  const OdtSplashAnimation({
    super.key,
    required this.onCompleted,
    this.duration = const Duration(milliseconds: 1850),
  });

  final VoidCallback onCompleted;
  final Duration duration;

  @override
  State<OdtSplashAnimation> createState() => _OdtSplashAnimationState();
}

class _OdtSplashAnimationState extends State<OdtSplashAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onCompleted();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final settle = _interval(value, 0.78, 1.0, Curves.easeInOut);
        final scale = 1 + math.sin(settle * math.pi) * 0.025;

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 230,
            height: 150,
            child: CustomPaint(
              painter: _OdtLogoPainter(
                backgroundProgress: _interval(
                  value,
                  0,
                  0.12,
                  Curves.easeOut,
                ),
                oProgress: _interval(value, 0.06, 0.36, Curves.easeOutCubic),
                dLineProgress: _interval(
                  value,
                  0.24,
                  0.48,
                  Curves.easeOutCubic,
                ),
                dCurveProgress: _interval(
                  value,
                  0.36,
                  0.66,
                  Curves.easeOutCubic,
                ),
                tTopProgress: _interval(
                  value,
                  0.52,
                  0.76,
                  Curves.easeOutBack,
                ),
                tStemProgress: _interval(
                  value,
                  0.62,
                  0.84,
                  Curves.easeOutCubic,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

double _interval(
  double value,
  double start,
  double end,
  Curve curve,
) {
  if (value <= start) {
    return 0;
  }
  if (value >= end) {
    return 1;
  }

  return curve.transform((value - start) / (end - start));
}

class _OdtLogoPainter extends CustomPainter {
  _OdtLogoPainter({
    required this.backgroundProgress,
    required this.oProgress,
    required this.dLineProgress,
    required this.dCurveProgress,
    required this.tTopProgress,
    required this.tStemProgress,
  });

  final double backgroundProgress;
  final double oProgress;
  final double dLineProgress;
  final double dCurveProgress;
  final double tTopProgress;
  final double tStemProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.06;
    final logoPaint = Paint()
      ..color = const Color(0xFFE8FFF2).withOpacity(backgroundProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentPaint = Paint()
      ..color = const Color(0xFF49D17D).withOpacity(backgroundProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final width = size.width;
    final height = size.height;
    final top = height * 0.2;
    final bottom = height * 0.82;
    final centerY = (top + bottom) / 2;
    final letterHeight = bottom - top;

    final oRect = Rect.fromLTWH(
      width * 0.04,
      top,
      letterHeight * 0.72,
      letterHeight,
    );
    final dLeftX = width * 0.38;
    final dRect = Rect.fromLTWH(
      dLeftX - letterHeight * 0.05,
      top,
      letterHeight * 0.72,
      letterHeight,
    );
    final tLeft = width * 0.68;
    final tRight = width * 0.96;
    final tCenter = (tLeft + tRight) / 2;

    final oPath = Path()
      ..addOval(oRect)
      ..shift(Offset.zero);
    _drawPartialPath(canvas, oPath, oProgress, logoPaint);

    final dLinePath = Path()
      ..moveTo(dLeftX, top)
      ..lineTo(dLeftX, bottom);
    _drawPartialPath(canvas, dLinePath, dLineProgress, accentPaint);

    final dCurvePath = Path()
      ..moveTo(dLeftX, top)
      ..arcTo(
        dRect,
        -math.pi / 2,
        math.pi,
        false,
      )
      ..lineTo(dLeftX, bottom);
    _drawPartialPath(canvas, dCurvePath, dCurveProgress, logoPaint);

    final tTopPath = Path()
      ..moveTo(tLeft, top)
      ..lineTo(tRight, top);
    _drawPartialPath(canvas, tTopPath, tTopProgress, accentPaint);

    final tStemPath = Path()
      ..moveTo(tCenter, top)
      ..lineTo(tCenter, bottom);
    _drawPartialPath(canvas, tStemPath, tStemProgress, logoPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF49D17D).withOpacity(
        (tStemProgress * backgroundProgress).clamp(0, 1),
      );
    canvas.drawCircle(
      Offset(width * 0.32, centerY),
      strokeWidth * 0.24,
      dotPaint,
    );
  }

  void _drawPartialPath(
    Canvas canvas,
    Path path,
    double progress,
    Paint paint,
  ) {
    if (progress <= 0) {
      return;
    }

    for (final metric in path.computeMetrics()) {
      final extract = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extract, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OdtLogoPainter oldDelegate) {
    return backgroundProgress != oldDelegate.backgroundProgress ||
        oProgress != oldDelegate.oProgress ||
        dLineProgress != oldDelegate.dLineProgress ||
        dCurveProgress != oldDelegate.dCurveProgress ||
        tTopProgress != oldDelegate.tTopProgress ||
        tStemProgress != oldDelegate.tStemProgress;
  }
}
