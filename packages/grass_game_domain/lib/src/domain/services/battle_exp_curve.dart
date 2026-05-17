import 'dart:math' as math;

class BattleExpCurve {
  const BattleExpCurve._();

  static const double deathmatchRequiredExpMultiplier = 1.35;

  static int requiredExpForLevel({
    required int baseExpToLevelUp,
    required int level,
    bool isDeathmatch = false,
  }) {
    final modeMultiplier = isDeathmatch ? deathmatchRequiredExpMultiplier : 1.0;
    return math.max(
      1,
      (baseExpToLevelUp * math.pow(level, 1.22) * modeMultiplier).floor(),
    );
  }

  static int cumulativeExpToReachLevel({
    required int baseExpToLevelUp,
    required int level,
    bool isDeathmatch = false,
  }) {
    var total = 0;
    for (var currentLevel = 1; currentLevel < level; currentLevel++) {
      total += requiredExpForLevel(
        baseExpToLevelUp: baseExpToLevelUp,
        level: currentLevel,
        isDeathmatch: isDeathmatch,
      );
    }
    return total;
  }
}
