import 'package:app_core/app_core.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

class GameRecordRepositoryImpl implements GameRecordRepository {
  const GameRecordRepositoryImpl();

  @override
  Future<Result<void>> saveResult(GameResult result) async {
    return const Success(null);
  }
}
