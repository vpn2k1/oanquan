import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/ads/ads_service.dart';
import 'app/app.dart';
import 'features/settings/settings_controller.dart';
import 'features/game/audio/sound_service.dart';
import 'features/game/flame/pieces_painter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PiecesPainter.loadPieces();
  // Luôn nằm ngang, lật trái/phải theo cảm biến: khóa bằng cấu hình native
  // (AndroidManifest `sensorLandscape`, Info.plist chỉ hai chiều ngang).
  // Không gọi SystemChrome.setPreferredOrientations: trên Android nó đổi thành
  // USER_LANDSCAPE, không lật khi máy tắt tự động xoay.
  // Chưa có google-services.json / GoogleService-Info.plist thì game vẫn chạy,
  // chỉ bỏ qua kiểm tra cập nhật.
  try {
    await Firebase.initializeApp();
  } on Object {
    // Firebase chưa được cấu hình.
  }
  unawaited(AdsService.init());
  // Tổng hợp âm thanh ở isolate nền ngay từ đầu (vào ván không bị khựng).
  unawaited(SoundService.prepare());
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const OQuanApp(),
    ),
  );
}
