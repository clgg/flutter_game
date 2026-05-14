import 'package:app_core/app_core.dart';

class LocalGameConfigCache {
  const LocalGameConfigCache(this._store);

  static const _cacheKey = 'grass_game_config';

  final KeyValueStore _store;

  Future<String?> readRawConfig() {
    return _store.readString(_cacheKey);
  }

  Future<void> writeRawConfig(String value) {
    return _store.writeString(_cacheKey, value);
  }
}
