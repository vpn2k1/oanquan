import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/core/engine/board_topology.dart';
import 'package:o_quan_viet/core/engine/move_result.dart';
import 'package:o_quan_viet/core/game_models/cell.dart';
import 'package:o_quan_viet/core/game_models/game_config.dart';
import 'package:o_quan_viet/core/persistence/game_serializer.dart';

import 'fixtures.dart';
import 'rules_engine_helpers.dart';

void main() {
  group('Khởi tạo bàn', () {
    for (final (n, ring) in [(2, 12), (3, 18), (4, 24)]) {
      test('$n người: $ring ô = ${n * 5} dân + $n quan', () {
        final s = initial(n);
        expect(s.cells.length, ring);
        expect(s.cells.where((c) => c.isQuanCell).length, n);
        expect(s.cells.where((c) => c.isDanCell).length, n * 5);
        expect(
          s.config.shape,
          [BoardShape.rectangle, BoardShape.triangle, BoardShape.square][n - 2],
        );
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
      expect(
        (engine.applyMove(s, mv(0, 0, cw)) as MoveRejected).reason,
        RejectReason.quanCellAsSource,
      );
      expect(
        (engine.applyMove(s, mv(0, 1, cw)) as MoveRejected).reason,
        RejectReason.emptyCell,
      );
      expect(
        (engine.applyMove(s, mv(1, 8, cw)) as MoveRejected).reason,
        RejectReason.notYourTurn,
      );
      expect(
        (engine.applyMove(s, mv(0, 99, cw)) as MoveRejected).reason,
        RejectReason.cellOutOfRange,
      );
      expect(engine.getLegalMoves(s).any((m) => m.sourceCellId == 1), isFalse);
    });

    test('applyMove không mutate state đầu vào', () {
      final s = initial(2);
      final before = jsonEncode(GameSerializer.stateToJson(s));
      ok(s, mv(0, 1, cw));
      expect(jsonEncode(GameSerializer.stateToJson(s)), before);
    });
  });
}
