import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/app/layout/fit_to_screen.dart';
import 'package:o_quan_viet/app/router.dart';
import 'package:o_quan_viet/core/game_models/game_config.dart';
import 'package:o_quan_viet/core/game_models/game_state.dart';
import 'package:o_quan_viet/core/game_models/player.dart';
import 'package:o_quan_viet/features/game/game_session.dart';

import 'app_flow_test.dart' show pumpApp;
import 'real_fonts.dart';

/// Điện thoại (ngang là chính, dọc cho web trên điện thoại): mọi màn menu phải
/// hiển thị đủ trong một màn hình, không có vùng cuộn dọc.
const phoneSizes = [
  Size(640, 360),
  Size(740, 360),
  Size(800, 360),
  Size(844, 390),
  Size(360, 640),
  Size(390, 844),
];

/// Thu nhỏ thấp nhất chấp nhận được (FitToScreen) trước khi coi là "quá chật".
const minScale = 0.8;

void main() {
  setUpAll(loadRealFonts);
  for (final size in phoneSizes) {
    testWidgets('màn menu vừa một màn hình ở $size', (t) async {
      _issues.clear();
      final c = await pumpApp(t, size);
      await _check(t, 'home', size);
      for (final r in [
        Routes.setup,
        Routes.settings,
        Routes.achievements,
        Routes.tutorial,
      ]) {
        c.read(routerProvider).go(r);
        await _settle(t);
        await _check(t, r, size);
      }
      _finishGame(c);
      c.read(routerProvider).go(Routes.result);
      await _settle(t);
      expect(find.byKey(const Key('resultTitle')), findsOneWidget);
      await _check(t, Routes.result, size);
      expect(_issues, isEmpty, reason: _issues.join('\n'));
    });
  }
}

Future<void> _settle(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 500));
  await t.pump(const Duration(milliseconds: 100));
}

/// Ván 4 người đã kết thúc, để mở màn kết quả với bảng xếp hạng dài nhất.
void _finishGame(ProviderContainer c) {
  final session = c.read(gameSessionProvider.notifier);
  session.start(const GameConfig(playerCount: 4, seed: 1), [
    for (var i = 0; i < 4; i++) Player(id: i, name: 'P${i + 1}'),
  ]);
  final st = c.read(gameSessionProvider)!;
  final over = st.current.copyWith(
    phase: GamePhase.gameOver,
    winnerIds: [0],
    endReason: EndReason.allQuanCaptured,
  );
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  session.state = st.copyWith(current: over, shown: over);
}

final _issues = <String>[];

Future<void> _check(WidgetTester t, String screen, Size size) async {
  if (t.takeException() != null) _issues.add('$screen tràn ở $size');
  for (final s in t.stateList<ScrollableState>(find.byType(Scrollable))) {
    final p = s.position;
    if (p.axis != Axis.vertical || !p.hasContentDimensions) continue;
    if (p.maxScrollExtent >= 1) {
      _issues.add('$screen phải vuốt ${p.maxScrollExtent.round()}px ở $size');
    }
  }
  // Chỉ xét khung FitToScreen (FittedBox con trực tiếp), không xét các
  // FittedBox nhỏ bên trong (chữ nút chọn có thể co riêng).
  final fits = find.descendant(
    of: find.byType(FitToScreen),
    matching: find.byType(FittedBox),
  );
  final outer = {
    for (final e in find.byType(FitToScreen).evaluate())
      fits.evaluate().firstWhere((f) => _isUnder(f, e)),
  };
  for (final e in outer) {
    final box = e.renderObject! as RenderBox;
    final child = (e.renderObject! as RenderProxyBox).child!;
    final scale = box.size.height / child.size.height;
    if (scale < minScale) {
      _issues.add('$screen thu nhỏ còn ${scale.toStringAsFixed(2)} ở $size');
    }
  }
}

bool _isUnder(Element child, Element ancestor) {
  var found = false;
  child.visitAncestorElements((a) {
    found = a == ancestor;
    return !found;
  });
  return found;
}
