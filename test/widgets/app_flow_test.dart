import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/app/app.dart';
import 'package:o_quan_viet/app/router.dart';
import 'package:o_quan_viet/core/engine/rules_engine.dart';
import 'package:o_quan_viet/features/game/game_session.dart';
import 'package:o_quan_viet/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> pumpApp(WidgetTester tester, Size size) async {
  // Tắt âm thanh trong test (không có plugin audio).
  SharedPreferences.setMockInitialValues({
    'settings.sound': false,
    'settings.haptics': false,
  });
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const OQuanApp()),
  );
  await tester.pump(const Duration(milliseconds: 1600)); // splash
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

void main() {
  testWidgets('splash hiển thị logo và thương hiệu VPN Games', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.sound': false,
      'settings.haptics': false,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const OQuanApp()),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/splash.png',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('playNow')), findsOneWidget);
  });

  const sizes = {
    'mobile-landscape': Size(812, 375),
    'tablet-landscape': Size(1180, 820),
    'desktop': Size(1400, 820),
    'mobile-portrait (web)': Size(380, 780),
  };

  for (final e in sizes.entries) {
    for (final n in [2, 3, 4]) {
      testWidgets('${e.key}: Home → Setup ($n người, cùng máy) → chơi một nước', (
        tester,
      ) async {
        final c = await pumpApp(tester, e.value);
        expect(find.byKey(const Key('playNow')), findsOneWidget);
        await tester.tap(find.byKey(const Key('playNow')));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.byKey(Key('players$n')));
        await tester.pump();
        await tester.tap(find.text('Chơi với bạn'));
        await tester.pump();
        await tester.scrollUntilVisible(
          find.byKey(const Key('startGame')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('startGame')));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byKey(const Key('pause')), findsOneWidget);
        for (var p = 0; p < n; p++) {
          expect(find.byKey(Key('player$p')), findsOneWidget);
        }
        final s = c.read(gameSessionProvider)!;
        expect(s.current.config.playerCount, n);

        // Gửi một nước như khi chạm ô + mũi tên; Flame phát animation rồi báo xong.
        final m = const RulesEngine().getLegalMoves(s.current).first;
        c.read(gameSessionProvider.notifier).submitMove(m);
        for (
          var i = 0;
          i < 600 && c.read(gameSessionProvider)!.pending != null;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          c.read(gameSessionProvider)!.pending,
          isNull,
          reason: 'animation phải kết thúc',
        );
        expect(c.read(gameSessionProvider)!.shown.moveNumber, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('tutorial, cài đặt và thành tích mở được', (tester) async {
    final c = await pumpApp(tester, const Size(812, 375));
    final router = c.read(routerProvider);
    await tester.tap(find.text('Hướng dẫn'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Bàn và quân'), findsOneWidget);
    await tester.tap(find.text('Tiếp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Chọn ô và hướng'), findsOneWidget);
    router.pop();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Cài đặt'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('reducedMotion')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('English'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('English'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Settings'), findsOneWidget);
    router.pop();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Achievements'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('First game'), findsOneWidget);
  });
}
