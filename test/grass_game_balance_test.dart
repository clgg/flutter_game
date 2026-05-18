import 'package:flutter_test/flutter_test.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

void main() {
  test('default in-run growth curve supports frequent early upgrades', () {
    const config = GrassGameConfig.defaults;

    expect(config.balance.baseExpToLevelUp, 7);
    expect(_requiredExpForLevel(1), 7);
    expect(
      {
        for (final level in [5, 8, 10, 12, 14, 16, 18, 20])
          level: _cumulativeExpToReachLevel(level),
      },
      {
        5: 86,
        8: 272,
        10: 462,
        12: 708,
        14: 1012,
        16: 1377,
        18: 1804,
        20: 2295,
      },
    );
  });

  test('default enemies use type-based experience drops', () {
    final enemies = GrassGameConfig.defaults.enemies;

    expect(enemies.firstWhere((enemy) => enemy.id == 'basic').expDrop, 4);
    expect(enemies.firstWhere((enemy) => enemy.id == 'fast').expDrop, 6);
    expect(enemies.firstWhere((enemy) => enemy.id == 'tank').expDrop, 14);
  });

  test('default stage enemies expose combat stats for balance tuning', () {
    final enemies = {
      for (final enemy in GrassGameConfig.defaults.enemies) enemy.id: enemy,
    };

    expect(enemies['basic']?.hp, 12);
    expect(enemies['basic']?.moveSpeed, 132);
    expect(enemies['basic']?.meleeDamageMin, 5);
    expect(enemies['fast']?.hp, 10);
    expect(enemies['fast']?.moveSpeed, 192);
    expect(enemies['fast']?.meleeDamageMax, 8);
    expect(enemies['tank']?.hp, 56);
    expect(enemies['tank']?.moveSpeed, 88);
    expect(enemies['tank']?.meleeDamageMax, 22);
  });

  test('deathmatch uses a slower battle level curve', () {
    final baseExp = GrassGameConfig.defaults.balance.baseExpToLevelUp;
    final normalLevel10 = BattleExpCurve.cumulativeExpToReachLevel(
      baseExpToLevelUp: baseExp,
      level: 10,
    );
    final deathmatchLevel10 = BattleExpCurve.cumulativeExpToReachLevel(
      baseExpToLevelUp: baseExp,
      level: 10,
      isDeathmatch: true,
    );

    expect(
      BattleExpCurve.deathmatchRequiredExpMultiplier,
      closeTo(1.35, 0.001),
    );
    expect(
      deathmatchLevel10,
      greaterThan((normalLevel10 * 1.3).floor()),
    );
  });
}

int _requiredExpForLevel(int level) {
  return BattleExpCurve.requiredExpForLevel(
    baseExpToLevelUp: GrassGameConfig.defaults.balance.baseExpToLevelUp,
    level: level,
  );
}

int _cumulativeExpToReachLevel(int level) {
  return BattleExpCurve.cumulativeExpToReachLevel(
    baseExpToLevelUp: GrassGameConfig.defaults.balance.baseExpToLevelUp,
    level: level,
  );
}
