import 'package:flutter/material.dart';
import 'package:app_core/app_core.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';

class GrassGameHud extends StatelessWidget {
  const GrassGameHud({
    super.key,
    required this.snapshot,
  });

  final HudSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final stageName = isZh
        ? '第 ${snapshot.stageChapter}-${snapshot.stageIndex} 关'
        : snapshot.stageName;
    final expRatio =
        snapshot.requiredExp == 0 ? 0.0 : snapshot.exp / snapshot.requiredExp;
    final objective = snapshot.isBossFight
        ? isZh
            ? '击败 Boss'
            : 'Defeat the Boss'
        : snapshot.bossSecondsRemaining <= 10
            ? isZh
                ? 'Boss 即将出现'
                : 'Boss incoming'
            : isZh
                ? 'Boss ${_formatTime(snapshot.bossSecondsRemaining)} 后出现'
                : 'Boss in ${_formatTime(snapshot.bossSecondsRemaining)}';
    final objectiveProgress = snapshot.isBossFight
        ? isZh
            ? 'Boss 战'
            : 'Boss Fight'
        : isZh
            ? '关卡路线'
            : 'Stage Route';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gameTheme.glass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gameTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  snapshot.isBossFight
                      ? Icons.warning_rounded
                      : Icons.flag_rounded,
                  color:
                      snapshot.isBossFight ? gameTheme.hot : gameTheme.accent2,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: gameTheme.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Text(
                  objective,
                  style: TextStyle(
                    color: gameTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _HudText(objectiveProgress),
                _HudText('Lv ${snapshot.level}'),
                _HudText(_formatTime(snapshot.elapsedSeconds)),
                _HudText(
                    isZh ? '金币 ${snapshot.coins}' : 'Coins ${snapshot.coins}'),
              ],
            ),
            const SizedBox(height: 8),
            _Meter(
              value: expRatio,
              color: gameTheme.accent,
              backgroundColor: const Color(0x22FFFFFF),
            ),
            if (!snapshot.isBossFight) ...[
              const SizedBox(height: 5),
              _Meter(
                value: snapshot.enemyProgress,
                color: gameTheme.accent2,
                backgroundColor: const Color(0x1AFFFFFF),
              ),
            ],
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
    final gameTheme = context.gameTheme;
    return Text(
      text,
      style: TextStyle(
        color: gameTheme.foreground,
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
