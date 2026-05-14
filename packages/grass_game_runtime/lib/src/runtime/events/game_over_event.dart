import 'package:grass_game_domain/grass_game_domain.dart';
import 'runtime_event.dart';

class GameOverEvent extends RuntimeEvent {
  const GameOverEvent({
    required this.result,
  });

  final GameResult result;
}
