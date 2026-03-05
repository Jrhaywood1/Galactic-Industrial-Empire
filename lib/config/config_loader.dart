import 'economy_pack_loader.dart';
import '../models/config/game_config.dart';

class ConfigLoader {
  static Future<GameConfig> loadAll() async {
    final pack = await EconomyPackLoader.tryLoad();
    if (pack != null) return pack;
    return EconomyPackLoader.loadLegacyCompatible();
  }
}
