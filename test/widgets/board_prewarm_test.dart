import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/app/router.dart';
import 'package:o_quan_viet/features/game/flame/board_game.dart';
import 'package:o_quan_viet/features/game/flame/board_raster.dart';

import 'app_flow_test.dart' show pumpApp;

/// Màn chọn vẽ sẵn bàn → vào ván là bàn có ngay frame đầu, đúng ảnh vẽ sẵn.
void main() {
  for (final players in [2, 4]) {
    testWidgets('bàn $players người có ngay khi vào ván', (t) async {
      final c = await pumpApp(t, const Size(800, 360));
      c.read(routerProvider).push(Routes.setup);
      await t.pump(const Duration(milliseconds: 500));
      await t.tap(find.byKey(Key('players$players')));
      await t.pump();
      // Đợi ảnh vẽ sẵn xong (chạy trên luồng raster thật).
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      await t.pump();

      await t.tap(find.byKey(const Key('startGame')));
      await t.pump();
      // Ngay frame đầu: ảnh bàn vẽ sẵn đã lót dưới Flame.
      final underlay = t.widget<RawImage>(find.byType(RawImage).first);
      expect(underlay.image, isNotNull, reason: 'frame đầu chưa có bàn');
      final g =
          (find.byType(GameWidget<OQuanGame>).evaluate().first.widget
                  as GameWidget<OQuanGame>)
              .game!;
      // Frame vẽ đầu tiên của bàn (Flame cần 1–2 frame để gắn game).
      var frames = 1;
      while (g.boardImage == null && frames < 5) {
        await t.pump(const Duration(milliseconds: 16));
        frames++;
      }
      expect(g.geo, isNotNull);
      final ready = StaticBoardCache.peek(g.staticSpec);
      expect(ready, isNotNull, reason: 'bàn chưa được vẽ sẵn đúng thông số');
      expect(g.boardImage, same(ready));
      expect(underlay.image, same(ready));
    });
  }
}
