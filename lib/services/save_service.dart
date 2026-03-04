import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/state/game_state.dart';

class SaveService {
  static const String _saveKey = 'game_save_v1';

  static Future<GameState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_saveKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return GameState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveState(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(state.toJson());
    await prefs.setString(_saveKey, jsonString);
  }

  static Future<void> deleteSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }
}
