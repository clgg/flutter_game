import '../configs/skill_config.dart';

class SkillOptionSelector {
  const SkillOptionSelector();

  List<SkillConfig> selectOptions(
    List<SkillConfig> skills, {
    int count = 3,
  }) {
    if (skills.length <= count) {
      return List.unmodifiable(skills);
    }

    return List.unmodifiable(skills.take(count));
  }
}
