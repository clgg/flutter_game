import 'package:app_core/app_core.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

import '../mappers/game_config_mapper.dart';
import '../sources/remote_game_config_source.dart';

class GameConfigRepositoryImpl implements GameConfigRepository {
  const GameConfigRepositoryImpl({
    required RemoteGameConfigSource remoteSource,
    required GameConfigMapper mapper,
  })  : _remoteSource = remoteSource,
        _mapper = mapper;

  final RemoteGameConfigSource _remoteSource;
  final GameConfigMapper _mapper;

  @override
  Future<Result<GrassGameConfig>> loadConfig() async {
    try {
      final dto = await _remoteSource.fetchConfig();
      return Success(_mapper.toDomain(dto));
    } catch (error) {
      return Failure(
        AppError('Failed to load grass game config.', cause: error),
      );
    }
  }
}
