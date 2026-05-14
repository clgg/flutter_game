import 'package:app_core/app_core.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

class LoadGrassGameConfig {
  const LoadGrassGameConfig(this._repository);

  final GameConfigRepository _repository;

  Future<Result<GrassGameConfig>> call() {
    return _repository.loadConfig();
  }
}
