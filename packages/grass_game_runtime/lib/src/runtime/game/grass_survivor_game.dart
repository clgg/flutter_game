import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:grass_game_domain/grass_game_domain.dart';

import '../components/player_component.dart';
import 'grass_game_runtime_controller.dart';
import 'grass_game_runtime_state.dart';

class GrassSurvivorGame extends FlameGame {
  GrassSurvivorGame({
    required this.config,
    required this.controller,
  }) : state = GrassGameRuntimeState.initial(
          configVersion: config.version,
        );

  final GrassGameConfig config;
  final GrassGameRuntimeController controller;
  GrassGameRuntimeState state;

  late final PlayerComponent player;

  final Paint _backgroundPaint = Paint()..color = const Color(0xFF102418);
  final Paint _gridPaint = Paint()
    ..color = const Color(0x1FE8FFF2)
    ..strokeWidth = 1;

  @override
  Color backgroundColor() => const Color(0xFF102418);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    controller.start();

    player = PlayerComponent(
      controller: controller,
      moveSpeed: config.balance.playerMoveSpeed,
    );

    await addAll([
      TextComponent(
        text: 'Grass Game Ready',
        anchor: Anchor.topCenter,
        position: Vector2(size.x / 2, 72),
        textRenderer: TextPaint(
          style: const painting.TextStyle(
            color: Color(0xFFE8FFF2),
            fontSize: 18,
            fontWeight: painting.FontWeight.w600,
          ),
        ),
      ),
      player,
    ]);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Offset.zero & Size(size.x, size.y), _backgroundPaint);
    _drawGrid(canvas);
    super.render(canvas);
  }

  void _drawGrid(Canvas canvas) {
    const cellSize = 32.0;
    for (var x = 0.0; x <= size.x; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), _gridPaint);
    }
    for (var y = 0.0; y <= size.y; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), _gridPaint);
    }
  }
}
