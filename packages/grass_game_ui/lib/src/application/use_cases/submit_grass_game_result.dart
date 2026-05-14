import 'package:app_core/app_core.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

class SubmitGrassGameResult {
  const SubmitGrassGameResult(this._repository);

  final GameRecordRepository _repository;

  Future<Result<void>> call(GameResult result) {
    return _repository.saveResult(result);
  }
}
