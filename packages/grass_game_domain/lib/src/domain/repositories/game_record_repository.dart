import 'package:app_core/app_core.dart';
import '../entities/game_result.dart';

abstract interface class GameRecordRepository {
  Future<Result<void>> saveResult(GameResult result);
}
