import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/core/ai/ai_player.dart';
import 'package:o_quan_viet/core/engine/move_result.dart';
import 'package:o_quan_viet/core/engine/rules_engine.dart';
import 'package:o_quan_viet/core/game_models/game_config.dart';
import 'package:o_quan_viet/core/game_models/game_state.dart';
import 'package:o_quan_viet/core/game_models/player.dart';

void main() {
  const engine = RulesEngine();

  test('bot luôn tạo nước hợp lệ cho 2/3/4 người, mọi mức độ, và ván kết thúc', () {
    for (final n in [2, 3, 4]) {
      for (final level in AiLevel.values) {
        final ai = AiPlayer();
        var s = engine.newGame(GameConfig.preset(n, seed: n));
        while (!s.isOver) {
          final m = ai.chooseMove(s, level: level);
          expect(engine.validate(s, m), isNull, reason: '$m phải hợp lệ');
          s = (engine.applyMove(s, m) as MoveAccepted).state;
        }
        expect(s.winnerIds, isNotEmpty);
      }
    }
  });

  test('Hard tôn trọng time budget (không đứng)', () {
    for (final n in [2, 3, 4]) {
      final s = engine.newGame(GameConfig.preset(n));
      final sw = Stopwatch()..start();
      AiPlayer().chooseMove(s, level: AiLevel.hard);
      expect(sw.elapsedMilliseconds, lessThan(1500));
    }
  });

  test('deterministic với seed và độ sâu cố định', () {
    const fixed = AiSettings(maxDepth: 3, budget: Duration(seconds: 30));
    final s = engine.newGame(GameConfig.preset(3, seed: 9));
    final a = AiPlayer().chooseMove(s, settings: fixed, seed: 1);
    final b = AiPlayer().chooseMove(s, settings: fixed, seed: 1);
    expect(a, b);
  });

  test('2 người: Medium thắng bot ngẫu nhiên đa số ván', () {
    var wins = 0;
    const games = 20;
    for (var g = 0; g < games; g++) {
      final rng = Random(g);
      var s = engine.newGame(GameConfig.preset(2, seed: g));
      final aiSide = g % 2;
      final ai = AiPlayer();
      while (!s.isOver) {
        final moves = engine.getLegalMoves(s);
        final m = s.turnPlayer == aiSide
            ? ai.chooseMove(s, level: AiLevel.medium)
            : moves[rng.nextInt(moves.length)];
        s = (engine.applyMove(s, m) as MoveAccepted).state;
      }
      if (s.winnerIds.length == 1 && s.winnerIds.first == aiSide) wins++;
    }
    expect(wins, greaterThanOrEqualTo(games * 0.7));
  });

  test('chỉ một nước hợp lệ → trả ngay', () {
    final base = engine.newGame(GameConfig.preset(2));
    final s = base.copyWith(cells: [
      for (final c in base.cells)
        c.copyWith(danCount: c.id == 3 ? 2 : (c.ownerId == 0 ? 0 : c.danCount)),
    ]);
    final moves = engine.getLegalMoves(s);
    expect(moves.length, 2);
    final m = AiPlayer().chooseMove(s, level: AiLevel.hard);
    expect(moves, contains(m));
    expect(s.phase, GamePhase.playing);
  });
}
