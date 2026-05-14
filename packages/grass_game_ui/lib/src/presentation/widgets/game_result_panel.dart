import 'package:flutter/material.dart';

class GameResultPanel extends StatelessWidget {
  const GameResultPanel({
    super.key,
    required this.killCount,
    required this.survivalSeconds,
  });

  final int killCount;
  final int survivalSeconds;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kills $killCount',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Time ${survivalSeconds}s',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
