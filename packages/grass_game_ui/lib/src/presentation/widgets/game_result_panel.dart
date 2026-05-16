import 'package:flutter/material.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

class GameResultPanel extends StatelessWidget {
  const GameResultPanel({
    super.key,
    required this.result,
    required this.onRestart,
    required this.onExit,
  });

  final GameResult result;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF102418),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x6649D17D)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.isWin ? 'Victory' : 'Run Ended',
                  style: const TextStyle(
                    color: Color(0xFFE8FFF2),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Time ${result.survivalSeconds}s  ·  Kills ${result.killCount}  ·  Battle Lv ${result.level}',
                  style: const TextStyle(
                    color: Color(0xBFE8FFF2),
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+${result.coinsEarned} coins  ·  +${result.characterExpEarned} hero EXP',
                  style: const TextStyle(
                    color: Color(0xFFFFC857),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: onExit,
                      child: const Text('Stages'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: onRestart,
                      child: const Text('Restart'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
