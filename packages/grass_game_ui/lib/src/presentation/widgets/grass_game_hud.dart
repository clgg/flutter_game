import 'package:flutter/material.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';

class GrassGameHud extends StatelessWidget {
  const GrassGameHud({
    super.key,
    required this.snapshot,
  });

  final HudSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final hpRatio = snapshot.maxHp == 0 ? 0.0 : snapshot.hp / snapshot.maxHp;
    final expRatio =
        snapshot.requiredExp == 0 ? 0.0 : snapshot.exp / snapshot.requiredExp;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC07130D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x3349D17D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HudText('HP ${snapshot.hp}/${snapshot.maxHp}'),
                _HudText('Lv ${snapshot.level}'),
                _HudText(_formatTime(snapshot.elapsedSeconds)),
                _HudText('Kills ${snapshot.killCount}'),
                _HudText('Coins ${snapshot.coins}'),
              ],
            ),
            const SizedBox(height: 8),
            _Meter(
              value: hpRatio,
              color: const Color(0xFFFF6B6B),
              backgroundColor: const Color(0x33FFFFFF),
            ),
            const SizedBox(height: 5),
            _Meter(
              value: expRatio,
              color: const Color(0xFF49D17D),
              backgroundColor: const Color(0x22FFFFFF),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }
}

class _HudText extends StatelessWidget {
  const _HudText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFE8FFF2),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final double value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: ColoredBox(
          color: backgroundColor,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: ColoredBox(color: color),
            ),
          ),
        ),
      ),
    );
  }
}
