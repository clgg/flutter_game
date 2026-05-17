import 'package:flutter/material.dart';
import 'package:app_core/app_core.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

class GameResultPanel extends StatelessWidget {
  const GameResultPanel({
    super.key,
    required this.result,
    required this.onRestart,
    required this.onNextStage,
    required this.onExit,
    required this.onUpgradeWeapon,
    required this.hasNextStage,
  });

  final GameResult result;
  final VoidCallback onRestart;
  final VoidCallback onNextStage;
  final VoidCallback onExit;
  final VoidCallback onUpgradeWeapon;
  final bool hasNextStage;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final strings = _GameResultStrings.of(context);
    final summary = result.isWin
        ? hasNextStage
            ? strings.nextStageUnlocked
            : strings.chapterCleared
        : strings.runEndedHint;
    return Material(
      color: Colors.black54,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: gameTheme.deep,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: gameTheme.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.isWin ? strings.victory : strings.runEnded,
                  style: TextStyle(
                    color: result.isWin ? gameTheme.accent2 : gameTheme.hot,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  strings.summary(
                    seconds: result.survivalSeconds,
                    kills: result.killCount,
                    level: result.level,
                  ),
                  style: TextStyle(
                    color: gameTheme.muted,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.rewards(
                    coins: result.coinsEarned,
                    heroExp: result.characterExpEarned,
                  ),
                  style: TextStyle(
                    color: gameTheme.accent2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                _RewardBreakdown(result: result, strings: strings),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    summary,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: gameTheme.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onExit,
                      icon: const Icon(Icons.map_rounded, size: 17),
                      label: Text(strings.back),
                    ),
                    OutlinedButton.icon(
                      onPressed: onUpgradeWeapon,
                      icon: const Icon(Icons.upgrade_rounded, size: 17),
                      label: Text(strings.upgradeWeapon),
                    ),
                    if (result.isWin && hasNextStage)
                      FilledButton.icon(
                        onPressed: onNextStage,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                        label: Text(strings.nextStage),
                      )
                    else if (!result.isWin)
                      FilledButton.icon(
                        onPressed: onRestart,
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: Text(strings.retry),
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

class _RewardBreakdown extends StatelessWidget {
  const _RewardBreakdown({
    required this.result,
    required this.strings,
  });

  final GameResult result;
  final _GameResultStrings strings;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final coinParts = [
      strings.runCoins(result.collectedCoins),
      if (result.stageCoins > 0) strings.clearCoins(result.stageCoins),
      if (result.survivalCoins > 0) strings.survivalCoins(result.survivalCoins),
    ];
    final expParts = [
      if (result.stageExp > 0) strings.stageExp(result.stageExp),
      strings.killExp(result.killExp),
      strings.levelExp(result.battleLevelExp),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        children: [
          _BreakdownLine(
            icon: Icons.paid_rounded,
            label: coinParts.join(' · '),
            color: gameTheme.accent2,
          ),
          const SizedBox(height: 5),
          _BreakdownLine(
            icon: Icons.auto_graph_rounded,
            label: expParts.join(' · '),
            color: gameTheme.accent,
          ),
        ],
      ),
    );
  }
}

class _GameResultStrings {
  const _GameResultStrings(this.isZh);

  factory _GameResultStrings.of(BuildContext context) {
    return _GameResultStrings(
      Localizations.localeOf(context).languageCode == 'zh',
    );
  }

  final bool isZh;

  String get victory => isZh ? '通关成功' : 'Victory';
  String get runEnded => isZh ? '战斗结束' : 'Run Ended';
  String get nextStageUnlocked => isZh
      ? '下一关已解锁。出发前可以先升级武器。'
      : 'Next stage unlocked. Upgrade weapons before the next run.';
  String get chapterCleared => isZh
      ? '当前路线已通关，可以使用金币升级武器。'
      : 'Chapter route cleared. Spend coins on weapon upgrades.';
  String get runEndedHint => isZh
      ? '可以升级武器，或调整路线后再次挑战。'
      : 'Upgrade weapons or retry with a safer route.';
  String get back => isZh ? '返回' : 'Back';
  String get upgradeWeapon => isZh ? '升级武器' : 'Upgrade Weapon';
  String get nextStage => isZh ? '下一关' : 'Next Stage';
  String get retry => isZh ? '重试' : 'Retry';

  String summary({
    required int seconds,
    required int kills,
    required int level,
  }) {
    return isZh
        ? '时间 ${seconds}秒  ·  击杀 $kills  ·  战斗等级 $level'
        : 'Time ${seconds}s  ·  Kills $kills  ·  Battle Lv $level';
  }

  String rewards({
    required int coins,
    required int heroExp,
  }) {
    return isZh
        ? '+$coins 金币  ·  +$heroExp 角色经验'
        : '+$coins coins  ·  +$heroExp hero EXP';
  }

  String runCoins(int value) => isZh ? '战斗 $value' : 'Run $value';
  String clearCoins(int value) => isZh ? '通关 $value' : 'Clear $value';
  String survivalCoins(int value) => isZh ? '生存 $value' : 'Survival $value';
  String stageExp(int value) => isZh ? '关卡 $value' : 'Stage $value';
  String killExp(int value) => isZh ? '击杀 $value' : 'Kills $value';
  String levelExp(int value) => isZh ? '等级 $value' : 'Level $value';
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: gameTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
