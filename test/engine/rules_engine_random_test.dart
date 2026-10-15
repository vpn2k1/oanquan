import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/core/engine/replay.dart';
import 'package:o_quan_viet/core/game_models/game_config.dart';
import 'package:o_quan_viet/core/game_models/game_state.dart';

import 'fixtures.dart';
import 'rules_engine_helpers.dart';

void main() {
  group('Ngẫu nhiên có seed (bất biến luật)', () {
    for (final n in [2, 3, 4]) {
      test('$n người: bảo toàn dân/quan, luôn kết thúc, replay khớp', () {
        var finished = 0;
        for (var seed = 0; seed < 60; seed++) {
          final rng = Random(seed * 31 + n);
          final init = engine.newGame(GameConfig.preset(n, seed: seed));
          var s = init;
          var guard = 0;
          while (!s.isOver && guard++ < 3000) {
            final moves = engine.getLegalMoves(s);
            expect(moves, isNotEmpty, reason: 'người active luôn có nước đi');
            s = ok(s, moves[rng.nextInt(moves.length)]).state;
            _checkInvariants(s, n);
          }
          if (s.isOver) finished++;
          final replayed = const Replay().replay(init, s.history);
          expect(replayed.boardKey, s.boardKey);
        }
        expect(finished, 60, reason: 'mọi ván ngẫu nhiên đều kết thúc');
      });
    }
  });
}

void _checkInvariants(GameState s, int n) {
  final captured = s.players.fold(
    0,
    (a, p) => a + p.danCaptured + p.danCollected,
  );
  final refills = s.players.fold(0, (a, p) => a + p.refillSpent);
  expect(s.danOnBoard + captured - refills, n * 25, reason: 'bảo toàn dân');
  final quanTaken = s.players.fold(0, (a, p) => a + p.quanCaptured);
  expect(s.quanTokensLeft + quanTaken, n, reason: 'bảo toàn quan');
  final lent = List.filled(n, 0);
  for (final p in s.players) {
    for (final e in p.debts.entries) {
      lent[e.key] += e.value;
    }
  }
  for (final p in s.players) {
    if (s.isOver) expect(p.debts, isEmpty, reason: 'nợ đã trả khi tính điểm');
    // Điểm hiện tại = dân ăn + quan + dân thu − dân rải lại + vay − cho vay.
    // Khi đã trả nợ, phần chênh do trả nợ nằm trong `repaid` (tính từ lịch sử không có),
    // nên chỉ kiểm tra trong ván.
    if (!s.isOver) {
      expect(
        p.score,
        p.danCaptured +
            p.quanCaptured * 10 +
            p.danCollected -
            p.refillSpent +
            p.totalDebt -
            lent[p.id],
      );
      expect(p.score, greaterThanOrEqualTo(0));
    }
  }
  if (s.isOver) {
    final total = s.players.fold(0, (a, p) => a + p.score);
    final expected = s.players.fold(
      0,
      (a, p) =>
          a +
          p.danCaptured +
          p.quanCaptured * 10 +
          p.danCollected -
          p.refillSpent,
    );
    expect(total, expected, reason: 'trả nợ chỉ chuyển điểm giữa người chơi');
  }
  for (final c in s.cells) {
    expect(c.danCount, greaterThanOrEqualTo(0));
    if (c.isDanCell) expect(c.hasQuan, isFalse);
  }
  if (!s.isOver) expect(s.players[s.turnPlayer].active, isTrue);
}
