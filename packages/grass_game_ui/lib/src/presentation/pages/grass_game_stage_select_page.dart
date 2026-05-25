import 'dart:math' as math;

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';

import '../../application/progression/grass_game_progress_controller.dart';

class GrassGameStageSelectPage extends StatefulWidget {
  const GrassGameStageSelectPage({
    super.key,
    required this.progressController,
    required this.onBack,
    required this.onStageSelected,
  });

  final GrassGameProgressController progressController;
  final VoidCallback onBack;
  final VoidCallback onStageSelected;

  @override
  State<GrassGameStageSelectPage> createState() =>
      _GrassGameStageSelectPageState();
}

class _GrassGameStageSelectPageState extends State<GrassGameStageSelectPage> {
  String? _activeStageId;
  int? _expandedChapter;
  bool _hasUserSelectedStage = false;
  late final ScrollController _scrollController;
  final Map<int, GlobalKey> _chapterKeys = {
    for (var chapter = 1; chapter <= 10; chapter++) chapter: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _activeStageId = _defaultContinueStageId();
    _expandedChapter = _activeStage().chapter;
    _scrollController = ScrollController(
      initialScrollOffset: _estimatedChapterScrollOffset(_expandedChapter),
    );
    _scrollToExpandedChapter();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GrassGameStageSelectPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressController != widget.progressController) {
      _activeStageId = _defaultContinueStageId();
      _expandedChapter = _activeStage().chapter;
      _hasUserSelectedStage = false;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _estimatedChapterScrollOffset(_expandedChapter),
        );
      }
      _scrollToExpandedChapter();
    }
  }

  double _estimatedChapterScrollOffset(int? chapter) {
    if (chapter == null || chapter <= 1) {
      return 0;
    }
    const heroHeight = 88.0;
    const collapsedChapterHeight = 70.0;
    return heroHeight + (chapter - 1) * collapsedChapterHeight;
  }

  String _defaultContinueStageId() {
    for (final stage in _campaignStages()) {
      if (!widget.progressController.isStageCompleted(stage.id) &&
          widget.progressController.canSelectStage(stage.id)) {
        return stage.id;
      }
    }
    return _campaignStages().first.id;
  }

  GameStageDefinition _activeStage() {
    final activeStageId = _activeStageId;
    if (activeStageId == null) {
      return _fallbackCampaignStage();
    }
    return _campaignStages().firstWhere(
      (stage) => stage.id == activeStageId,
      orElse: _fallbackCampaignStage,
    );
  }

  void _selectStage(String stageId) {
    if (!widget.progressController.canSelectStage(stageId)) {
      return;
    }
    final stage = _stageById(stageId);
    setState(() {
      _activeStageId = stageId;
      _expandedChapter = stage.chapter;
      _hasUserSelectedStage = true;
    });
    widget.progressController.selectStage(stageId);
  }

  GameStageDefinition _stageById(String stageId) {
    return _campaignStages().firstWhere(
      (stage) => stage.id == stageId,
      orElse: _fallbackCampaignStage,
    );
  }

  List<GameStageDefinition> _campaignStages() {
    return widget.progressController.stages
        .where((stage) => !stage.isDeathmatch)
        .toList(growable: false);
  }

  GameStageDefinition _fallbackCampaignStage() {
    final selectedStage = widget.progressController.selectedStage;
    if (!selectedStage.isDeathmatch) {
      return selectedStage;
    }
    return _campaignStages().first;
  }

  void _toggleChapter(int chapter) {
    final stages = widget.progressController.stagesForChapter(chapter);
    if (stages.isEmpty) {
      return;
    }
    final nextStage = _preferredStageInChapter(stages);
    setState(() {
      _expandedChapter = chapter;
      _activeStageId = nextStage.id;
      _hasUserSelectedStage = true;
    });
    if (widget.progressController.canSelectStage(nextStage.id)) {
      widget.progressController.selectStage(nextStage.id);
    }
  }

  void _scrollToExpandedChapter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final chapter = _expandedChapter;
      if (chapter == null || chapter <= 1) {
        return;
      }
      final context = _chapterKeys[chapter]?.currentContext;
      if (context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        alignment: 0.08,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  GameStageDefinition _preferredStageInChapter(
      List<GameStageDefinition> stages) {
    for (final stage in stages) {
      if (!widget.progressController.isStageCompleted(stage.id) &&
          widget.progressController.canSelectStage(stage.id)) {
        return stage;
      }
    }
    for (final stage in stages) {
      if (widget.progressController.canSelectStage(stage.id)) {
        return stage;
      }
    }
    return stages.first;
  }

  void _startActiveStage() {
    final stage = _activeStage();
    if (!widget.progressController.canSelectStage(stage.id)) {
      return;
    }
    widget.progressController.selectStage(stage.id);
    widget.onStageSelected();
  }

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final strings = _StageSelectStrings.of(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          widget.onBack();
        }
      },
      child: Scaffold(
        backgroundColor: gameTheme.background,
        appBar: AppBar(
          leading: IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(strings.selectStage),
        ),
        body: SafeArea(
          top: false,
          child: AnimatedBuilder(
            animation: widget.progressController,
            builder: (context, _) {
              final activeStage = _activeStage();
              final isUnlocked =
                  widget.progressController.canSelectStage(activeStage.id);
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: _StageHero(strings: strings)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        final chapter = index + 1;
                        return _ChapterSnakeSection(
                          key: _chapterKeys[chapter],
                          chapter: chapter,
                          stages: widget.progressController
                              .stagesForChapter(chapter),
                          progressController: widget.progressController,
                          strings: strings,
                          activeStage: activeStage,
                          selectedStageId: activeStage.id,
                          isExpanded: _expandedChapter == chapter,
                          activeStageCompleted:
                              widget.progressController.isStageCompleted(
                            activeStage.id,
                          ),
                          activeStageUnlocked: isUnlocked,
                          primaryButtonLabel:
                              !_hasUserSelectedStage && isUnlocked
                                  ? strings.continueLabel
                                  : strings.startLabel,
                          onToggle: () => _toggleChapter(chapter),
                          onStageSelected: _selectStage,
                          onStart: _startActiveStage,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StageHero extends StatelessWidget {
  const _StageHero({required this.strings});

  final _StageSelectStrings strings;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.campaign,
            style: TextStyle(
              color: gameTheme.foreground,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 8),
          Text(
            strings.campaignSubtitle,
            style: TextStyle(
              color: gameTheme.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterSnakeSection extends StatelessWidget {
  const _ChapterSnakeSection({
    super.key,
    required this.chapter,
    required this.stages,
    required this.progressController,
    required this.strings,
    required this.activeStage,
    required this.selectedStageId,
    required this.isExpanded,
    required this.activeStageCompleted,
    required this.activeStageUnlocked,
    required this.primaryButtonLabel,
    required this.onToggle,
    required this.onStageSelected,
    required this.onStart,
  });

  final int chapter;
  final List<GameStageDefinition> stages;
  final GrassGameProgressController progressController;
  final _StageSelectStrings strings;
  final GameStageDefinition activeStage;
  final String selectedStageId;
  final bool isExpanded;
  final bool activeStageCompleted;
  final bool activeStageUnlocked;
  final String primaryButtonLabel;
  final VoidCallback onToggle;
  final ValueChanged<String> onStageSelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final completedCount = stages
        .where((stage) => progressController.isStageCompleted(stage.id))
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gameTheme.deep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isExpanded ? gameTheme.accent : gameTheme.line,
            width: isExpanded ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, isExpanded ? 12 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        strings.chapter(chapter),
                        style: TextStyle(
                          color: gameTheme.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        strings.clearedProgress(completedCount, stages.length),
                        style: TextStyle(
                          color: gameTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: gameTheme.foreground,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 10),
                _SelectedStagePanel(
                  stage: activeStage,
                  strings: strings,
                  isCompleted: activeStageCompleted,
                  isUnlocked: activeStageUnlocked,
                  primaryButtonLabel: primaryButtonLabel,
                  onStart: onStart,
                  isEmbedded: true,
                ),
                const SizedBox(height: 10),
                _StageSnakeMap(
                  chapter: chapter,
                  stages: stages,
                  progressController: progressController,
                  selectedStageId: selectedStageId,
                  onStageSelected: onStageSelected,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedStagePanel extends StatelessWidget {
  const _SelectedStagePanel({
    required this.stage,
    required this.strings,
    required this.isCompleted,
    required this.isUnlocked,
    required this.primaryButtonLabel,
    required this.onStart,
    this.isEmbedded = false,
  });

  final GameStageDefinition stage;
  final _StageSelectStrings strings;
  final bool isCompleted;
  final bool isUnlocked;
  final String primaryButtonLabel;
  final VoidCallback onStart;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Padding(
      padding: isEmbedded
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isEmbedded ? gameTheme.panel : gameTheme.deep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: gameTheme.line),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, isEmbedded ? 12 : 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StageSceneImage(
                stage: stage,
                strings: strings,
                isCompleted: isCompleted,
                isUnlocked: isUnlocked,
              ),
              const SizedBox(height: 12),
              Text(
                strings.stageName(stage),
                style: TextStyle(
                  color: gameTheme.foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.stageDescription(stage),
                style: TextStyle(
                  color: gameTheme.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isUnlocked ? onStart : null,
                  icon: Icon(
                    isUnlocked ? Icons.play_arrow_rounded : Icons.lock_rounded,
                  ),
                  label: Text(
                    isUnlocked ? primaryButtonLabel : strings.locked,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StageInfoChip(
                    icon: isUnlocked ? Icons.flag_rounded : Icons.lock_rounded,
                    label: isCompleted
                        ? strings.cleared
                        : isUnlocked
                            ? strings.pending
                            : strings.locked,
                  ),
                  _StageInfoChip(
                    icon: Icons.landscape_rounded,
                    label: strings.themeName(stage),
                  ),
                  _StageInfoChip(
                    icon: stage.isDeathmatch
                        ? Icons.all_inclusive_rounded
                        : Icons.shield_rounded,
                    label: stage.isDeathmatch
                        ? strings.deathmatchMode
                        : strings.boss(stage),
                  ),
                  _StageInfoChip(
                    icon: stage.isDeathmatch
                        ? Icons.trending_up_rounded
                        : Icons.timer_rounded,
                    label: stage.isDeathmatch
                        ? strings.deathmatchScaling
                        : strings.bossTime(_formatTime(stage.bossTimeSeconds)),
                  ),
                  _StageInfoChip(
                    icon: Icons.groups_rounded,
                    label: stage.isDeathmatch
                        ? strings.endlessEnemies
                        : strings.enemyCount(stage.enemyCount),
                  ),
                  _StageInfoChip(
                    icon: Icons.bolt_rounded,
                    label: strings.strength(stage.enemyStrengthMultiplier),
                  ),
                  _StageInfoChip(
                    icon: Icons.category_rounded,
                    label: stage.isDeathmatch
                        ? strings.guaishouPool(stage.enemyTypes.length)
                        : strings.enemyTypes(stage.enemyTypes),
                  ),
                  _StageInfoChip(
                    icon: Icons.auto_graph_rounded,
                    label: stage.isDeathmatch
                        ? strings.mediumPlusRewards
                        : strings.rewardExp(stage.rewardExp),
                  ),
                  if (!stage.isDeathmatch)
                    _StageInfoChip(
                      icon: Icons.paid_rounded,
                      label: strings.rewardCoins(stage.rewardCoins),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remain = seconds % 60;
    return '$minutes:${remain.toString().padLeft(2, '0')}';
  }
}

class _StageSceneImage extends StatelessWidget {
  const _StageSceneImage({
    required this.stage,
    required this.strings,
    required this.isCompleted,
    required this.isUnlocked,
  });

  final GameStageDefinition stage;
  final _StageSelectStrings strings;
  final bool isCompleted;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              stage.sceneAssetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gameTheme.panel, gameTheme.deep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.62),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: _StageOverlayPill(
                icon: Icons.public_rounded,
                label: strings.themeName(stage),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: _StageOverlayPill(
                icon: isCompleted
                    ? Icons.check_rounded
                    : isUnlocked
                        ? Icons.flag_rounded
                        : Icons.lock_rounded,
                label: isCompleted
                    ? strings.cleared
                    : isUnlocked
                        ? strings.pending
                        : strings.locked,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageOverlayPill extends StatelessWidget {
  const _StageOverlayPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.48),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageInfoChip extends StatelessWidget {
  const _StageInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gameTheme.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gameTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: gameTheme.accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: gameTheme.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageSnakeMap extends StatelessWidget {
  const _StageSnakeMap({
    required this.chapter,
    required this.stages,
    required this.progressController,
    required this.selectedStageId,
    required this.onStageSelected,
  });

  final int chapter;
  final List<GameStageDefinition> stages;
  final GrassGameProgressController progressController;
  final String selectedStageId;
  final ValueChanged<String> onStageSelected;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const nodeSize = 48.0;
        const verticalGap = 50.0;
        final height = math.max(164.0, 36 + (stages.length - 1) * verticalGap);
        final centers = _buildCenters(
          size: Size(constraints.maxWidth, height),
          nodeSize: nodeSize,
        );
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SnakePathPainter(
                    points: centers,
                    color: gameTheme.accent.withOpacity(0.38),
                    glowColor: gameTheme.accent2.withOpacity(0.18),
                  ),
                ),
              ),
              for (var i = 0; i < stages.length; i++)
                Positioned(
                  left: centers[i].dx - nodeSize / 2,
                  top: centers[i].dy - nodeSize / 2,
                  child: _StageNode(
                    stage: stages[i],
                    size: nodeSize,
                    isSelected: stages[i].id == selectedStageId,
                    isCompleted:
                        progressController.isStageCompleted(stages[i].id),
                    isUnlocked: progressController.canSelectStage(stages[i].id),
                    onTap: () {
                      onStageSelected(stages[i].id);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Offset> _buildCenters({
    required Size size,
    required double nodeSize,
  }) {
    if (stages.length == 1) {
      return [Offset(size.width / 2, size.height / 2)];
    }

    final amplitude = math.max(0.0, (size.width - nodeSize - 42) / 2);
    final centerX = size.width / 2;
    final top = 24.0;
    final bottom = size.height - 24;
    final startSign = chapter.isEven ? 1.0 : -1.0;
    return [
      for (var i = 0; i < stages.length; i++)
        Offset(
          centerX +
              math.sin((i / (stages.length - 1)) * math.pi * 2 - math.pi / 2) *
                  amplitude *
                  startSign,
          top + (bottom - top) * i / (stages.length - 1),
        ),
    ];
  }
}

class _SnakePathPainter extends CustomPainter {
  const _SnakePathPainter({
    required this.points,
    required this.color,
    required this.glowColor,
  });

  final List<Offset> points;
  final Color color;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final dy = next.dy - current.dy;
      path.cubicTo(
        current.dx,
        current.dy + dy * 0.58,
        next.dx,
        next.dy - dy * 0.58,
        next.dx,
        next.dy,
      );
    }

    canvas
      ..drawPath(
        path,
        Paint()
          ..color = glowColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 14,
      )
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4,
      );
  }

  @override
  bool shouldRepaint(covariant _SnakePathPainter oldDelegate) {
    return points != oldDelegate.points ||
        color != oldDelegate.color ||
        glowColor != oldDelegate.glowColor;
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.stage,
    required this.size,
    required this.isSelected,
    required this.isCompleted,
    required this.isUnlocked,
    required this.onTap,
  });

  final GameStageDefinition stage;
  final double size;
  final bool isSelected;
  final bool isCompleted;
  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final color = isCompleted
        ? gameTheme.accent
        : isSelected
            ? gameTheme.accent2
            : isUnlocked
                ? gameTheme.panel
                : gameTheme.line;
    return InkWell(
      onTap: isUnlocked ? onTap : null,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isSelected ? gameTheme.foreground : gameTheme.line,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: gameTheme.accent.withOpacity(0.28),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check_rounded,
                    color: gameTheme.ink,
                    size: 22,
                  )
                : isUnlocked
                    ? Text(
                        '${stage.stage}',
                        style: TextStyle(
                          color:
                              isSelected ? gameTheme.ink : gameTheme.foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      )
                    : Icon(
                        Icons.lock_rounded,
                        color: gameTheme.muted,
                        size: 17,
                      ),
          ),
        ),
      ),
    );
  }
}

class _StageSelectStrings {
  const _StageSelectStrings(this.isZh);

  factory _StageSelectStrings.of(BuildContext context) {
    return _StageSelectStrings(
      Localizations.localeOf(context).languageCode == 'zh',
    );
  }

  final bool isZh;

  String get selectStage => isZh ? '选择关卡' : 'Select Stage';
  String get campaign => isZh ? '末日生存战役' : 'Survival Campaign';
  String get campaignSubtitle => isZh
      ? '农场、公路、城市一路推进到宇宙裂隙，通关上一关后解锁下一条路线'
      : 'Push from the farm to the cosmic rift. Clear previous stages to unlock the next route';
  String get continueLabel => isZh ? '继续' : 'Continue';
  String get startLabel => isZh ? '开始' : 'Start';
  String get locked => isZh ? '未解锁' : 'Locked';
  String get cleared => isZh ? '已通关' : 'Cleared';
  String get pending => isZh ? '待挑战' : 'Pending';

  String chapter(int chapter) {
    if (chapter == 11) {
      return isZh ? '特殊模式' : 'Special Mode';
    }
    return isZh ? '第 $chapter 章' : 'Chapter $chapter';
  }

  String clearedProgress(int completed, int total) {
    return isZh ? '已通关 $completed/$total' : '$completed/$total cleared';
  }

  String stageName(GameStageDefinition stage) {
    if (stage.isDeathmatch) {
      return isZh ? '死斗模式' : 'Deathmatch';
    }
    return isZh
        ? '第 ${stage.chapter}-${stage.stage} 关'
        : 'Chapter ${stage.chapter}-${stage.stage}';
  }

  String stageDescription(GameStageDefinition stage) {
    if (stage.isDeathmatch) {
      return isZh ? '无尽近战生存，怪兽会持续增多，并每分钟强化。' : stage.description;
    }
    if (!isZh) {
      return stage.description;
    }
    if (stage.chapter == 1) {
      return switch (stage.stage) {
        1 => '农场围栏已经倒下，清理第一批变异动物，守住谷仓灯光。',
        2 => '泥地里出现更快的脚印，变异体开始沿玉米地包抄。',
        3 => '水井被污染，边收集结晶样本边守住院落。',
        4 => '重型变异兽撞开筒仓防线，走位空间会被持续压缩。',
        _ => '摧毁农场巢穴，否则感染会扩散到公路。',
      };
    }
    return switch (stage.chapter) {
      2 => switch (stage.stage) {
          1 => '抵达第一道公路路障，从废车堆里打开通道。',
          2 => '燃油泄漏把公路切成窄道，快速怪会从车缝包抄。',
          3 => '护送信号信标穿过废弃巴士车队。',
          4 => '在高架桥咽喉点顶住重甲公路兽。',
          _ => '炸开油罐巢穴，进入城市外围。',
        },
      3 => switch (stage.stage) {
          1 => '搜索城市外街，每一次枪声都会引来巷道里的变异体。',
          2 => '重启应急电网，否则街区会被彻底封死。',
          3 => '穿过市场废墟，躲过楼顶和地铁口的夹击。',
          4 => '重甲怪聚集在地铁入口，必须打出足够清场能力。',
          _ => '击败城市核心守卫，拿到撤离密码。',
        },
      4 => switch (stage.stage) {
          1 => '进入洞穴入口，先抢下第一条照明链路。',
          2 => '晶尘会干扰视野，侧洞里的钻地怪开始突袭。',
          3 => '破坏黏液喷口，防止低层路线被污染淹没。',
          4 => '在狭窄石桥上顶住厚壳变异体。',
          _ => '击穿地下变异室，带着样本爬回地面。',
        },
      5 => switch (stage.stage) {
          1 => '进入孢子森林，先从扭曲树根里切出一条路。',
          2 => '发光孢子会吸引快速野兽从两翼靠近。',
          3 => '烧穿护林站，夺回补给和导航图。',
          4 => '古树根系把战场切成多个危险口袋。',
          _ => '摧毁森林心脏，阻止孢子扩散到海岸。',
        },
      6 => switch (stage.stage) {
          1 => '守住断裂码头，毒潮会把海兽推上海岸。',
          2 => '被感染的海洋生物沿着积水公路涌入。',
          3 => '从搁浅船坞中回收求救信标。',
          4 => '在灯塔底部对抗重甲海岸兽。',
          _ => '击沉海洋巢穴，追踪下一段异常信号。',
        },
      7 => switch (stage.stage) {
          1 => '进入封锁区，先压制第一批感染者。',
          2 => '医院帐篷坍塌，感染群会从雾里围住街道。',
          3 => '保护疫苗箱，警报声会持续吸引更多敌人。',
          4 => '穿过救护车残骸和狭窄急救通道。',
          _ => '净化封锁指挥中心，否则死区会继续扩张。',
        },
      8 => switch (stage.stage) {
          1 => '穿越白骨荒原，沉睡的残骸开始重新组合。',
          2 => '蓝色鬼火标出危险窄道，骷髅怪会顺着路线冲锋。',
          3 => '在地面裂开前夺回遗物碎片。',
          4 => '重甲骷髅兽守住废弃祭坛入口。',
          _ => '粉碎白骨祭坛，停止无尽重组。',
        },
      9 => switch (stage.stage) {
          1 => '调查第一枚外星舱，清理侦察群。',
          2 => '异常重力扭曲基地路线，雷达残骸会变成掩体。',
          3 => '关闭信标塔，阻止更多入侵者降落。',
          4 => '外星装甲单位从机库废墟推进。',
          _ => '摧毁登陆核心，打开最后的宇宙裂隙路线。',
        },
      _ => switch (stage.stage) {
          1 => '登上破碎轨道平台，天空正在被撕开。',
          2 => '宇宙风暴把战场切成不断变化的危险路线。',
          3 => '切开缠绕空间站主轴的外星生物质。',
          4 => '守住反应堆环，终局变异体会集中压上来。',
          _ => '击破宇宙裂隙核心，决定世界是否还能幸存。',
        },
    };
  }

  String boss(GameStageDefinition stage) {
    return isZh ? 'Boss ${bossName(stage)}' : 'Boss ${stage.bossName}';
  }

  String bossTime(String time) {
    return isZh ? 'Boss $time 出现' : 'Boss $time';
  }

  String enemyCount(int count) {
    return isZh ? '$count 个敌人' : '$count enemies';
  }

  String strength(double value) {
    return isZh ? '强度 x$value' : 'x$value';
  }

  String enemyTypes(List<String> types) {
    final labels = <String>[];
    for (final type in types) {
      final label = enemyType(type);
      if (!labels.contains(label)) {
        labels.add(label);
      }
    }
    return labels.join(isZh ? ' / ' : '/');
  }

  String guaishouPool(int count) {
    return isZh ? '$count 种怪兽' : '$count guaishou';
  }

  String enemyType(String type) {
    return switch (type) {
      'basic' ||
      'chick' ||
      'lamb' ||
      'piglet' ||
      'sheep' =>
        isZh ? '普通' : 'basic',
      'fast' || 'calf' || 'rooster' || 'dog' => isZh ? '快速' : 'fast',
      'tank' || 'turkey' || 'bull' => isZh ? '重甲' : 'tank',
      final id when id.startsWith('guaishou_') => isZh ? '怪兽' : 'guaishou',
      _ => type,
    };
  }

  String themeName(GameStageDefinition stage) {
    if (!isZh) {
      return stage.themeName;
    }
    return switch (stage.themeId) {
      'farm' => '感染农场',
      'highway' => '废弃公路',
      'city' => '沦陷城市',
      'cave' => '变异洞穴',
      'forest' => '孢子森林',
      'ocean' => '污染海岸',
      'infected' => '丧尸封锁区',
      'skeleton' => '白骨荒原',
      'alien' => '外星登陆点',
      'cosmos' || 'deathmatch' => '宇宙裂隙',
      'mixed_guaishou' => '变异爆发',
      _ => stage.themeName,
    };
  }

  String get deathmatchMode => isZh ? '无尽死斗' : 'Endless deathmatch';

  String get deathmatchScaling =>
      isZh ? '每分钟强化，9-10 分钟体型 +50%' : 'Buffs every minute, +50% size at 9-10m';

  String get endlessEnemies => isZh ? '怪兽无限刷新' : 'Endless enemies';

  String get mediumPlusRewards => isZh ? '中级以上掉落' : 'Medium+ drops';

  String rewardExp(int value) {
    return isZh ? '+$value 经验' : '+$value EXP';
  }

  String rewardCoins(int value) {
    return isZh ? '+$value 金币' : '+$value';
  }

  String bossName(GameStageDefinition stage) {
    if (!isZh) {
      return stage.bossName;
    }
    return switch (stage.bossId) {
      'tiger' => '老虎',
      'crocodile' => '鳄鱼',
      'guaishou_cyber_crocodile_boss' => '机械鳄鱼',
      'guaishou_highway_juggernaut_boss' => '公路机甲',
      'guaishou_city_core_guardian_boss' => '城市核心守卫',
      'guaishou_cave_crystal_brute_boss' => '晶洞巨兽',
      'guaishou_forest_spore_titan_boss' => '孢子森林泰坦',
      'guaishou_ocean_shell_leviathan_boss' => '甲壳海兽',
      'guaishou_infected_plague_beetle_boss' => '疫化甲虫',
      'guaishou_bone_wasteland_reaper_boss' => '白骨荒原收割者',
      'guaishou_alien_landing_overlord_boss' => '异星登陆霸主',
      'guaishou_cosmic_rift_dragon_boss' => '宇宙裂隙龙',
      'random_guaishou' => '变异怪兽',
      'zombie' => '丧尸',
      'skeleton' => '骷髅',
      'trex' => '霸王龙',
      'dragon' => '飞龙',
      _ => stage.bossName,
    };
  }
}
