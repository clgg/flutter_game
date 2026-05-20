import 'package:flutter/material.dart';

class AnimatedCharacterSprite extends StatefulWidget {
  const AnimatedCharacterSprite({
    super.key,
    required this.spriteSheetAssetPath,
    required this.size,
    this.row = 0,
    this.frameCount = 6,
    this.rowCount = 8,
    this.frameDuration = const Duration(milliseconds: 120),
    this.animate = true,
  });

  final String spriteSheetAssetPath;
  final double size;
  final int row;
  final int frameCount;
  final int rowCount;
  final Duration frameDuration;
  final bool animate;

  @override
  State<AnimatedCharacterSprite> createState() =>
      _AnimatedCharacterSpriteState();
}

class _AnimatedCharacterSpriteState extends State<AnimatedCharacterSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.frameDuration * widget.frameCount,
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCharacterSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frameDuration != widget.frameDuration ||
        oldWidget.frameCount != widget.frameCount) {
      _controller.duration = widget.frameDuration * widget.frameCount;
    }
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row.clamp(0, widget.rowCount - 1);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final rawFrame = widget.animate
            ? (_controller.value * widget.frameCount).floor()
            : 0;
        final frame = rawFrame.clamp(0, widget.frameCount - 1);
        return ClipRect(
          child: SizedBox.square(
            dimension: widget.size,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: -frame * widget.size,
                  top: -row * widget.size,
                  child: Image.asset(
                    widget.spriteSheetAssetPath,
                    width: widget.size * widget.frameCount,
                    height: widget.size * widget.rowCount,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
