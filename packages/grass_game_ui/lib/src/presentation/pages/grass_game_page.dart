import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:grass_game_domain/grass_game_domain.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';

import '../widgets/grass_game_hud.dart';
import '../widgets/virtual_joystick.dart';

class GrassGamePage extends StatefulWidget {
  const GrassGamePage({super.key});

  @override
  State<GrassGamePage> createState() => _GrassGamePageState();
}

class _GrassGamePageState extends State<GrassGamePage> {
  late final GrassGameRuntimeController _controller;
  late final GrassSurvivorGame _game;

  @override
  void initState() {
    super.initState();
    _controller = GrassGameRuntimeController();
    _game = GrassSurvivorGame(
      config: GrassGameConfig.defaults,
      controller: _controller,
    );
  }

  @override
  void dispose() {
    _controller.setMoveDirection(0, 0);
    _controller.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget<GrassSurvivorGame>(game: _game),
          const Positioned(
            top: 24,
            left: 16,
            right: 16,
            child: GrassGameHud(),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: SafeArea(
              child: VirtualJoystick(
                onChanged: (direction) {
                  _controller.setMoveDirection(direction.dx, direction.dy);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
