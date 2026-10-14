import 'dart:convert';

import '../game_models/cell.dart';
import '../game_models/game_config.dart';
import '../game_models/game_state.dart';
import '../game_models/move.dart';
import '../game_models/player.dart';

/// Serialize JSON có `schemaVersion` để nâng cấp định dạng về sau.
abstract final class GameSerializer {
  static const schemaVersion = 1;

  static Map<String, dynamic> stateToJson(GameState s) => {
        'schemaVersion': schemaVersion,
        'config': s.config.toJson(),
        'cells': [for (final c in s.cells) c.toJson()],
        'players': [for (final p in s.players) p.toJson()],
        'turnPlayer': s.turnPlayer,
        'phase': s.phase.name,
        'moveNumber': s.moveNumber,
        'history': [for (final m in s.history) m.toJson()],
        'winnerIds': s.winnerIds,
        if (s.endReason != null) 'endReason': s.endReason!.name,
      };

  static GameState stateFromJson(Map<String, dynamic> j) {
    final v = j['schemaVersion'];
    if (v != schemaVersion) {
      throw FormatException('schemaVersion không hỗ trợ: $v');
    }
    return GameState(
      config: GameConfig.fromJson(j['config'] as Map<String, dynamic>),
      cells: List.unmodifiable([
        for (final c in j['cells'] as List) Cell.fromJson(c as Map<String, dynamic>),
      ]),
      players: List.unmodifiable([
        for (final p in j['players'] as List)
          Player.fromJson(p as Map<String, dynamic>),
      ]),
      turnPlayer: j['turnPlayer'] as int,
      phase: GamePhase.values.byName(j['phase'] as String),
      moveNumber: j['moveNumber'] as int,
      history: List.unmodifiable([
        for (final m in j['history'] as List) Move.fromJson(m as Map<String, dynamic>),
      ]),
      winnerIds: (j['winnerIds'] as List).cast<int>(),
      endReason: j['endReason'] == null
          ? null
          : EndReason.values.byName(j['endReason'] as String),
    );
  }

  /// Ván lưu = trạng thái ban đầu + trạng thái hiện tại (để undo/replay).
  static String encodeSave(SavedGame g) => jsonEncode({
        'schemaVersion': schemaVersion,
        'savedAt': g.savedAt.toIso8601String(),
        'initial': stateToJson(g.initial),
        'current': stateToJson(g.current),
      });

  static SavedGame decodeSave(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['schemaVersion'] != schemaVersion) {
      throw FormatException('schemaVersion không hỗ trợ: ${j['schemaVersion']}');
    }
    return SavedGame(
      initial: stateFromJson(j['initial'] as Map<String, dynamic>),
      current: stateFromJson(j['current'] as Map<String, dynamic>),
      savedAt: DateTime.parse(j['savedAt'] as String),
    );
  }
}

class SavedGame {
  const SavedGame({
    required this.initial,
    required this.current,
    required this.savedAt,
  });
  final GameState initial;
  final GameState current;
  final DateTime savedAt;
}
