import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/core/engine/move_result.dart';
import 'package:o_quan_viet/core/engine/rules_engine.dart';
import 'package:o_quan_viet/core/game_models/game_config.dart';
import 'package:o_quan_viet/core/game_models/game_event.dart';
import 'package:o_quan_viet/core/game_models/game_state.dart';
import 'package:o_quan_viet/core/game_models/player.dart';
import 'package:o_quan_viet/core/persistence/game_serializer.dart';

PlayerType _typeOf(int i) {
  if (i.isOdd) return PlayerType.ai;
  return PlayerType.human;
}

void main() {
  const engine = RulesEngine();

  GameState playRandom(int n, int moves, int seed) {
    final rng = Random(seed);
    var s = engine.newGame(
      GameConfig.preset(n, seed: seed),
      players: [
        for (var i = 0; i < n; i++)
          Player(id: i, name: 'P$i', type: _typeOf(i), aiLevel: AiLevel.hard),
      ],
    );
    for (var i = 0; i < moves && !s.isOver; i++) {
      final ms = engine.getLegalMoves(s);
      s = (engine.applyMove(s, ms[rng.nextInt(ms.length)]) as MoveAccepted)
          .state;
    }
    return s;
  }

  test('round-trip GameState JSON (2/3/4 người, giữa ván và kết thúc)', () {
    for (final n in [2, 3, 4]) {
      for (final moves in [0, 7, 9999]) {
        final s = playRandom(n, moves, n * 100 + moves);
        final raw = jsonEncode(GameSerializer.stateToJson(s));
        final back = GameSerializer.stateFromJson(jsonDecode(raw));
        expect(jsonEncode(GameSerializer.stateToJson(back)), raw);
        expect(back.boardKey, s.boardKey);
        expect(back.history, s.history);
        expect(back.players, s.players);
        expect(back.config, s.config);
        expect(back.endReason, s.endReason);
      }
    }
  });

  test('SavedGame encode/decode giữ initial + current', () {
    final init = engine.newGame(GameConfig.preset(3));
    final cur = playRandom(3, 5, 1);
    final raw = GameSerializer.encodeSave(
      SavedGame(initial: init, current: cur, savedAt: DateTime.utc(2026, 1, 2)),
    );
    final g = GameSerializer.decodeSave(raw);
    expect(g.initial.boardKey, init.boardKey);
    expect(g.current.boardKey, cur.boardKey);
    expect(g.savedAt, DateTime.utc(2026, 1, 2));
  });

  test('từ chối schemaVersion lạ', () {
    final j = GameSerializer.stateToJson(engine.newGame(GameConfig.preset(2)));
    j['schemaVersion'] = 99;
    expect(() => GameSerializer.stateFromJson(j), throwsFormatException);
  });

  test('event JSON round-trip', () {
    final s = playRandom(4, 9999, 42);
    expect(s.isOver, isTrue);
    // Phát lại nước cuối để lấy events.
    final events = <GameEvent>[];
    var t = engine.newGame(
      s.config,
      players: s.players
          .map(
            (p) => p.copyWith(
              score: 0,
              active: true,
              danCaptured: 0,
              quanCaptured: 0,
              refillSpent: 0,
            ),
          )
          .toList(),
    );
    for (final m in s.history) {
      final r = engine.applyMove(t, m) as MoveAccepted;
      events.addAll(r.events);
      t = r.state;
    }
    expect(t.boardKey, s.boardKey);
    for (final e in events) {
      final back = GameEvent.fromJson(jsonDecode(jsonEncode(e.toJson())));
      expect(back.toJson(), e.toJson());
    }
    expect(events.whereType<GameOverEvent>(), hasLength(1));
  });

  test('giả định A3: giới hạn nước kết thúc ván với endReason=moveLimit', () {
    const cfg = GameConfig(
      playerCount: 2,
      ruleset: RulesetConfig(maxMovesPerPlayer: 2),
    );
    var s = engine.newGame(cfg);
    final rng = Random(3);
    while (!s.isOver) {
      final ms = engine.getLegalMoves(s);
      s = (engine.applyMove(s, ms[rng.nextInt(ms.length)]) as MoveAccepted)
          .state;
    }
    expect(s.moveNumber, lessThanOrEqualTo(4));
    if (s.moveNumber == 4) expect(s.endReason, EndReason.moveLimit);
  });
}
