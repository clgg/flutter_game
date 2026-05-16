import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:grass_game_domain/grass_game_domain.dart';
import 'package:grass_game_runtime/grass_game_runtime.dart';

import '../../application/progression/grass_game_progress_controller.dart';
import '../widgets/game_result_panel.dart';
import '../widgets/grass_game_hud.dart';
import '../widgets/level_up_panel.dart';

class GrassGamePage extends StatefulWidget {
  const GrassGamePage({
    super.key,
    required this.progressController,
    required this.onExit,
  });

  final GrassGameProgressController progressController;
  final VoidCallback onExit;

  @override
  State<GrassGamePage> createState() => _GrassGamePageState();
}

class _GrassGamePageState extends State<GrassGamePage> {
  late GrassGameRuntimeController _controller;
  late GrassSurvivorGame _game;
  int _gameKey = 0;
  GameResult? _settledResult;

  @override
  void initState() {
    super.initState();
    _createGame();
  }

  @override
  void dispose() {
    _controller.setMoveDirection(0, 0);
    _controller.pause();
    _controller.removeListener(_handleRuntimeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _createGame() {
    final loadout = widget.progressController.currentLoadout;
    _settledResult = null;
    _controller = GrassGameRuntimeController();
    _controller.addListener(_handleRuntimeChanged);
    _game = GrassSurvivorGame(
      config: GrassGameConfig.defaults,
      controller: _controller,
      playerMaxHp: loadout.playerMaxHp,
      playerMoveSpeedMultiplier: loadout.playerMoveSpeedMultiplier,
      playerSpriteSheetAssetPath: loadout.playerSpriteSheetAssetPath,
      weaponDamage: loadout.weaponDamage,
      weaponCooldownMultiplier: loadout.weaponCooldownMultiplier,
      weaponFireIntervalSeconds: loadout.weaponFireIntervalSeconds,
      weaponKind: loadout.weapon.kind,
      weaponProjectileAssetPath: null,
      weaponMuzzleFlashAssetPath: null,
      weaponFireSoundAssetPath: loadout.weapon.fireSoundAssetPath,
      bossTimeSeconds: loadout.stage.bossTimeSeconds,
      bossMaxHp: 320 + loadout.stage.difficulty * 8,
      stageRewardExp: loadout.stage.rewardExp,
      stageRewardCoins: loadout.stage.rewardCoins,
      stageEnemyCount: loadout.stage.enemyCount,
      stageEnemyStrengthMultiplier: loadout.stage.enemyStrengthMultiplier,
      stageEnemyTypes: loadout.stage.enemyTypes,
      bossSpriteSheetAssetPath: loadout.stage.bossSpriteSheetAssetPath,
      bossDeathAssetPath: loadout.stage.bossDeathAssetPath,
    );
  }

  void _restart() {
    _controller.removeListener(_handleRuntimeChanged);
    _controller.dispose();
    setState(() {
      _gameKey++;
      _createGame();
    });
  }

  void _handleRuntimeChanged() {
    final result = _controller.result;
    if (result == null || identical(result, _settledResult)) {
      return;
    }
    _settledResult = result;
    widget.progressController.applyBattleResult(result);
  }

  @override
  Widget build(BuildContext context) {
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
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return _LevelUpAvatarButton(
                      avatarAssetPath: widget
                          .progressController.selectedCharacter.avatarAssetPath,
                      pendingCount: _controller.pendingLevelUpCount,
                      onPressed: _game.openLevelUpChoices,
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 68,
              child: SafeArea(
                child: IconButton.filledTonal(
                  onPressed: _confirmExit,
                  tooltip: 'Exit',
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 124,
              right: 88,
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return GrassGameHud(snapshot: _controller.hud);
                  },
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return FilledButton.tonal(
                      onPressed: _controller.toggleTimeScale,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Text(
                        _controller.isDoubleSpeed ? '2x' : '1x',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
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
                  onExit: widget.onExit,
                );
              },
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
          title: const Text(
            'Exit run?',
            style: TextStyle(color: Color(0xFFE8FFF2)),
          ),
          content: const Text(
            'Current coins will be settled. Hero EXP is only awarded after a successful clear.',
            style: TextStyle(color: Color(0xBFE8FFF2)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
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
    widget.onExit();
  }
}

class _LevelUpAvatarButton extends StatelessWidget {
  const _LevelUpAvatarButton({
    required this.avatarAssetPath,
    required this.pendingCount,
    required this.onPressed,
  });

  final String avatarAssetPath;
  final int pendingCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingCount > 0;
    return IconButton(
      onPressed: hasPending ? onPressed : null,
      tooltip: 'Level up',
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xCC07130D),
        disabledBackgroundColor: const Color(0x9907130D),
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
            child: Image.asset(
              avatarAssetPath,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
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
