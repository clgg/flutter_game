import 'package:flutter/material.dart';

import '../widgets/grass_game_hud.dart';
import '../widgets/virtual_joystick.dart';

class GrassGamePage extends StatelessWidget {
  const GrassGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          ColoredBox(
            color: Color(0xFF102418),
            child: Center(
              child: Text(
                'Grass Game Ready',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: 16,
            right: 16,
            child: GrassGameHud(),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: VirtualJoystick(),
          ),
        ],
      ),
    );
  }
}
