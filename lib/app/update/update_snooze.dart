import 'package:shared_preferences/shared_preferences.dart';

/// Nhớ lần bấm "Để sau": không nhắc lại cùng một bản mới trong [period].
abstract final class UpdateSnooze {
  static const key = 'update.snooze';
  static const period = Duration(days: 2);

  static Future<bool> isSnoozed(String id, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    return snoozed(prefs.getString(key), id, now ?? DateTime.now());
  }

  static Future<void> snooze(String id, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    await prefs.setString(key, '$id|$at');
  }

  /// Quyết định thuần (để test): giá trị lưu dạng `id|millis`.
  static bool snoozed(String? stored, String id, DateTime now) {
    if (stored == null) return false;
    final cut = stored.lastIndexOf('|');
    if (cut < 0 || stored.substring(0, cut) != id) return false;
    final at = int.tryParse(stored.substring(cut + 1));
    if (at == null) return false;
    final since = now.difference(DateTime.fromMillisecondsSinceEpoch(at));
    return since < period;
  }
}
