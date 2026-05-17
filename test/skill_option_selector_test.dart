import 'package:flutter_test/flutter_test.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

void main() {
  group('SkillOptionSelector', () {
    const selector = SkillOptionSelector();
    final skills = GrassGameConfig.defaults.skills;

    test('starts with only first-run normal skill trees', () {
      final options = selector.selectOptions(skills, count: 10);

      expect(
        options.map((skill) => skill.id),
        containsAll([
          'star_projectile',
          'orbit_blade',
          'thunder_matrix',
          'void_magnet',
        ]),
      );
      expect(options.every((skill) => skill.tier == SkillTier.normal), isTrue);
    });

    test('offers core evolution after a tree reaches level 5', () {
      final options = selector.selectOptions(
        skills,
        count: 10,
        skillLevels: const {'star_projectile': 5},
      );

      expect(
        options.map((skill) => skill.id),
        contains('evolve_star_barrage'),
      );
      expect(
        options.map((skill) => skill.id),
        isNot(contains('star_projectile')),
      );
    });

    test('includes new control and ground effect skill trees', () {
      final options = selector.selectOptions(skills, count: 20);

      expect(
        options.map((skill) => skill.id),
        containsAll(['ice_nova', 'fire_trail', 'poison_spore']),
      );
    });

    test('offers frost inferno ultimate after ice and fire evolutions', () {
      final options = selector.selectOptions(
        skills,
        count: 20,
        evolvedSkills: const {
          'evolve_permafrost_field',
          'evolve_inferno_path',
        },
      );

      expect(
        options.map((skill) => skill.id),
        contains('ultimate_frost_inferno'),
      );
    });

    test('does not offer already selected core evolution again', () {
      final options = selector.selectOptions(
        skills,
        count: 10,
        skillLevels: const {'star_projectile': 5},
        evolvedSkills: const {'evolve_star_barrage'},
      );

      expect(
        options.map((skill) => skill.id),
        isNot(contains('evolve_star_barrage')),
      );
    });

    test('offers ultimate only when its two evolutions are owned', () {
      final options = selector.selectOptions(
        skills,
        count: 10,
        evolvedSkills: const {
          'evolve_star_barrage',
          'evolve_thunder_chain',
        },
      );

      expect(
        options.map((skill) => skill.id),
        contains('ultimate_star_judgement'),
      );
      expect(
        options.map((skill) => skill.id),
        isNot(contains('ultimate_black_moon')),
      );
    });

    test('blocks every ultimate after one ultimate has been selected', () {
      final options = selector.selectOptions(
        skills,
        count: 10,
        evolvedSkills: const {
          'evolve_star_barrage',
          'evolve_thunder_chain',
          'evolve_moon_wheel',
          'evolve_black_hole',
        },
        ultimateSkillId: 'ultimate_star_judgement',
      );

      expect(options.any((skill) => skill.tier == SkillTier.ultimate), isFalse);
    });

    test('returns no options after every route is exhausted', () {
      final options = selector.selectOptions(
        skills,
        count: 10,
        skillLevels: const {
          'star_projectile': 5,
          'orbit_blade': 5,
          'thunder_matrix': 5,
          'void_magnet': 5,
          'ice_nova': 5,
          'fire_trail': 5,
          'poison_spore': 5,
        },
        evolvedSkills: const {
          'evolve_star_barrage',
          'evolve_thunder_chain',
          'evolve_moon_wheel',
          'evolve_black_hole',
          'evolve_permafrost_field',
          'evolve_inferno_path',
          'evolve_corrosive_plague',
        },
        ultimateSkillId: 'ultimate_star_judgement',
      );

      expect(options, isEmpty);
    });

    test('keeps one already owned route in three options when possible', () {
      final options = selector.selectOptions(
        skills,
        skillLevels: const {'orbit_blade': 2},
      );

      expect(options, hasLength(3));
      expect(
        options.any((skill) => skill.treeId == 'orbit_blade'),
        isTrue,
      );
    });

    test('reroll offset rotates selectable candidates', () {
      final firstOptions = selector.selectOptions(skills);
      final rerolledOptions = selector.selectOptions(skills, rerollOffset: 1);

      expect(firstOptions, hasLength(3));
      expect(rerolledOptions, hasLength(3));
      expect(
        rerolledOptions.map((skill) => skill.id).toList(),
        isNot(firstOptions.map((skill) => skill.id).toList()),
      );
    });
  });
}
