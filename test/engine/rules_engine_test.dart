import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/core/engine/board_topology.dart';
import 'package:o_quan_viet/core/engine/move_result.dart';
import 'package:o_quan_viet/core/engine/replay.dart';
import 'package:o_quan_viet/core/engine/rules_engine.dart';
import 'package:o_quan_viet/core/engine/scoring.dart';
import 'package:o_quan_viet/core/game_models/cell.dart';
import 'package:o_quan_viet/core/game_models/game_config.dart';
import 'package:o_quan_viet/core/game_models/game_event.dart';
import 'package:o_quan_viet/core/game_models/game_state.dart';
import 'package:o_quan_viet/core/game_models/move.dart';
import 'package:o_quan_viet/core/game_models/player.dart';
import 'package:o_quan_viet/core/persistence/game_serializer.dart';

import 'fixtures.dart';

const cw = Direction.clockwise;
const ccw = Direction.counterClockwise;

MoveAccepted ok(GameState s, Move m) {
  final r = engine.applyMove(s, m);
  expect(r, isA<MoveAccepted>(), reason: '$m bị từ chối: $r');
  return r as MoveAccepted;
}

Move mv(int p, int cell, Direction d) =>
    Move(playerId: p, sourceCellId: cell, direction: d);

void main() {
  group('Khởi tạo bàn', () {
    for (final (n, ring) in [(2, 12), (3, 18), (4, 24)]) {
      test('$n người: $ring ô = ${n * 5} dân + $n quan', () {
        final s = initial(n);
        expect(s.cells.length, ring);
        expect(s.cells.where((c) => c.isQuanCell).length, n);
        expect(s.cells.where((c) => c.isDanCell).length, n * 5);
        expect(s.config.shape,
            [BoardShape.rectangle, BoardShape.triangle, BoardShape.square][n - 2]);
        for (var p = 0; p < n; p++) {
          final own = s.cells.where((c) => c.ownerId == p).toList();
          expect(own.length, 5, reason: 'người $p sở hữu 5 ô');
          expect(own.every((c) => c.danCount == 5 && !c.hasQuan), isTrue);
        }
        for (final q in s.cells.where((c) => c.isQuanCell)) {
          expect(q.danCount, 0);
          expect(q.hasQuan, isTrue);
          expect(q.ownerId, isNull, reason: 'ô quan là ô chung');
        }
        expect(s.turnPlayer, 0);
        expect(s.danOnBoard, n * 25);
      });
    }

    test('thứ tự vòng Q0, P0C0..4, Q1, ... đúng mapping', () {
      final s = initial(3);
      final topo = BoardTopology(s.config);
      for (var p = 0; p < 3; p++) {
        expect(s.cells[topo.quanIndex(p)].kind, CellKind.quan);
        expect(topo.quanIndex(p), p * 6);
        for (var j = 0; j < 5; j++) {
          final i = topo.danIndex(p, j);
          expect(i, p * 6 + 1 + j);
          expect(s.cells[i].ownerId, p);
          expect(topo.danSlot(i), j);
        }
      }
    });

    test('wrap modulo cả hai chiều', () {
      for (final n in [2, 3, 4]) {
        final topo = BoardTopology(GameConfig.preset(n));
        final last = topo.n - 1;
        expect(topo.next(last, cw), 0);
        expect(topo.next(0, ccw), last);
        expect(topo.next(5, cw), 6);
        expect(topo.next(6, ccw), 5);
        expect(topo.wrap(-1), last);
        expect(topo.wrap(topo.n * 3 + 2), 2);
      }
    });
  });

  group('Nước đi hợp lệ', () {
    test('ban đầu có 10 nước (5 ô × 2 chiều), chỉ ô của người đến lượt', () {
      final s = initial(4);
      final moves = engine.getLegalMoves(s);
      expect(moves.length, 10);
      expect(moves.every((m) => s.cells[m.sourceCellId].ownerId == 0), isTrue);
    });

    test('invalidMove: chọn P1C2 → lỗi, state không đổi', () {
      final s = initial(2);
      final before = jsonEncode(GameSerializer.stateToJson(s));
      final topo = BoardTopology(s.config);
      final r = engine.applyMove(s, mv(0, topo.danIndex(1, 2), cw));
      expect((r as MoveRejected).reason, RejectReason.notOwnCell);
      expect(jsonEncode(GameSerializer.stateToJson(s)), before);
    });

    test('không chọn ô quan, ô rỗng, ngoài lượt, ngoài phạm vi', () {
      final s = custom(2, dan: [0, 0, 5, 5, 5, 5, 0, 5, 5, 5, 5, 5]);
      expect((engine.applyMove(s, mv(0, 0, cw)) as MoveRejected).reason,
          RejectReason.quanCellAsSource);
      expect((engine.applyMove(s, mv(0, 1, cw)) as MoveRejected).reason,
          RejectReason.emptyCell);
      expect((engine.applyMove(s, mv(1, 8, cw)) as MoveRejected).reason,
          RejectReason.notYourTurn);
      expect((engine.applyMove(s, mv(0, 99, cw)) as MoveRejected).reason,
          RejectReason.cellOutOfRange);
      expect(engine.getLegalMoves(s).any((m) => m.sourceCellId == 1), isFalse);
    });

    test('applyMove không mutate state đầu vào', () {
      final s = initial(2);
      final before = jsonEncode(GameSerializer.stateToJson(s));
      ok(s, mv(0, 1, cw));
      expect(jsonEncode(GameSerializer.stateToJson(s)), before);
    });
  });

  group('Rải', () {
    test('rải qua ô dân và ô quan, không di chuyển token quan, bốc tiếp ô có dân', () {
      // P0C0 (5) cw: 2..5 +1, Q1 +1, ô 7 (5) → bốc tiếp: 8..11 +1, Q0 +1;
      // ô 1 trống → ăn ô 2 (6 dân).
      final r = ok(initial(2), mv(0, 1, cw));
      final s = r.state;
      expect(danOf(s), [1, 0, 0, 6, 6, 6, 1, 0, 6, 6, 6, 6]);
      expect(s.cells[0].hasQuan, isTrue);
      expect(s.cells[6].hasQuan, isTrue);
      expect(s.players[0].score, 6);
      expect(s.turnPlayer, 1);
      final pickups = r.events.whereType<PickupEvent>().map((e) => e.cellId);
      expect(pickups, [1, 7]);
      expect(r.events.whereType<DropEvent>().length, 10);
      expect(r.events.whereType<CaptureDanEvent>().single.count, 6);
      expect(r.events.last, isA<EndTurnEvent>());
    });

    test('chiều ngược kim đồng hồ wrap qua chỉ số 0', () {
      // P0C0 ccw: Q0 +1, 11..8 +1; ô 7 (5) bốc: Q1 +1, 5..2 +1;
      // ô 1 trống, sau đó Q0 là quan non (1 dân) → không được ăn, mất lượt.
      final s = ok(initial(2), mv(0, 1, ccw)).state;
      expect(danOf(s), [1, 0, 6, 6, 6, 6, 1, 0, 6, 6, 6, 6]);
      expect(s.cells[0].hasQuan, isTrue);
      expect(s.players[0].score, 0);
      expect(s.players[0].quanCaptured, 0);
    });

    test('gặp ô quan (còn token) thì dừng, không bốc, không ăn', () {
      final s0 = custom(2, dan: [0, 0, 0, 0, 1, 0, 3, 1, 1, 1, 1, 1]);
      final r = ok(s0, mv(0, 4, cw));
      expect(danOf(r.state), [0, 0, 0, 0, 0, 1, 3, 1, 1, 1, 1, 1]);
      expect(r.events.whereType<PickupEvent>().length, 1);
      expect(r.state.players[0].score, 0);
    });

    test('ô dân rỗng ngay sau rồi tới ô quan chỉ có token → không ăn gì', () {
      final s0 = custom(2, dan: [0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1]);
      final s = ok(s0, mv(0, 3, cw)).state;
      expect(s.cells[6].hasQuan, isTrue);
      expect(s.players[0].score, 0);
    });
  });

  group('Ăn', () {
    test('captureOne: ô trống rồi ô 3 dân → +3, xóa dân', () {
      final s0 = custom(2, dan: [0, 1, 0, 0, 3, 0, 0, 1, 1, 1, 1, 1]);
      final r = ok(s0, mv(0, 1, cw));
      expect(r.state.players[0].score, 3);
      expect(r.state.players[0].danCaptured, 3);
      expect(r.state.cells[4].danCount, 0);
      expect(danOf(r.state), [0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1]);
    });

    test('ăn chuỗi; gặp quan non (4 dân) thì dừng, không ăn ô quan', () {
      final s0 = custom(2, dan: [0, 1, 0, 0, 2, 0, 4, 1, 1, 1, 1, 1]);
      final r = ok(s0, mv(0, 1, cw));
      expect(r.state.players[0].score, 2);
      expect(r.state.cells[6].danCount, 4);
      expect(r.state.cells[6].hasQuan, isTrue);
      expect(r.events.whereType<CaptureDanEvent>().map((e) => e.cellId), [4]);
      expect(r.events.whereType<CaptureQuanEvent>(), isEmpty);
    });

    test('ăn chuỗi qua ô quan đã mất quan nhưng còn dân', () {
      final s0 = custom(2, dan: [0, 1, 0, 0, 2, 0, 3, 1, 1, 1, 1, 1], quan: {0});
      final r = ok(s0, mv(0, 1, cw));
      expect(r.state.players[0].score, 5);
      expect(r.events.whereType<CaptureDanEvent>().map((e) => e.cellId), [4, 6]);
    });

    test('captureQuanThreshold: 5 dân + token → ăn token, tổng +15', () {
      final s0 = custom(2, dan: [0, 0, 0, 1, 0, 0, 5, 1, 1, 1, 1, 1]);
      final r = ok(s0, mv(0, 3, cw));
      expect(r.state.players[0].score, 15);
      expect(r.state.players[0].danCaptured, 5);
      expect(r.state.players[0].quanCaptured, 1);
      expect(r.state.cells[6].hasQuan, isFalse);
      expect(r.state.cells[6].danCount, 0);
      expect(r.events.whereType<CaptureQuanEvent>().single.value, 10);
      expect(r.state.isOver, isFalse, reason: 'Q0 vẫn còn token');
    });

    test('quan non: 4 dân + quan → không được ăn, mất lượt', () {
      final s0 = custom(2, dan: [0, 0, 0, 1, 0, 0, 4, 1, 1, 1, 1, 1]);
      final r = ok(s0, mv(0, 3, cw));
      expect(r.state.players[0].score, 0);
      expect(r.state.cells[6].danCount, 4);
      expect(r.state.cells[6].hasQuan, isTrue);
      expect(r.state.turnPlayer, 1);
    });

    test('không ăn qua 2 ô trống liên tiếp', () {
      final s0 = custom(2, dan: [0, 1, 0, 0, 0, 3, 0, 1, 1, 1, 1, 1]);
      final r = ok(s0, mv(0, 1, cw));
      expect(r.state.players[0].score, 0);
      expect(r.state.cells[5].danCount, 3);
    });

    test('chuỗi dừng khi gặp 2 ô trống liên tiếp', () {
      // Ăn ô 4 (2), sau đó ô 5 trống, ô 6 (Q1) chỉ token → dừng; ô 8 không bị ăn.
      final s0 = custom(2, dan: [0, 1, 0, 0, 2, 0, 0, 0, 4, 1, 1, 1]);
      final r = ok(s0, mv(0, 1, cw));
      expect(r.state.players[0].score, 2);
      expect(r.state.cells[8].danCount, 4);
    });

    test('giả định A1: ô quan đã mất token và 0 dân được coi là ô trống', () {
      final s0 = custom(2,
          dan: [0, 0, 0, 0, 1, 0, 0, 2, 1, 1, 1, 1], quan: {0});
      final r = ok(s0, mv(0, 4, cw));
      expect(r.state.players[0].score, 2);
      expect(r.state.cells[7].danCount, 0);
    });
  });

  group('Nạp dân / loại', () {
    test('refill: hết dân, điểm 5 → trừ 5 và nạp 1 dân/ô', () {
      final s0 = custom(2,
          dan: [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0], scores: [0, 5]);
      final r = ok(s0, mv(0, 3, ccw));
      final s = r.state;
      expect(s.turnPlayer, 1);
      expect(s.players[1].score, 0);
      expect(s.players[1].refillSpent, 5);
      expect([for (var i = 7; i <= 11; i++) s.cells[i].danCount], [1, 1, 1, 1, 1]);
      final refill = r.events.whereType<RefillEvent>().single;
      expect(refill.playerId, 1);
      expect(refill.cellIds, [7, 8, 9, 10, 11]);
      expect(engine.getLegalMoves(s), isNotEmpty);
    });

    test('thiếu dân → vay đối thủ, trả khi tính điểm', () {
      final s0 = custom(2,
          dan: [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0], scores: [12, 2]);
      final r = ok(s0, mv(0, 3, ccw));
      final s = r.state;
      expect(s.isOver, isFalse);
      expect(s.turnPlayer, 1);
      expect(s.players[1].score, 0);
      expect(s.players[1].debts, {0: 3});
      expect(s.players[0].score, 9, reason: 'người cho vay đưa 3 dân');
      expect([for (var i = 7; i <= 11; i++) s.cells[i].danCount], [1, 1, 1, 1, 1]);
      expect(r.events.whereType<RefillEvent>().single.borrowed, {0: 3});
    });

    test('kết thúc ván: thu dân bên mình rồi trả nợ', () {
      final base = custom(2,
          dan: [0, 0, 0, 1, 0, 0, 5, 2, 0, 1, 0, 0], quan: {6}, scores: [0, 4]);
      final s0 = base.copyWith(players: [
        base.players[0].copyWith(score: 0),
        base.players[1].copyWith(debts: {0: 3}),
      ]);
      final r = ok(s0, mv(0, 3, cw));
      expect(r.state.isOver, isTrue);
      // P0: +5 dân +10 quan, thu 1 (ô 4), nhận trả 3 = 19; P1: 4 + thu 3 − trả 3 = 4.
      expect(r.state.players[0].score, 19);
      expect(r.state.players[1].score, 4);
      expect(r.state.players[1].danCollected, 3);
      expect(r.state.players[1].debts, isEmpty);
      expect(r.state.danOnBoard, 0);
      final types = r.events.map((e) => e.type).toList();
      expect(types.indexOf('Collect'), lessThan(types.indexOf('Repay')));
      expect(types.last, 'GameOver');
    });

    test('skipEliminated: không đủ điểm và không ai cho vay → bị loại, tới người active kế tiếp', () {
      final dan = List.filled(18, 0);
      dan[3] = 1;
      for (var i = 13; i <= 17; i++) {
        dan[i] = 1;
      }
      final s0 = custom(3, dan: dan, scores: [0, 4, 0]);
      final r = ok(s0, mv(0, 3, ccw));
      expect(r.state.players[1].active, isFalse);
      expect(r.state.players[1].score, 4, reason: 'giữ nguyên điểm');
      expect(r.state.turnPlayer, 2);
      expect(r.events.whereType<EliminateEvent>().single.playerId, 1);
      expect(r.state.isOver, isFalse);
      // Ô dân của người bị loại vẫn trên vòng nhưng không ai chọn làm nguồn.
      final after = ok(r.state, mv(2, 17, ccw)).state;
      expect(after.turnPlayer, 0);
      final after2 = ok(after, mv(0, 2, cw)).state;
      expect(after2.turnPlayer, 2, reason: 'bỏ qua người 1 đã bị loại');
    });

    test('2 người: không vay đủ → bị loại → kết thúc ván', () {
      final s0 = custom(2,
          dan: [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0], scores: [0, 4]);
      final r = ok(s0, mv(0, 3, ccw));
      expect(r.state.isOver, isTrue);
      expect(r.state.winnerIds, [1]);
      expect(r.events.last, isA<GameOverEvent>());
    });
  });

  group('Kết thúc ván', () {
    test('hai ô quan hết sạch → GameOver, dân bên nào về bên đó', () {
      final s0 = custom(2,
          dan: [0, 0, 0, 1, 0, 0, 5, 3, 3, 3, 3, 3], quan: {6}, scores: [0, 12]);
      final r = ok(s0, mv(0, 3, cw));
      expect(r.state.isOver, isTrue);
      expect(r.state.players[0].score, 16, reason: '15 + 1 dân còn ở ô 4');
      expect(r.state.players[1].score, 27, reason: '12 + 15 dân còn bên mình');
      expect(r.state.players[1].danCollected, 15);
      expect(r.state.winnerIds, [1]);
      expect(engine.getLegalMoves(r.state), isEmpty);
      expect((engine.applyMove(r.state, mv(1, 7, cw)) as MoveRejected).reason,
          RejectReason.gameOver);
    });

    test('hết quan nhưng ô quan còn dân → chưa kết thúc', () {
      final s0 = custom(2,
          dan: [2, 0, 0, 1, 0, 0, 5, 3, 3, 3, 3, 3], quan: {6}, scores: [0, 0]);
      final r = ok(s0, mv(0, 3, cw));
      expect(r.state.quanTokensLeft, 0);
      expect(r.state.isOver, isFalse, reason: 'Q0 còn 2 dân');
    });

    test('đồng điểm → hòa đồng hạng', () {
      final s0 = custom(2,
          dan: [0, 0, 0, 1, 0, 0, 5, 3, 3, 3, 3, 3], quan: {6}, scores: [0, 1]);
      final r = ok(s0, mv(0, 3, cw));
      expect(r.state.winnerIds, [0, 1]);
      final st = Scoring.standings(r.state.players);
      expect(st.map((e) => e.rank), [1, 1]);
    });

    test('standings xếp hạng kiểu thi đấu 1,1,3', () {
      final ps = [
        const Player(id: 0, name: 'a', score: 7),
        const Player(id: 1, name: 'b', score: 9),
        const Player(id: 2, name: 'c', score: 9),
        const Player(id: 3, name: 'd', score: 1),
      ];
      final st = Scoring.standings(ps);
      expect(st.map((e) => e.player.id), [1, 2, 0, 3]);
      expect(st.map((e) => e.rank), [1, 1, 3, 4]);
      expect(Scoring.teamScores(ps), [7 + 9, 9 + 1]);
    });
  });

  group('Loop guard', () {
    test('vượt chốt bước tối đa → RuleLoopGuard và kết thúc lượt', () {
      const tiny = RulesEngine(maxStepsPerTurn: 3);
      final r = tiny.applyMove(initial(2), mv(0, 1, cw)) as MoveAccepted;
      expect(r.events.whereType<RuleLoopGuardEvent>(), hasLength(1));
      expect(r.state.turnPlayer, 1);
      expect(r.state.danOnBoard, 50);
    });
  });

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
  final captured = s.players.fold(0, (a, p) => a + p.danCaptured + p.danCollected);
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
      expect(p.score,
          p.danCaptured + p.quanCaptured * 10 + p.danCollected - p.refillSpent + p.totalDebt - lent[p.id]);
      expect(p.score, greaterThanOrEqualTo(0));
    }
  }
  if (s.isOver) {
    final total = s.players.fold(0, (a, p) => a + p.score);
    final expected = s.players.fold(0, (a, p) =>
        a + p.danCaptured + p.quanCaptured * 10 + p.danCollected - p.refillSpent);
    expect(total, expected, reason: 'trả nợ chỉ chuyển điểm giữa người chơi');
  }
  for (final c in s.cells) {
    expect(c.danCount, greaterThanOrEqualTo(0));
    if (c.isDanCell) expect(c.hasQuan, isFalse);
  }
  if (!s.isOver) expect(s.players[s.turnPlayer].active, isTrue);
}
