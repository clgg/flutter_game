import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';

import '../../application/skills/skill_guide_catalog.dart';

class GrassGameSkillGuidePage extends StatefulWidget {
  const GrassGameSkillGuidePage({super.key});

  @override
  State<GrassGameSkillGuidePage> createState() =>
      _GrassGameSkillGuidePageState();
}

class _GrassGameSkillGuidePageState extends State<GrassGameSkillGuidePage> {
  final Set<String> _expandedTreeIds = {skillGuideTrees.first.id};

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final strings = _SkillGuideStrings.of(context);
    return Scaffold(
      backgroundColor: gameTheme.background,
      appBar: AppBar(
        title: Text(strings.title),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemBuilder: (context, index) {
            final tree = skillGuideTrees[index];
            final isExpanded = _expandedTreeIds.contains(tree.id);
            return _SkillTreeSection(
              tree: tree,
              isExpanded: isExpanded,
              onToggle: () => _toggleTree(tree.id),
              onNodeTap: _showSkillDetail,
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: skillGuideTrees.length,
        ),
      ),
    );
  }

  void _toggleTree(String id) {
    setState(() {
      if (!_expandedTreeIds.add(id)) {
        _expandedTreeIds.remove(id);
      }
    });
  }

  void _showSkillDetail(SkillGuideNode node) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SkillDetailSheet(node: node),
    );
  }
}

class _SkillTreeSection extends StatelessWidget {
  const _SkillTreeSection({
    required this.tree,
    required this.isExpanded,
    required this.onToggle,
    required this.onNodeTap,
  });

  final SkillGuideTree tree;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<SkillGuideNode> onNodeTap;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gameTheme.deep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpanded ? tree.color : gameTheme.line,
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _SkillImage(
                    color: tree.color,
                    icon: _treeIcon,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tree.name,
                          style: TextStyle(
                            color: gameTheme.foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tree.role,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: gameTheme.muted,
                            fontSize: 12,
                            height: 1.25,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
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
            Divider(color: gameTheme.line, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: _SkillTree(nodes: tree.nodes, onNodeTap: onNodeTap),
            ),
          ],
        ],
      ),
    );
  }

  IconData get _treeIcon {
    return switch (tree.id) {
      'star_projectile' => Icons.auto_awesome_rounded,
      'orbit_blade' => Icons.cyclone_rounded,
      'thunder_matrix' => Icons.thunderstorm_rounded,
      'void_magnet' => Icons.lens_blur_rounded,
      _ => Icons.flare_rounded,
    };
  }
}

class _SkillTree extends StatelessWidget {
  const _SkillTree({
    required this.nodes,
    required this.onNodeTap,
  });

  final List<SkillGuideNode> nodes;
  final ValueChanged<SkillGuideNode> onNodeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < nodes.length; index++)
          _SkillTreeNodeTile(
            node: nodes[index],
            isFirst: index == 0,
            isLast: index == nodes.length - 1,
            onTap: () => onNodeTap(nodes[index]),
          ),
      ],
    );
  }
}

class _SkillTreeNodeTile extends StatelessWidget {
  const _SkillTreeNodeTile({
    required this.node,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final SkillGuideNode node;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : gameTheme.line,
                  ),
                ),
                _SkillImage(
                  color: node.color,
                  icon: node.icon,
                  size: 38,
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : gameTheme.line,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: gameTheme.panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: gameTheme.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    node.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: gameTheme.foreground,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _TierPill(tier: node.tier, color: node.color),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              node.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: gameTheme.muted,
                                fontSize: 12,
                                height: 1.25,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.info_outline_rounded,
                        color: node.color,
                        size: 20,
                      ),
                    ],
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

class _SkillImage extends StatelessWidget {
  const _SkillImage({
    required this.color,
    required this.icon,
    required this.size,
  });

  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.78), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.16),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, color: gameTheme.foreground, size: size * 0.5),
    );
  }
}

class _TierPill extends StatelessWidget {
  const _TierPill({
    required this.tier,
    required this.color,
  });

  final SkillGuideTier tier;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.48)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          _label,
          style: TextStyle(
            color: tier == SkillGuideTier.ultimate ? gameTheme.accent2 : color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  String get _label {
    return switch (tier) {
      SkillGuideTier.normal => 'Lv',
      SkillGuideTier.evolution => 'Core',
      SkillGuideTier.ultimate => 'Ult',
    };
  }
}

class _SkillDetailSheet extends StatelessWidget {
  const _SkillDetailSheet({required this.node});

  final SkillGuideNode node;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final strings = _SkillGuideStrings.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: gameTheme.deep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: node.color.withOpacity(0.6)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SkillImage(color: node.color, icon: node.icon, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.name,
                            style: TextStyle(
                              color: gameTheme.foreground,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _TierPill(tier: node.tier, color: node.color),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  node.description,
                  style: TextStyle(
                    color: gameTheme.foreground,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                _DetailBlock(
                  title: strings.requiredLevel,
                  text: node.requiredLevel,
                  color: node.color,
                ),
                const SizedBox(height: 10),
                _DetailBlock(
                  title: strings.unlock,
                  text: node.unlockCondition,
                  color: node.color,
                ),
                const SizedBox(height: 14),
                Text(
                  strings.parameters,
                  style: TextStyle(
                    color: gameTheme.foreground,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                for (final parameter in node.parameters)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.adjust_rounded,
                          size: 16,
                          color: node.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            parameter,
                            style: TextStyle(
                              color: gameTheme.muted,
                              height: 1.3,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillGuideStrings {
  const _SkillGuideStrings(this.isZh);

  factory _SkillGuideStrings.of(BuildContext context) {
    return _SkillGuideStrings(
      Localizations.localeOf(context).languageCode == 'zh',
    );
  }

  final bool isZh;

  String get title => isZh ? '技能图鉴' : 'Skill Guide';
  String get requiredLevel => isZh ? '需要等级' : 'Required Level';
  String get unlock => isZh ? '解锁条件' : 'Unlock';
  String get parameters => isZh ? '技能参数' : 'Parameters';
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.title,
    required this.text,
    required this.color,
  });

  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.36)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              text,
              style: TextStyle(
                color: gameTheme.foreground,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
