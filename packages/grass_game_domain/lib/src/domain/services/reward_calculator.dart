import '../entities/game_result.dart';

class RewardCalculator {
  const RewardCalculator();

  int calculateCoins(GameResult result) {
    return result.killCount + result.level * 2 + result.survivalSeconds ~/ 30;
  }
}
