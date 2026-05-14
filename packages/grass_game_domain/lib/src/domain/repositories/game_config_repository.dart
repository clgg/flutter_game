import 'package:app_core/app_core.dart';
import '../configs/grass_game_config.dart';

abstract interface class GameConfigRepository {
  Future<Result<GrassGameConfig>> loadConfig();
}
