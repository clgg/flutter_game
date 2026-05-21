import 'dart:async';

import 'package:flame/game.dart';
import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:grass_game_domain/grass_game_domain.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/progression/grass_game_progress_controller.dart';
import '../widgets/animated_character_sprite.dart';
import '../widgets/game_result_panel.dart';
import '../widgets/level_up_panel.dart';

class GrassGamePage extends StatefulWidget {
  const GrassGamePage({
    super.key,
    required this.progressController,
    required this.soundVolume,
    required this.vibrationIntensity,
    required this.onExit,
    required this.onUpgradeWeapon,
  });

  final GrassGameProgressController progressController;
  final double soundVolume;
  final double vibrationIntensity;
  final VoidCallback onExit;
  final VoidCallback onUpgradeWeapon;

  @override
  State<GrassGamePage> createState() => _GrassGamePageState();
}

class _GrassGamePageState extends State<GrassGamePage> {
  late GrassGameRuntimeController _controller;
  late GrassSurvivorGame _game;
  int _gameKey = 0;
  GameResult? _settledResult;
  bool _showFirstRunGuide = false;
  bool _showDeathmatchLoading = false;
  bool _deathmatchMinimumDelayDone = true;
  Timer? _deathmatchLoadingTimer;

  static const _firstRunGuideKey = 'grass_game.first_run_guide_seen';
  static const _deathmatchLoadingMinDuration = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadFirstRunGuide();
  }

  @override
  void dispose() {
    _deathmatchLoadingTimer?.cancel();
    _controller.setMoveDirection(0, 0);
    _controller.pause();
    _game.releaseRuntimeResources();
    _controller.removeListener(_handleRuntimeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _createGame() {
    final loadout = widget.progressController.currentLoadout;
    _settledResult = null;
    _deathmatchLoadingTimer?.cancel();
    _showDeathmatchLoading = loadout.stage.isDeathmatch;
    _deathmatchMinimumDelayDone = !loadout.stage.isDeathmatch;
    if (loadout.stage.isDeathmatch) {
      _deathmatchLoadingTimer = Timer(_deathmatchLoadingMinDuration, () {
        _deathmatchMinimumDelayDone = true;
        _hideDeathmatchLoadingIfReady();
      });
    }
    _controller = GrassGameRuntimeController();
    _controller.addListener(_handleRuntimeChanged);
    _game = GrassSurvivorGame(
      config: GrassGameConfig.defaults,
      controller: _controller,
      playerMaxHp: loadout.playerMaxHp,
      playerMoveSpeedMultiplier: loadout.playerMoveSpeedMultiplier,
      playerCharacterId: loadout.character.id,
      playerSpriteSheetAssetPath: loadout.playerSpriteSheetAssetPath,
      weaponDamage: loadout.weaponDamage,
      weaponCooldownMultiplier: 1,
      weaponFireIntervalSeconds: loadout.weaponFireIntervalSeconds,
      weaponKind: loadout.weapon.kind,
      weaponProjectileAssetPath: loadout.weapon.projectileAssetPath,
      weaponMuzzleFlashAssetPath: loadout.weapon.muzzleFlashAssetPath,
      weaponFireSoundAssetPath: loadout.weapon.fireSoundAssetPath,
      weaponRuntimeStats: loadout.weaponRuntimeStats,
      soundVolume: widget.soundVolume,
      vibrationIntensity: widget.vibrationIntensity,
      stageName: loadout.stage.name,
      stageChapter: loadout.stage.chapter,
      stageIndex: loadout.stage.stage,
      bossTimeSeconds: loadout.stage.bossTimeSeconds,
      bossMaxHp: 420 + loadout.stage.difficulty * 13,
      stageRewardExp: loadout.stage.rewardExp,
      stageRewardCoins: loadout.stage.rewardCoins,
      stageEnemyCount: loadout.stage.enemyCount,
      stageEnemyStrengthMultiplier: loadout.stage.enemyStrengthMultiplier,
      stageEnemyTypes: loadout.stage.enemyTypes,
      isDeathmatch: loadout.stage.isDeathmatch,
    );
  }

  void _restart() {
    _controller.removeListener(_handleRuntimeChanged);
    _game.releaseRuntimeResources();
    _controller.dispose();
    setState(() {
      _gameKey++;
      _createGame();
    });
  }

  void _nextStage() {
    if (!widget.progressController.selectNextStage()) {
      widget.onExit();
      return;
    }
    _restart();
  }

  Future<void> _loadFirstRunGuide() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || (prefs.getBool(_firstRunGuideKey) ?? false)) {
      return;
    }
    setState(() {
      _showFirstRunGuide = true;
    });
    await prefs.setBool(_firstRunGuideKey, true);
    await Future<void>.delayed(const Duration(seconds: 7));
    if (!mounted) {
      return;
    }
    setState(() {
      _showFirstRunGuide = false;
    });
  }

  void _handleRuntimeChanged() {
    _hideDeathmatchLoadingIfReady();
    final result = _controller.result;
    if (result == null || identical(result, _settledResult)) {
      return;
    }
    _settledResult = result;
    widget.progressController.applyBattleResult(result);
  }

  void _hideDeathmatchLoadingIfReady() {
    if (!_showDeathmatchLoading ||
        !_deathmatchMinimumDelayDone ||
        !_controller.state.isRunning) {
      return;
    }
    if (!mounted) {
      _showDeathmatchLoading = false;
      return;
    }
    setState(() {
      _showDeathmatchLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _game.languageCode = Localizations.localeOf(context).languageCode;
    final strings = _GrassGamePageStrings.of(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _confirmExit();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            GameWidget<GrassSurvivorGame>(
              key: ValueKey(_gameKey),
              game: _game,
            ),
            _FullScreenMovementInput(
              onChanged: (direction) {
                _controller.setMoveDirection(direction.dx, direction.dy);
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                child: _LeftRunControls(
                  controller: _controller,
                  spriteSheetAssetPath: widget.progressController
                      .selectedCharacter.gameSpriteSheetAssetPath,
                  onExit: _confirmExit,
                  onLevelUp: _game.openLevelUpChoices,
                  onUltimate: _game.triggerChargedUltimate,
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 86,
              right: 86,
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return _StageNamePill(snapshot: _controller.hud);
                  },
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 10,
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return _SpeedToggleButton(
                      isDoubleSpeed: _controller.isDoubleSpeed,
                      onPressed: _controller.toggleTimeScale,
                    );
                  },
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.levelUpOptions.isEmpty) {
                  return const SizedBox.shrink();
                }
                return LevelUpPanel(
                  options: _controller.levelUpOptions,
                  pendingCount: _controller.pendingLevelUpCount,
                  onRefresh: _game.refreshLevelUpChoices,
                  onClose: _game.closeLevelUpChoices,
                  onSelected: (option) => _game.applySkill(option.id),
                );
              },
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final result = _controller.result;
                if (result == null) {
                  return const SizedBox.shrink();
                }
                return GameResultPanel(
                  result: result,
                  onRestart: _restart,
                  onNextStage: _nextStage,
                  onExit: widget.onExit,
                  onUpgradeWeapon: widget.onUpgradeWeapon,
                  hasNextStage: widget.progressController.hasNextStage,
                );
              },
            ),
            if (_showFirstRunGuide)
              Positioned(
                left: 16,
                right: 16,
                bottom: 28,
                child: _FirstRunGuideCard(strings: strings),
              ),
            if (_showDeathmatchLoading)
              _DeathmatchLoadingPage(
                strings: strings,
                characterSpriteSheetAssetPath: widget.progressController
                    .selectedCharacter.gameSpriteSheetAssetPath,
                weaponName: widget.progressController.selectedWeapon.name,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    if (_controller.result != null) {
      widget.onExit();
      return;
    }

    final strings = _GrassGamePageStrings.of(context);
    final wasRunning = _controller.state.isRunning;
    if (wasRunning) {
      _controller.pause();
      _game.pauseEngine();
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102418),
          title: Text(
            strings.exitTitle,
            style: const TextStyle(color: Color(0xFFE8FFF2)),
          ),
          content: Text(
            strings.exitMessage,
            style: const TextStyle(color: Color(0xBFE8FFF2)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.exit),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (shouldExit == true) {
      _settleAndExit();
      return;
    }

    if (wasRunning && _controller.result == null) {
      _controller.resume();
      _game.resumeEngine();
    }
  }

  void _settleAndExit() {
    _controller.setMoveDirection(0, 0);
    _game.finishEarly();
    _game.releaseRuntimeResources();
    widget.onExit();
  }
}

class _FirstRunGuideCard extends StatelessWidget {
  const _FirstRunGuideCard({required this.strings});

  final _GrassGamePageStrings strings;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gameTheme.glass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gameTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideLine(
              icon: Icons.touch_app_rounded,
              text: strings.moveGuide,
              color: gameTheme.accent,
            ),
            const SizedBox(height: 8),
            _GuideLine(
              icon: Icons.auto_awesome_rounded,
              text: strings.upgradeGuide,
              color: gameTheme.accent2,
            ),
            const SizedBox(height: 8),
            _GuideLine(
              icon: Icons.flag_rounded,
              text: strings.bossGuide,
              color: gameTheme.hot,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeathmatchLoadingPage extends StatelessWidget {
  const _DeathmatchLoadingPage({
    required this.strings,
    required this.characterSpriteSheetAssetPath,
    required this.weaponName,
  });

  final _GrassGamePageStrings strings;
  final String characterSpriteSheetAssetPath;
  final String weaponName;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Positioned.fill(
      child: ColoredBox(
        color: gameTheme.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: gameTheme.hot,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.deathmatchLoadingMode,
                      style: TextStyle(
                        color: gameTheme.hot,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    color: gameTheme.deep,
                    shape: BoxShape.circle,
                    border: Border.all(color: gameTheme.accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: gameTheme.accent.withOpacity( 0.22),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedCharacterSprite(
                      spriteSheetAssetPath: characterSpriteSheetAssetPath,
                      size: 118,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  strings.deathmatchLoadingTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: gameTheme.foreground,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.deathmatchLoadingSubtitle(weaponName),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: gameTheme.muted,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: gameTheme.line,
                    color: gameTheme.hot,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _LoadingPill(
                      text: strings.deathmatchLoadingWeapons,
                      color: gameTheme.accent,
                    ),
                    _LoadingPill(
                      text: strings.deathmatchLoadingEnemies,
                      color: gameTheme.hot,
                    ),
                    _LoadingPill(
                      text: strings.deathmatchLoadingArena,
                      color: gameTheme.accent2,
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity( 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity( 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            color: gameTheme.foreground,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _GrassGamePageStrings {
  const _GrassGamePageStrings(this.isZh);

  static _GrassGamePageStrings of(BuildContext context) {
    return _GrassGamePageStrings(
      Localizations.localeOf(context).languageCode == 'zh',
    );
  }

  final bool isZh;

  String get exitTitle => isZh ? '退出本次作战？' : 'Exit run?';
  String get exitMessage => isZh
      ? '当前金币会立即结算。英雄经验只会在通关成功后发放。'
      : 'Current coins will be settled. Hero EXP is only awarded after a successful clear.';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get exit => isZh ? '退出' : 'Exit';
  String get moveGuide => isZh ? '在任意位置拖动来移动。' : 'Drag anywhere to move.';
  String get upgradeGuide => isZh
      ? '收集经验后，点击头像选择升级。'
      : 'Collect EXP, then tap your avatar to choose an upgrade.';
  String get bossGuide =>
      isZh ? '击败 Boss 即可完成关卡。' : 'Defeat the Boss to clear the stage.';
  String get deathmatchLoadingMode => isZh ? '死斗模式' : 'Deathmatch';
  String get deathmatchLoadingTitle => isZh ? '正在集结战场' : 'Preparing the arena';
  String deathmatchLoadingSubtitle(String weaponName) {
    return isZh
        ? '装配 $weaponName，生成怪物群和初始升级选项。'
        : 'Equipping $weaponName, spawning enemy waves, and preparing upgrades.';
  }

  String get deathmatchLoadingWeapons => isZh ? '装配武器' : 'Weapon ready';
  String get deathmatchLoadingEnemies => isZh ? '生成怪物' : 'Enemies spawning';
  String get deathmatchLoadingArena => isZh ? '加载战场' : 'Arena loading';
}

class _GuideLine extends StatelessWidget {
  const _GuideLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: gameTheme.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeedToggleButton extends StatelessWidget {
  const _SpeedToggleButton({
    required this.isDoubleSpeed,
    required this.onPressed,
  });

  final bool isDoubleSpeed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDoubleSpeed ? gameTheme.accent : gameTheme.glass,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDoubleSpeed ? Colors.transparent : gameTheme.line,
          ),
          boxShadow: [
            if (isDoubleSpeed)
              BoxShadow(
                color: gameTheme.accent.withOpacity(0.32),
                blurRadius: 10,
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flash_on_rounded,
                color: isDoubleSpeed ? gameTheme.ink : gameTheme.accent,
                size: 14,
              ),
              const SizedBox(width: 2),
              Text(
                isDoubleSpeed ? '2x' : '1x',
                style: TextStyle(
                  color: isDoubleSpeed ? gameTheme.ink : gameTheme.foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftRunControls extends StatelessWidget {
  const _LeftRunControls({
    required this.controller,
    required this.spriteSheetAssetPath,
    required this.onExit,
    required this.onLevelUp,
    required this.onUltimate,
  });

  final GrassGameRuntimeController controller;
  final String spriteSheetAssetPath;
  final VoidCallback onExit;
  final VoidCallback onLevelUp;
  final VoidCallback onUltimate;

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoundIconButton(
              icon: Icons.close_rounded,
              tooltip: isZh ? '退出' : 'Exit',
              onPressed: onExit,
            ),
            const SizedBox(height: 10),
            _BossCountdownBadge(snapshot: controller.hud),
            const SizedBox(height: 10),
            _LevelUpAvatarButton(
              spriteSheetAssetPath: spriteSheetAssetPath,
              pendingCount: controller.pendingLevelUpCount,
              onPressed: onLevelUp,
            ),
            const SizedBox(height: 10),
            _ChargedUltimateButton(
              snapshot: controller.hud,
              onPressed: onUltimate,
            ),
          ],
        );
      },
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: gameTheme.glass,
        foregroundColor: gameTheme.foreground,
        side: BorderSide(color: gameTheme.line),
        padding: EdgeInsets.zero,
        fixedSize: const Size(48, 48),
      ),
      icon: Icon(icon),
    );
  }
}

class _BossCountdownBadge extends StatelessWidget {
  const _BossCountdownBadge({required this.snapshot});

  final HudSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final isBossFight = snapshot.isBossFight;
    final color = isBossFight ? gameTheme.hot : gameTheme.accent2;
    return Tooltip(
      message: isBossFight ? 'Boss fight' : 'Boss countdown',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gameTheme.glass,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isBossFight ? Icons.warning_rounded : Icons.flag_rounded,
                color: color,
                size: 16,
              ),
              const SizedBox(height: 2),
              Text(
                isBossFight
                    ? 'BOSS'
                    : _formatCompactTime(snapshot.bossSecondsRemaining),
                style: TextStyle(
                  color: gameTheme.foreground,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCompactTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }
}

class _StageNamePill extends StatelessWidget {
  const _StageNamePill({required this.snapshot});

  final HudSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final title = isZh
        ? '第 ${snapshot.stageChapter}-${snapshot.stageIndex} 关'
        : snapshot.stageName;
    return Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gameTheme.glass,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: gameTheme.line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, color: gameTheme.accent2, size: 15),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  title,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelUpAvatarButton extends StatelessWidget {
  const _LevelUpAvatarButton({
    required this.spriteSheetAssetPath,
    required this.pendingCount,
    required this.onPressed,
  });

  final String spriteSheetAssetPath;
  final int pendingCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingCount > 0;
    final gameTheme = context.gameTheme;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    return IconButton(
      onPressed: hasPending ? onPressed : null,
      tooltip: isZh ? '升级' : 'Level up',
      style: IconButton.styleFrom(
        backgroundColor: hasPending
            ? const Color(0x33FFC857)
            : gameTheme.glass.withOpacity(0.42),
        disabledBackgroundColor: gameTheme.glass.withOpacity(0.28),
        side: BorderSide(
          color: hasPending ? const Color(0xFFFFC857) : const Color(0x3349D17D),
          width: hasPending ? 2 : 1,
        ),
        padding: EdgeInsets.zero,
        fixedSize: const Size(48, 48),
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Center(
              child: AnimatedCharacterSprite(
                spriteSheetAssetPath: spriteSheetAssetPath,
                size: 36,
              ),
            ),
          ),
          if (hasPending)
            Positioned(
              top: -8,
              right: -10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC857),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF07130D), width: 2),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    pendingCount > 5 ? '5+' : '$pendingCount',
                    style: const TextStyle(
                      color: Color(0xFF07130D),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChargedUltimateButton extends StatefulWidget {
  const _ChargedUltimateButton({
    required this.snapshot,
    required this.onPressed,
  });

  final HudSnapshot snapshot;
  final VoidCallback onPressed;

  @override
  State<_ChargedUltimateButton> createState() => _ChargedUltimateButtonState();
}

class _ChargedUltimateButtonState extends State<_ChargedUltimateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 860),
    );
    _syncGlow();
  }

  @override
  void didUpdateWidget(covariant _ChargedUltimateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncGlow();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _syncGlow() {
    if (widget.snapshot.isUltimateReady) {
      if (!_glowController.isAnimating) {
        _glowController.repeat(reverse: true);
      }
      return;
    }
    if (_glowController.isAnimating) {
      _glowController.stop();
    }
    _glowController.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final snapshot = widget.snapshot;
    final isReady = snapshot.isUltimateReady;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final chargeText =
        '${snapshot.ultimateCharge}/${snapshot.ultimateChargeRequired}';
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = isReady ? _glowController.value : 0.0;
        return Tooltip(
          message: isZh ? '大招 $chargeText' : 'Ultimate $chargeText',
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFF2A6)
                            .withOpacity(0.28 + glow * 0.32),
                        blurRadius: 10 + glow * 12,
                        spreadRadius: 1 + glow * 3,
                      ),
                    ]
                  : const [],
            ),
            child: IconButton(
              onPressed: isReady ? widget.onPressed : null,
              style: IconButton.styleFrom(
                backgroundColor: isReady
                    ? const Color(0x44FFD36E)
                    : gameTheme.glass.withOpacity(0.30),
                disabledBackgroundColor: gameTheme.glass.withOpacity(0.22),
                side: BorderSide(
                  color: isReady
                      ? const Color(0xFFFFF2A6)
                      : gameTheme.line.withOpacity(0.72),
                  width: isReady ? 2 : 1,
                ),
                padding: EdgeInsets.zero,
                fixedSize: const Size(48, 48),
              ),
              icon: CustomPaint(
                foregroundPainter: _UltimateChargeRingPainter(
                  progress: snapshot.ultimateChargeProgress,
                  color: isReady ? const Color(0xFFFFF2A6) : gameTheme.accent2,
                ),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.offline_bolt_rounded,
                        color: isReady
                            ? const Color(0xFFFFF2A6)
                            : gameTheme.foreground.withOpacity(0.55),
                        size: 19,
                      ),
                      Text(
                        chargeText,
                        style: TextStyle(
                          color: gameTheme.foreground,
                          fontSize: 9,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UltimateChargeRingPainter extends CustomPainter {
  const _UltimateChargeRingPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final trackPaint = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(2), -1.5708, 6.2832, false, trackPaint);
    canvas.drawArc(
      rect.deflate(2),
      -1.5708,
      6.2832 * progress.clamp(0, 1),
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _UltimateChargeRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _FullScreenMovementInput extends StatefulWidget {
  const _FullScreenMovementInput({
    required this.onChanged,
  });

  final ValueChanged<Offset> onChanged;

  @override
  State<_FullScreenMovementInput> createState() =>
      _FullScreenMovementInputState();
}

class _FullScreenMovementInputState extends State<_FullScreenMovementInput> {
  static const double _baseSize = 112;
  static const double _knobSize = 40;
  static const double _maxDistance = (_baseSize - _knobSize) / 2;

  Offset? _origin;
  Offset _knobOffset = Offset.zero;

  void _start(Offset position) {
    setState(() {
      _origin = position;
      _knobOffset = Offset.zero;
    });
    widget.onChanged(Offset.zero);
  }

  void _update(Offset position) {
    final origin = _origin;
    if (origin == null) {
      _start(position);
      return;
    }

    var offset = position - origin;
    if (offset.distance > _maxDistance) {
      offset = Offset.fromDirection(offset.direction, _maxDistance);
    }

    setState(() {
      _knobOffset = offset;
    });
    widget.onChanged(offset / _maxDistance);
  }

  void _end() {
    setState(() {
      _origin = null;
      _knobOffset = Offset.zero;
    });
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) => _start(details.localPosition),
        onPanUpdate: (details) => _update(details.localPosition),
        onPanEnd: (_) => _end(),
        onPanCancel: _end,
        child: CustomPaint(
          painter: _FloatingJoystickPainter(
            origin: _origin,
            knobOffset: _knobOffset,
          ),
        ),
      ),
    );
  }
}

class _FloatingJoystickPainter extends CustomPainter {
  const _FloatingJoystickPainter({
    required this.origin,
    required this.knobOffset,
  });

  final Offset? origin;
  final Offset knobOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = origin;
    if (center == null) {
      return;
    }

    final basePaint = Paint()..color = Colors.white.withOpacity(0.14);
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final knobPaint = Paint()..color = Colors.white.withOpacity(0.64);

    canvas.drawCircle(
        center, _FullScreenMovementInputState._baseSize / 2, basePaint);
    canvas.drawCircle(
      center,
      _FullScreenMovementInputState._baseSize / 2,
      borderPaint,
    );
    canvas.drawCircle(
      center + knobOffset,
      _FullScreenMovementInputState._knobSize / 2,
      knobPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FloatingJoystickPainter oldDelegate) {
    return origin != oldDelegate.origin || knobOffset != oldDelegate.knobOffset;
  }
}
