import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/app/router.dart';
import 'package:o_quan_viet/core/game_models/game_config.dart';
import 'package:o_quan_viet/core/game_models/player.dart';
import 'package:o_quan_viet/features/game/game_session.dart';

import 'app_flow_test.dart' show pumpApp;

/// Xoay điện thoại giữa chừng: màn đang mở dựng lại theo chiều mới, không tràn.
void main() {
  const landscape = Size(800, 360);
  const portrait = Size(360, 800);

  Future<void> rotate(WidgetTester t, Size size, String where) async {
    t.view.physicalSize = size;
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.takeException(), isNull, reason: '$where tràn ở $size');
  }

  for (final n in [2, 4]) {
    testWidgets('màn chơi $n người xoay ngang ↔ dọc', (t) async {
      final c = await pumpApp(t, landscape);
      c.read(gameSessionProvider.notifier).start(
        GameConfig(playerCount: n, seed: 7),
        [for (var i = 0; i < n; i++) Player(id: i, name: 'P${i + 1}')],
      );
      c.read(routerProvider).go(Routes.game);
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 100));
      for (final size in [portrait, landscape, portrait]) {
        await rotate(t, size, 'màn chơi');
        for (var i = 0; i < n; i++) {
          expect(find.byKey(Key('player$i')), findsOneWidget);
        }
      }
    });
  }

  testWidgets('màn menu xoay ngang ↔ dọc', (t) async {
    final c = await pumpApp(t, landscape);
    for (final r in [Routes.home, Routes.setup, Routes.settings]) {
      c.read(routerProvider).go(r);
      await t.pump(const Duration(milliseconds: 500));
      for (final size in [portrait, landscape]) {
        await rotate(t, size, r);
      }
    }
  });
}
