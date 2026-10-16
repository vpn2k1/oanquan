import 'dart:io';

import 'package:flutter/services.dart';

/// Nạp font Roboto thật (kèm Flutter SDK) thay cho font ô vuông mặc định của
/// test, để đo bố cục sát với điện thoại. Không tìm thấy SDK thì bỏ qua.
Future<void> loadRealFonts() async {
  final exe = Platform.resolvedExecutable.replaceAll(r'\', '/');
  final i = exe.indexOf('/bin/cache/');
  var root = Platform.environment['FLUTTER_ROOT'];
  if (i >= 0) root ??= exe.substring(0, i);
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  // Chữ không đặt fontFamily rơi về font mặc định của test ('FlutterTest')
  // → nạp Roboto dưới cả hai tên.
  for (final family in ['Roboto', 'FlutterTest']) {
    final loader = FontLoader(family);
    for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
      final f = File('${dir.path}/Roboto-$w.ttf');
      if (!f.existsSync()) continue;
      final bytes = f.readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}
