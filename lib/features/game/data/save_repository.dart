import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/persistence/game_serializer.dart';
import '../../settings/settings_controller.dart';

/// Lưu/khôi phục ván qua shared_preferences (chạy trên Android, iOS và Web).
class SaveRepository {
  SaveRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'savedGame.v${GameSerializer.schemaVersion}';

  bool get hasSave => _prefs.containsKey(_key);

  Future<void> save(SavedGame g) =>
      _prefs.setString(_key, GameSerializer.encodeSave(g));

  /// Trả `null` nếu không có hoặc dữ liệu hỏng (xóa bản hỏng).
  SavedGame? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return GameSerializer.decodeSave(raw);
    } catch (_) {
      _prefs.remove(_key);
      return null;
    }
  }

  Future<void> clear() => _prefs.remove(_key);
}

final saveRepositoryProvider = Provider<SaveRepository>(
  (ref) => SaveRepository(ref.watch(sharedPrefsProvider)),
);
