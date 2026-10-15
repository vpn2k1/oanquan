import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Quy ước: mỗi file Dart dưới 300 dòng code (docs/code_conventions.md).
/// Dòng trống và dòng comment `//` không tính.
const maxLines = 300;
const scanDirs = ['lib', 'test'];
final generated = RegExp(r'(app_localizations[^/\\]*|l10n[/\\]strings)\.dart$');
final nonCode = RegExp(r'^\s*($|//)');

/// File cũ vượt chuẩn, trần = số dòng lúc thêm rule.
/// Chỉ được HẠ trần hoặc xóa; không tăng, không thêm file mới.
const legacyCeilings = <String, int>{};

int codeLines(File f) =>
    f.readAsLinesSync().where((l) => !nonCode.hasMatch(l)).length;

Map<String, int> measure() => {
  for (final dir in scanDirs)
    for (final f in Directory(dir).listSync(recursive: true))
      if (f is File && f.path.endsWith('.dart') && !generated.hasMatch(f.path))
        f.path.replaceAll(r'\', '/'): codeLines(f),
};

void main() {
  final sizes = measure();

  test('mỗi file dưới $maxLines dòng code (hoặc không vượt trần cũ)', () {
    final bad = <String>[];
    sizes.forEach((path, n) {
      final limit = legacyCeilings[path];
      if (limit == null && n >= maxLines) bad.add('$path: $n ≥ $maxLines');
      if (limit != null && n > limit) bad.add('$path: $n > trần $limit');
    });
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('legacyCeilings luôn khớp thực tế (hạ trần / xóa khi đã giảm)', () {
    final stale = <String>[];
    legacyCeilings.forEach((path, limit) {
      final n = sizes[path];
      if (n == null) {
        stale.add('$path: không còn tồn tại — xóa khỏi danh sách');
      } else if (n < maxLines) {
        stale.add('$path: còn $n dòng — xóa khỏi danh sách');
      } else if (n < limit) {
        stale.add('$path: còn $n dòng — hạ trần từ $limit xuống $n');
      }
    });
    expect(stale, isEmpty, reason: stale.join('\n'));
  });
}
