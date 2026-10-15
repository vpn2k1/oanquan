import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/core/engine/move_result.dart';
import 'package:o_quan_viet/core/engine/rules_engine.dart';
import 'package:o_quan_viet/core/engine/scoring.dart';
import 'package:o_quan_viet/core/game_models/game_event.dart';
import 'package:o_quan_viet/core/game_models/player.dart';

import 'fixtures.dart';
import 'rules_engine_helpers.dart';

void main() {
  group('Nạp dân / loại', () {
    test('refill: hết dân, điểm 5 → trừ 5 và nạp 1 dân/ô', () {
      final s0 = custom(
        2,
        dan: [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        scores: [0, 5],
      );
      final r = ok(s0, mv(0, 3, ccw));
      final s = r.state;
      expect(s.turnPlayer, 1);
      expect(s.players[1].score, 0);
      expect(s.players[1].refillSpent, 5);
      expect(
        [for (var i = 7; i <= 11; i++) s.cells[i].danCount],
        [1, 1, 1, 1, 1],
      );
      final refill = r.events.whereType<RefillEvent>().single;
      expect(refill.playerId, 1);
      expect(refill.cellIds, [7, 8, 9, 10, 11]);
      expect(engine.getLegalMoves(s), isNotEmpty);
    });

    test('thiếu dân → vay đối thủ, trả khi tính điểm', () {
      final s0 = custom(
        2,
        dan: [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        scores: [12, 2],
      );
      final r = ok(s0, mv(0, 3, ccw));
      final s = r.state;
      expect(s.isOver, isFalse);
      expect(s.turnPlayer, 1);
      expect(s.players[1].score, 0);
      expect(s.players[1].debts, {0: 3});
      expect(s.players[0].score, 9, reason: 'người cho vay đưa 3 dân');
      expect(
        [for (var i = 7; i <= 11; i++) s.cells[i].danCount],
        [1, 1, 1, 1, 1],
      );
      expect(r.events.whereType<RefillEvent>().single.borrowed, {0: 3});
    });

    test('kết thúc ván: thu dân bên mình rồi trả nợ', () {
      final base = custom(
        2,
        dan: [0, 0, 0, 1, 0, 0, 5, 2, 0, 1, 0, 0],
        quan: {6},
        scores: [0, 4],
      );
      final s0 = base.copyWith(
        players: [
          base.players[0].copyWith(score: 0),
          base.players[1].copyWith(debts: {0: 3}),
        ],
      );
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

    test(
      'skipEliminated: không đủ điểm và không ai cho vay → bị loại, tới người active kế tiếp',
      () {
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
      },
    );

    test('2 người: không vay đủ → bị loại → kết thúc ván', () {
      final s0 = custom(
        2,
        dan: [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        scores: [0, 4],
      );
      final r = ok(s0, mv(0, 3, ccw));
      expect(r.state.isOver, isTrue);
      expect(r.state.winnerIds, [1]);
      expect(r.events.last, isA<GameOverEvent>());
    });
  });

  group('Kết thúc ván', () {
    test('hai ô quan hết sạch → GameOver, dân bên nào về bên đó', () {
      final s0 = custom(
        2,
        dan: [0, 0, 0, 1, 0, 0, 5, 3, 3, 3, 3, 3],
        quan: {6},
        scores: [0, 12],
      );
      final r = ok(s0, mv(0, 3, cw));
      expect(r.state.isOver, isTrue);
      expect(r.state.players[0].score, 16, reason: '15 + 1 dân còn ở ô 4');
      expect(r.state.players[1].score, 27, reason: '12 + 15 dân còn bên mình');
      expect(r.state.players[1].danCollected, 15);
      expect(r.state.winnerIds, [1]);
      expect(engine.getLegalMoves(r.state), isEmpty);
      expect(
        (engine.applyMove(r.state, mv(1, 7, cw)) as MoveRejected).reason,
        RejectReason.gameOver,
      );
    });

    test('hết quan nhưng ô quan còn dân → chưa kết thúc', () {
      final s0 = custom(
        2,
        dan: [2, 0, 0, 1, 0, 0, 5, 3, 3, 3, 3, 3],
        quan: {6},
        scores: [0, 0],
      );
      final r = ok(s0, mv(0, 3, cw));
      expect(r.state.quanTokensLeft, 0);
      expect(r.state.isOver, isFalse, reason: 'Q0 còn 2 dân');
    });

    test('đồng điểm → hòa đồng hạng', () {
      final s0 = custom(
        2,
        dan: [0, 0, 0, 1, 0, 0, 5, 3, 3, 3, 3, 3],
        quan: {6},
        scores: [0, 1],
      );
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
}
