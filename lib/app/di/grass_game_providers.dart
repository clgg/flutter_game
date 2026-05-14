import 'package:grass_game_domain/grass_game_domain.dart';
import 'package:grass_game_ui/grass_game_ui.dart';

class GrassGameProviders {
  const GrassGameProviders({
    required this.loadConfig,
    required this.startGame,
    required this.submitResult,
  });

  final LoadGrassGameConfig loadConfig;
  final StartGrassGame startGame;
  final SubmitGrassGameResult submitResult;

  factory GrassGameProviders.create({
    required GameConfigRepository configRepository,
    required GameRecordRepository recordRepository,
  }) {
    return GrassGameProviders(
      loadConfig: LoadGrassGameConfig(configRepository),
      startGame: const StartGrassGame(),
      submitResult: SubmitGrassGameResult(recordRepository),
    );
  }
}
