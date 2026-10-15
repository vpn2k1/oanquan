import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/core/game_models/game_event.dart';

import 'fixtures.dart';
import 'rules_engine_helpers.dart';

void main() {
  group('Rải', () {
    test(
      'rải qua ô dân và ô quan, không di chuyển token quan, bốc tiếp ô có dân',
      () {
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
      },
    );

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
      final s0 = custom(
        2,
        dan: [0, 1, 0, 0, 2, 0, 3, 1, 1, 1, 1, 1],
        quan: {0},
      );
      final r = ok(s0, mv(0, 1, cw));
      expect(r.state.players[0].score, 5);
      expect(r.events.whereType<CaptureDanEvent>().map((e) => e.cellId), [
        4,
        6,
      ]);
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
      final s0 = custom(
        2,
        dan: [0, 0, 0, 0, 1, 0, 0, 2, 1, 1, 1, 1],
        quan: {0},
      );
      final r = ok(s0, mv(0, 4, cw));
      expect(r.state.players[0].score, 2);
      expect(r.state.cells[7].danCount, 0);
    });
  });
}
