import 'package:app_core/app_core.dart';
import '../dto/game_config_dto.dart';

class RemoteGameConfigSource {
  const RemoteGameConfigSource(this._httpClient);

  final HttpClient _httpClient;

  Future<GameConfigDto> fetchConfig() async {
    final response = await _httpClient.get('/game/grass/config');
    return GameConfigDto.fromJson(response.body);
  }
}
