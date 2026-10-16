import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/app/app.dart';
import 'package:o_quan_viet/app/router.dart';
import 'package:o_quan_viet/core/game_models/player.dart';
import 'package:o_quan_viet/features/achievements/stats_repository.dart';
import 'package:o_quan_viet/features/settings/settings_controller.dart';
import 'package:o_quan_viet/l10n/app_localizations.dart';
import 'package:o_quan_viet/l10n/l10n.dart';
import 'package:o_quan_viet/l10n/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> pumpLocalized(
  WidgetTester tester,
  Size size, {
  String language = 'vi',
}) async {
  SharedPreferences.setMockInitialValues({
    'settings.sound': false,
    'settings.haptics': false,
    'settings.language': language,
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
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

void main() {
  tearDown(() => Strings.use(lookupAppLocalizations(const Locale('vi'))));

  test('Strings.use đổi ngôn ngữ', () {
    expect(Strings.home, 'Trang chủ');
    Strings.use(lookupAppLocalizations(const Locale('en')));
    expect(Strings.home, 'Home');
    expect(Strings.turnOf('An'), 'Turn: An');
    expect(Strings.level(AiLevel.hard), 'Hard');
    expect(Strings.achievement(Achievement.firstGame), 'First game');
    expect(Strings.styleName('dirt_stick'), 'Dirt · stick');
  });

  test('AppLanguage.byCode mặc định là vi', () {
    expect(AppLanguage.byCode('en'), AppLanguage.en);
    expect(AppLanguage.byCode(null), AppLanguage.vi);
    expect(AppLanguage.byCode('xx'), AppLanguage.vi);
  });

  testWidgets('đổi ngôn ngữ trong Cài đặt cập nhật ngay, giữ màn hiện tại', (
    tester,
  ) async {
    final c = await pumpLocalized(tester, const Size(844, 390));
    c.read(routerProvider).go(Routes.settings);
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt'), findsOneWidget);

    // Điện thoại ngang: Cài đặt vừa một màn hình, không cần cuộn.
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(c.read(settingsProvider).language, AppLanguage.en);
    expect(Strings.home, 'Home');
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Cài đặt'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
  });

  // Tiếng Anh thường dài hơn: kiểm tra tràn chữ trên máy hẹp.
  for (final size in const [Size(360, 740), Size(740, 360)]) {
    for (final route in [
      Routes.home,
      Routes.setup,
      Routes.settings,
      Routes.tutorial,
      Routes.achievements,
    ]) {
      testWidgets('tiếng Anh không tràn: $route ở $size', (tester) async {
        final c = await pumpLocalized(tester, size, language: 'en');
        expect(Strings.home, 'Home');
        c.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
