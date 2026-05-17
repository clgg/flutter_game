enum SkillTier {
  normal,
  evolution,
  ultimate,
}

class SkillConfig {
  const SkillConfig({
    required this.id,
    this.treeId,
    this.tier = SkillTier.normal,
    this.level = 1,
    required this.weight,
    required this.maxLevel,
    this.requires = const [],
    this.blocks = const [],
  });

  final String id;
  final String? treeId;
  final SkillTier tier;
  final int level;
  final int weight;
  final int maxLevel;
  final List<String> requires;
  final List<String> blocks;
}
