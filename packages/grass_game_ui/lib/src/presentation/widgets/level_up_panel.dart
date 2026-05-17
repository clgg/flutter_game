import 'package:flutter/material.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

class LevelUpPanel extends StatelessWidget {
  const LevelUpPanel({
    super.key,
    required this.options,
    required this.onSelected,
    this.pendingCount = 1,
    this.onRefresh,
  });

  final List<SkillConfig> options;
  final ValueChanged<SkillConfig> onSelected;
  final int pendingCount;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final strings = _LevelUpPanelStrings.of(context);
    return Material(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xF2102418),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x6649D17D)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE8FFF2),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x1A49D17D),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0x5549D17D),
                            ),
                          ),
                          child: Text(
                            strings.optionCount(options.length),
                            style: const TextStyle(
                              color: Color(0xCCBFFFE0),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 158,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < options.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _SkillCard(
                                option: options[i],
                                strings: strings,
                                onTap: () => onSelected(options[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.pendingCount(pendingCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xBFE8FFF2),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(strings.refresh),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE8FFF2),
                            side: const BorderSide(color: Color(0x6649D17D)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.option,
    required this.strings,
    required this.onTap,
  });

  final SkillConfig option;
  final _LevelUpPanelStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skillColor = _colorFor(option.id);
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF17321F),
        foregroundColor: const Color(0xFFE8FFF2),
        padding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: skillColor.withOpacity(0.72)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skillColor,
                  boxShadow: [
                    BoxShadow(
                      color: skillColor.withOpacity(0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x1AE8FFF2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  strings.skillTier(option.tier),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xCCE8FFF2),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            strings.skillTitle(option.id),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              strings.skillDescription(option.id),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xBFE8FFF2),
                fontSize: 11,
                height: 1.18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String id) {
    return switch (id) {
      'star_projectile' || 'evolve_star_barrage' => const Color(0xFF8FD7FF),
      'orbit_blade' || 'evolve_moon_wheel' => const Color(0xFFC7F7FF),
      'thunder_matrix' || 'evolve_thunder_chain' => const Color(0xFFB68CFF),
      'void_magnet' || 'evolve_black_hole' => const Color(0xFF8FE388),
      'ultimate_star_judgement' => const Color(0xFFFFD36E),
      'ultimate_black_moon' => const Color(0xFF7B61FF),
      _ => const Color(0xFF49D17D),
    };
  }
}

class _LevelUpPanelStrings {
  const _LevelUpPanelStrings(this.isZh);

  static _LevelUpPanelStrings of(BuildContext context) {
    return _LevelUpPanelStrings(
      Localizations.localeOf(context).languageCode == 'zh',
    );
  }

  final bool isZh;

  String get title => isZh ? '选择升级' : 'Level Up';
  String get refresh => isZh ? '刷新' : 'Refresh';

  String optionCount(int count) {
    return isZh ? '$count 项' : '$count options';
  }

  String pendingCount(int count) {
    return isZh ? '剩余技能点 $count' : '$count skill points left';
  }

  String skillTier(SkillTier tier) {
    return switch (tier) {
      SkillTier.normal => isZh ? '基础' : 'Base',
      SkillTier.evolution => isZh ? '进化' : 'Evo',
      SkillTier.ultimate => isZh ? '大招' : 'Ult',
    };
  }

  String skillTitle(String id) {
    if (isZh) {
      return switch (id) {
        'star_projectile' => '星矢点火',
        'orbit_blade' => '第一环刃',
        'thunder_matrix' => '雷标锁定',
        'void_magnet' => '磁核手套',
        'ice_nova' => '霜环初现',
        'fire_trail' => '火星足迹',
        'poison_spore' => '孢子落点',
        'evolve_star_barrage' => '星河连射',
        'evolve_moon_wheel' => '月轮风暴',
        'evolve_thunder_chain' => '天罚连锁',
        'evolve_black_hole' => '黑洞核心',
        'evolve_permafrost_field' => '永冻领域',
        'evolve_inferno_path' => '炼狱轨迹',
        'evolve_corrosive_plague' => '腐蚀瘟疫',
        'ultimate_star_judgement' => '星陨审判',
        'ultimate_black_moon' => '黑月坍缩',
        'ultimate_frost_inferno' => '冰火炼狱',
        _ => '技能强化',
      };
    }
    return switch (id) {
      'star_projectile' => 'Star Spark',
      'orbit_blade' => 'First Ring Blade',
      'thunder_matrix' => 'Thunder Lock',
      'void_magnet' => 'Void Magnet',
      'ice_nova' => 'Ice Nova',
      'fire_trail' => 'Fire Trail',
      'poison_spore' => 'Poison Spore',
      'evolve_star_barrage' => 'Star Barrage',
      'evolve_moon_wheel' => 'Moon Wheel Storm',
      'evolve_thunder_chain' => 'Thunder Chain',
      'evolve_black_hole' => 'Black Hole Core',
      'evolve_permafrost_field' => 'Permafrost Field',
      'evolve_inferno_path' => 'Inferno Path',
      'evolve_corrosive_plague' => 'Corrosive Plague',
      'ultimate_star_judgement' => 'Star Judgement',
      'ultimate_black_moon' => 'Black Moon Collapse',
      'ultimate_frost_inferno' => 'Frost Inferno',
      _ => 'Skill Upgrade',
    };
  }

  String skillDescription(String id) {
    if (isZh) {
      return switch (id) {
        'star_projectile' => '额外发射追踪星矢，升级后增加弹道和穿透。',
        'orbit_blade' => '召唤围绕你的能量刃，切开近身敌人。',
        'thunder_matrix' => '周期性召唤雷电，打击敌群中心。',
        'void_magnet' => '扩大拾取范围，并把拾取成长转成战斗爆发。',
        'ice_nova' => '周期释放减速冰环，被包围时拉开空间。',
        'fire_trail' => '移动时留下燃烧区域，让走位也能输出。',
        'poison_spore' => '在怪群脚下生成毒雾，持续腐蚀敌人。',
        'evolve_star_barrage' => '每 5 次攻击触发一轮扇形星矢弹幕。',
        'evolve_moon_wheel' => '环刃周期性扩张，形成切割风暴。',
        'evolve_thunder_chain' => '雷电会从厚血敌人扩散到周围敌群。',
        'evolve_black_hole' => '收集经验会生成黑洞，聚怪后爆炸。',
        'evolve_permafrost_field' => '冰环中心短暂冻结普通敌人并释放碎冰。',
        'evolve_inferno_path' => '移动轨迹变成更密集、更持久的燃烧带。',
        'evolve_corrosive_plague' => '中毒敌人死亡后扩散小毒雾。',
        'ultimate_star_judgement' => '流星与雷暴同时降临，轰击全屏敌群。',
        'ultimate_black_moon' => '黑洞拉起月轮风暴，把敌群撕裂后引爆。',
        'ultimate_frost_inferno' => '冰区与火区交替爆发，减速后爆燃怪群。',
        _ => '获得一次战斗强化。',
      };
    }
    return switch (id) {
      'star_projectile' =>
        'Fires an extra tracking star bolt with more shots and pierce after upgrades.',
      'orbit_blade' => 'Summons orbiting blades that cut nearby enemies.',
      'thunder_matrix' =>
        'Periodically calls lightning into the center of enemy groups.',
      'void_magnet' =>
        'Expands pickup range and turns growth into combat bursts.',
      'ice_nova' => 'Releases a slowing ice ring to create breathing room.',
      'fire_trail' => 'Leaves burning ground while moving.',
      'poison_spore' => 'Creates poison clouds under enemy clusters.',
      'evolve_star_barrage' => 'Every 5 attacks triggers a fan of star bolts.',
      'evolve_moon_wheel' =>
        'Ring blades expand periodically into a cutting storm.',
      'evolve_thunder_chain' =>
        'Lightning spreads from high-health enemies to nearby groups.',
      'evolve_black_hole' =>
        'Collecting EXP creates black holes that gather and explode enemies.',
      'evolve_permafrost_field' =>
        'Ice rings briefly freeze normal enemies and burst into shards.',
      'evolve_inferno_path' =>
        'Movement leaves denser and longer-lasting burning paths.',
      'evolve_corrosive_plague' =>
        'Poisoned enemies spread smaller clouds on death.',
      'ultimate_star_judgement' =>
        'Meteors and thunder strike across the whole screen.',
      'ultimate_black_moon' =>
        'Black holes pull in Moon Wheel storms before detonating.',
      'ultimate_frost_inferno' =>
        'Alternates fire and ice zones to slow and burn enemy groups.',
      _ => 'Gain one combat upgrade.',
    };
  }
}
