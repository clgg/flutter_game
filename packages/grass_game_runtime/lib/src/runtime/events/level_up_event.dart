import 'package:grass_game_domain/grass_game_domain.dart';
import 'runtime_event.dart';

class LevelUpEvent extends RuntimeEvent {
  const LevelUpEvent({
    required this.options,
  });

  final List<SkillConfig> options;
}
