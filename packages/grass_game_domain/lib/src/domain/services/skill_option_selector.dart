import '../configs/skill_config.dart';

class SkillOptionSelector {
  const SkillOptionSelector();

  List<SkillConfig> selectOptions(
    List<SkillConfig> skills, {
    int count = 3,
    int rerollOffset = 0,
    Map<String, int> skillLevels = const {},
    Set<String> evolvedSkills = const {},
    String? ultimateSkillId,
  }) {
    final candidates = skills.where((skill) {
      return switch (skill.tier) {
        SkillTier.normal => _canSelectNormal(skill, skillLevels),
        SkillTier.evolution => _canSelectEvolution(
            skill,
            skillLevels,
            evolvedSkills,
          ),
        SkillTier.ultimate => _canSelectUltimate(
            skill,
            evolvedSkills,
            ultimateSkillId,
          ),
      };
    }).toList()
      ..sort((a, b) {
        final aWeight = _effectiveWeight(a, skillLevels);
        final bWeight = _effectiveWeight(b, skillLevels);
        final byWeight = bWeight.compareTo(aWeight);
        if (byWeight != 0) {
          return byWeight;
        }
        return a.id.compareTo(b.id);
      });

    if (candidates.length <= count) {
      return List.unmodifiable(candidates);
    }

    final rotatedCandidates = _rotateByProgress(
      candidates,
      skillLevels,
      rerollOffset,
    );
    final picked = <SkillConfig>[];
    final existingRoute = rotatedCandidates.where((skill) {
      final treeId = skill.treeId;
      return treeId != null && (skillLevels[treeId] ?? 0) > 0;
    });
    if (existingRoute.isNotEmpty) {
      picked.add(existingRoute.first);
    }

    for (final skill in rotatedCandidates) {
      if (picked.length >= count) {
        break;
      }
      if (picked.any((pickedSkill) => pickedSkill.id == skill.id)) {
        continue;
      }
      picked.add(skill);
    }

    return List.unmodifiable(picked);
  }

  bool _canSelectNormal(SkillConfig skill, Map<String, int> skillLevels) {
    final treeId = skill.treeId ?? skill.id;
    return (skillLevels[treeId] ?? 0) < skill.maxLevel;
  }

  bool _canSelectEvolution(
    SkillConfig skill,
    Map<String, int> skillLevels,
    Set<String> evolvedSkills,
  ) {
    if (evolvedSkills.contains(skill.id)) {
      return false;
    }
    final treeId = skill.treeId;
    if (treeId == null) {
      return false;
    }
    final requiredLevel = skillLevels[treeId] ?? 0;
    return requiredLevel >= 5;
  }

  bool _canSelectUltimate(
    SkillConfig skill,
    Set<String> evolvedSkills,
    String? ultimateSkillId,
  ) {
    if (ultimateSkillId != null) {
      return false;
    }
    return skill.requires.every(evolvedSkills.contains);
  }

  int _effectiveWeight(SkillConfig skill, Map<String, int> skillLevels) {
    if (skill.tier != SkillTier.normal) {
      return skill.weight;
    }
    final treeId = skill.treeId ?? skill.id;
    return (skillLevels[treeId] ?? 0) > 0 ? skill.weight + 20 : skill.weight;
  }

  List<SkillConfig> _rotateByProgress(
    List<SkillConfig> candidates,
    Map<String, int> skillLevels,
    int rerollOffset,
  ) {
    if (candidates.isEmpty) {
      return candidates;
    }
    final progress = skillLevels.values.fold<int>(0, (sum, level) {
      return sum + level;
    });
    final offset = (progress + rerollOffset) % candidates.length;
    if (offset == 0) {
      return candidates;
    }
    return [
      ...candidates.skip(offset),
      ...candidates.take(offset),
    ];
  }
}
