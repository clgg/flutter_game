import 'package:flutter/material.dart';

import '../../application/progression/grass_game_progress_controller.dart';

class GrassGameStageSelectPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          onBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF07130D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF07130D),
          foregroundColor: const Color(0xFFE8FFF2),
          leading: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Select Stage'),
        ),
        body: SafeArea(
          top: false,
          child: AnimatedBuilder(
            animation: progressController,
            builder: (context, _) {
              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _StageHero()),
                  SliverToBoxAdapter(
                    child: _SelectedStagePanel(
                      stage: progressController.selectedStage,
                      isCompleted: progressController.isStageCompleted(
                        progressController.selectedStage.id,
                      ),
                      onStart: onStageSelected,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        final chapter = index + 1;
                        return _ChapterSnakeSection(
                          chapter: chapter,
                          stages: progressController.stagesForChapter(chapter),
                          progressController: progressController,
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
  const _StageHero();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campaign',
            style: TextStyle(
              color: Color(0xFFE8FFF2),
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '10 chapters · select a node to preview stage rules',
            style: TextStyle(
              color: Color(0x99E8FFF2),
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
    required this.chapter,
    required this.stages,
    required this.progressController,
  });

  final int chapter;
  final List<GameStageDefinition> stages;
  final GrassGameProgressController progressController;

  @override
  Widget build(BuildContext context) {
    final reversed = chapter.isEven;
    final displayStages = reversed ? stages.reversed.toList() : stages;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF102418),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x3349D17D)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Chapter $chapter',
                    style: const TextStyle(
                      color: Color(0xFFE8FFF2),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${stages.length} stages',
                    style: const TextStyle(
                      color: Color(0x9949D17D),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final gap = stages.length <= 5 ? 14.0 : 8.0;
                  final tileSize =
                      ((constraints.maxWidth - gap * (stages.length - 1)) /
                              stages.length)
                          .clamp(40.0, 58.0);
                  return Row(
                    mainAxisAlignment: reversed
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      for (var i = 0; i < displayStages.length; i++) ...[
                        _StageNode(
                          stage: displayStages[i],
                          size: tileSize,
                          isSelected: displayStages[i].id ==
                              progressController.selectedStageId,
                          isCompleted: progressController
                              .isStageCompleted(displayStages[i].id),
                          onTap: () {
                            progressController.selectStage(displayStages[i].id);
                          },
                        ),
                        if (i != displayStages.length - 1)
                          _SnakeConnector(width: gap + 8),
                      ],
                    ],
                  );
                },
              ),
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
    required this.isCompleted,
    required this.onStart,
  });

  final GameStageDefinition stage;
  final bool isCompleted;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF102418),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x4449D17D)),
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
                          stage.name,
                          style: const TextStyle(
                            color: Color(0xFFE8FFF2),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage.description,
                          style: const TextStyle(
                            color: Color(0x99E8FFF2),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: onStart,
                    child: const Text('Start'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StageInfoChip(
                    icon: Icons.flag_rounded,
                    label: isCompleted ? 'Cleared' : 'Pending',
                  ),
                  _StageInfoChip(
                    icon: Icons.shield_rounded,
                    label: 'Boss ${stage.bossName}',
                  ),
                  _StageInfoChip(
                    icon: Icons.timer_rounded,
                    label: 'Boss ${_formatTime(stage.bossTimeSeconds)}',
                  ),
                  _StageInfoChip(
                    icon: Icons.groups_rounded,
                    label: '${stage.enemyCount} enemies',
                  ),
                  _StageInfoChip(
                    icon: Icons.bolt_rounded,
                    label: 'x${stage.enemyStrengthMultiplier}',
                  ),
                  _StageInfoChip(
                    icon: Icons.category_rounded,
                    label: stage.enemyTypes.join('/'),
                  ),
                  _StageInfoChip(
                    icon: Icons.auto_graph_rounded,
                    label: '+${stage.rewardExp} EXP',
                  ),
                  _StageInfoChip(
                    icon: Icons.paid_rounded,
                    label: '+${stage.rewardCoins}',
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1B3425),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x2249D17D)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF49D17D)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE8FFF2),
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

class _SnakeConnector extends StatelessWidget {
  const _SnakeConnector({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0x5549D17D),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.stage,
    required this.size,
    required this.isSelected,
    required this.isCompleted,
    required this.onTap,
  });

  final GameStageDefinition stage;
  final double size;
  final bool isSelected;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? const Color(0xFF49D17D)
        : isSelected
            ? const Color(0xFFFFC857)
            : const Color(0xFF263B31);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFE8FFF2)
                  : const Color(0x6649D17D),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x4449D17D),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF07130D),
                    size: 22,
                  )
                : Text(
                    '${stage.stage}',
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF07130D)
                          : const Color(0xFFE8FFF2),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
