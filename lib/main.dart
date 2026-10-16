import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/ads/ads_service.dart';
import 'app/app.dart';
import 'features/settings/settings_controller.dart';
import 'features/game/flame/pieces_painter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PiecesPainter.loadPieces();
  // Xoay theo điện thoại: dọc hoặc ngang (bỏ dọc ngược). Mỗi màn có bố cục
  // riêng cho từng chiều (ScreenLayout); web theo cửa sổ trình duyệt.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Chưa có google-services.json / GoogleService-Info.plist thì game vẫn chạy,
  // chỉ bỏ qua kiểm tra cập nhật.
  try {
    await Firebase.initializeApp();
  } on Object {
    // Firebase chưa được cấu hình.
  }
  unawaited(AdsService.init());
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const OQuanApp(),
    ),
  );
}
