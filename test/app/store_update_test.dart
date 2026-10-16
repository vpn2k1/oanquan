import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/app/update/app_version.dart';
import 'package:o_quan_viet/app/update/store_update.dart';
import 'package:o_quan_viet/app/update/update_checker.dart';
import 'package:o_quan_viet/app/update/update_gate.dart';
import 'package:o_quan_viet/app/update/update_snooze.dart';
import 'package:o_quan_viet/l10n/app_localizations.dart';
import 'package:o_quan_viet/l10n/strings_scope.dart';

AppVersion v(String s) => AppVersion.tryParse(s)!;

String lookup(String version) =>
    '{"resultCount":1,"results":[{"version":"$version",'
    '"trackViewUrl":"https://apps.apple.com/vn/app/o-quan/id123"}]}';

void main() {
  group('iTunes Lookup', () {
    test('store cao hơn → có bản mới, kèm tên và link', () {
      final u = StoreUpdateSource.parseItunesLookup(
        lookup('1.2.0'),
        v('1.1.9'),
      );
      expect(u?.version, '1.2.0');
      expect(u?.id, '1.2.0');
      expect(u?.url, 'https://apps.apple.com/vn/app/o-quan/id123');
    });
    test('bằng hoặc thấp hơn → không có', () {
      expect(
        StoreUpdateSource.parseItunesLookup(lookup('1.2.0'), v('1.2.0')),
        isNull,
      );
      expect(
        StoreUpdateSource.parseItunesLookup(lookup('1.1.0'), v('1.2.0')),
        isNull,
      );
    });
    test('chưa lên store / dữ liệu lạ → không có', () {
      expect(
        StoreUpdateSource.parseItunesLookup(
          '{"resultCount":0,"results":[]}',
          v('1.0.0'),
        ),
        isNull,
      );
      expect(
        StoreUpdateSource.parseItunesLookup('{"results":[{}]}', v('1.0.0')),
        isNull,
      );
    });
  });

  test('gộp nguồn: bắt buộc thắng, store mới → nhắc nhẹ', () {
    expect(UpdateChecker.merge(UpdateNeeded.none, false), UpdateNeeded.none);
    expect(UpdateChecker.merge(UpdateNeeded.none, true), UpdateNeeded.soft);
    expect(
      UpdateChecker.merge(UpdateNeeded.required, true),
      UpdateNeeded.required,
    );
  });

  test('"Để sau" chỉ hoãn đúng bản đó trong 2 ngày', () {
    final t0 = DateTime(2026, 10, 16, 9);
    final stored = '1.2.0|${t0.millisecondsSinceEpoch}';
    expect(UpdateSnooze.snoozed(null, '1.2.0', t0), isFalse);
    expect(
      UpdateSnooze.snoozed(stored, '1.2.0', t0.add(const Duration(days: 1))),
      isTrue,
    );
    expect(
      UpdateSnooze.snoozed(stored, '1.2.0', t0.add(const Duration(days: 3))),
      isFalse,
    );
    expect(UpdateSnooze.snoozed(stored, '1.3.0', t0), isFalse);
  });

  Future<void> pumpDialog(WidgetTester t, UpdateDialog d) => t.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: StringsScope(child: Scaffold(body: d)),
    ),
  );

  testWidgets('popup nhắc nhẹ hiện số phiên bản, có "Để sau"', (t) async {
    await pumpDialog(
      t,
      const UpdateDialog(
        required: false,
        store: StoreUpdate(id: '1.2.0', version: '1.2.0'),
      ),
    );
    await t.pump();
    expect(find.textContaining('1.2.0'), findsOneWidget);
    expect(find.byKey(const Key('updateLater')), findsOneWidget);
    expect(find.byKey(const Key('updateNow')), findsOneWidget);
  });

  testWidgets('popup bắt buộc không có "Để sau"', (t) async {
    await pumpDialog(t, const UpdateDialog(required: true));
    await t.pump();
    expect(find.byKey(const Key('updateLater')), findsNothing);
    expect(find.byKey(const Key('updateNow')), findsOneWidget);
  });
}
