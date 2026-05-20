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
    const heroAndSelectedPanelHeight = 260.0;
    const collapsedChapterHeight = 78.0;
    return heroAndSelectedPanelHeight + (chapter - 1) * collapsedChapterHeight;
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
                  SliverToBoxAdapter(
                    child: _SelectedStagePanel(
                      stage: activeStage,
                      strings: strings,
                      isCompleted: widget.progressController.isStageCompleted(
                        activeStage.id,
                      ),
                      isUnlocked: isUnlocked,
                      primaryButtonLabel: !_hasUserSelectedStage && isUnlocked
                          ? strings.continueLabel
                          : strings.startLabel,
                      onStart: _startActiveStage,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
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
                          selectedStageId: activeStage.id,
                          isExpanded: _expandedChapter == chapter,
                          onToggle: () => _toggleChapter(chapter),
                          onStageSelected: _selectStage,
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
    required this.selectedStageId,
    required this.isExpanded,
    required this.onToggle,
    required this.onStageSelected,
  });

  final int chapter;
  final List<GameStageDefinition> stages;
  final GrassGameProgressController progressController;
  final _StageSelectStrings strings;
  final String selectedStageId;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onStageSelected;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final completedCount = stages
        .where((stage) => progressController.isStageCompleted(stage.id))
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
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
            padding: EdgeInsets.fromLTRB(12, 12, 12, isExpanded ? 14 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                if (isExpanded) ...[
                  const SizedBox(height: 12),
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
  });

  final GameStageDefinition stage;
  final _StageSelectStrings strings;
  final bool isCompleted;
  final bool isUnlocked;
  final String primaryButtonLabel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gameTheme.deep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: gameTheme.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: isUnlocked ? onStart : null,
                    child:
                        Text(isUnlocked ? primaryButtonLabel : strings.locked),
                  ),
                ],
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
        const nodeSize = 54.0;
        const verticalGap = 76.0;
        final height = math.max(220.0, 40 + (stages.length - 1) * verticalGap);
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
    final top = 28.0;
    final bottom = size.height - 28;
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
  String get campaign => isZh ? '战役' : 'Campaign';
  String get campaignSubtitle =>
      isZh ? '通关上一关后解锁下一条路线' : 'Clear previous stages to unlock the next route';
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
        1 => '学习移动、收集经验，并击败第一只老虎 Boss。',
        2 => '快速敌人进入战场，保持移动避免被包围。',
        3 => '怪物波次更密集，武器升级开始变得重要。',
        4 => '重甲敌人会检验你的伤害和走位空间。',
        _ => '进入第二章前的第一次真正挑战。',
      };
    }
    return '清理第 ${stage.chapter * 10 + stage.stage} 波怪物，并击败${bossName(stage)}。';
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
    return types.map(enemyType).join(isZh ? ' / ' : '/');
  }

  String guaishouPool(int count) {
    return isZh ? '$count 种怪兽' : '$count guaishou';
  }

  String enemyType(String type) {
    if (!isZh) {
      return type;
    }
    return switch (type) {
      'basic' => '普通',
      'fast' => '快速',
      'tank' => '重甲',
      final id when id.startsWith('guaishou_') => '怪兽',
      _ => type,
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
      'zombie' => '丧尸',
      'skeleton' => '骷髅',
      'trex' => '霸王龙',
      'dragon' => '飞龙',
      _ => stage.bossName,
    };
  }
}
