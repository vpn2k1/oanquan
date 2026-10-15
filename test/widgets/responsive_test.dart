import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/app/app.dart';
import 'package:o_quan_viet/app/router.dart';

import 'app_flow_test.dart' show pumpApp;

double scaleFor(Size screen) {
  final d = OQuanApp.clampedDesignSize(screen);
  return math.min(screen.width / d.width, screen.height / d.height);
}

void main() {
  group('Giới hạn tỉ lệ co giãn', () {
    test('máy thiết kế (dọc và ngang) = 1', () {
      expect(scaleFor(const Size(390, 844)), closeTo(1, 1e-9));
      expect(scaleFor(const Size(844, 390)), closeTo(1, 1e-9));
    });
    test('tablet bị chặn ở maxScale', () {
      expect(scaleFor(const Size(800, 1280)), closeTo(OQuanApp.maxScale, 1e-9));
      expect(scaleFor(const Size(1280, 800)), closeTo(OQuanApp.maxScale, 1e-9));
    });
    test('máy nhỏ được giữ ở minScale', () {
      expect(scaleFor(const Size(320, 568)), closeTo(OQuanApp.minScale, 1e-9));
      expect(scaleFor(const Size(568, 320)), closeTo(OQuanApp.minScale, 1e-9));
    });
    test('máy trung bình giữ tỉ lệ tự nhiên', () {
      expect(scaleFor(const Size(360, 780)), closeTo(360 / 390, 1e-9));
    });
  });

  // Màn ngang là chính; vẫn kiểm tra dọc cho bản web.
  const sizes = [
    Size(568, 320),
    Size(640, 360),
    Size(740, 360),
    Size(844, 390),
    Size(1280, 800),
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(800, 1280),
  ];
  for (final size in sizes) {
    testWidgets('trang chủ + màn chọn không tràn ở $size', (t) async {
      final c = await pumpApp(t, size);
      expect(t.takeException(), isNull, reason: 'trang chủ tràn ở $size');
      _logScroll(t, 'home', size);

      c.read(routerProvider).push(Routes.setup);
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull, reason: 'màn chọn tràn ở $size');
      _logScroll(t, 'setup', size);
    });
  }
}

void _logScroll(WidgetTester t, String screen, Size size) {
  for (final s in t.stateList<ScrollableState>(find.byType(Scrollable))) {
    if (s.position.axis == Axis.vertical && s.position.hasContentDimensions) {
      // ignore: avoid_print
      print(
        '$screen $size cuộn ${s.position.maxScrollExtent.toStringAsFixed(0)}px',
      );
    }
  }
}
