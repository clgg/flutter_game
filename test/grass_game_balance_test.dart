import 'package:flutter_test/flutter_test.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

void main() {
  test('default in-run growth curve supports frequent early upgrades', () {
    const config = GrassGameConfig.defaults;

    expect(config.balance.baseExpToLevelUp, 6);
    expect(_requiredExpForLevel(1), 6);
    expect(_cumulativeExpToReachLevel(10), lessThanOrEqualTo(394));
    expect(_cumulativeExpToReachLevel(16), lessThanOrEqualTo(1178));
  });

  test('default enemies use type-based experience drops', () {
    final enemies = GrassGameConfig.defaults.enemies;

    expect(enemies.firstWhere((enemy) => enemy.id == 'basic').expDrop, 2);
    expect(enemies.firstWhere((enemy) => enemy.id == 'fast').expDrop, 3);
    expect(enemies.firstWhere((enemy) => enemy.id == 'tank').expDrop, 6);
  });

  test('default stage enemy movement speeds are tuned down slightly', () {
    final enemies = {
      for (final enemy in GrassGameConfig.defaults.enemies) enemy.id: enemy,
    };

    expect(enemies['basic']?.moveSpeed, 148);
    expect(enemies['lamb']?.moveSpeed, 168);
    expect(enemies['piglet']?.moveSpeed, 133);
    expect(enemies['calf']?.moveSpeed, 153);
    expect(enemies['fast']?.moveSpeed, 198);
    expect(enemies['rooster']?.moveSpeed, 183);
    expect(enemies['turkey']?.moveSpeed, 143);
    expect(enemies['tank']?.moveSpeed, 108);
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
