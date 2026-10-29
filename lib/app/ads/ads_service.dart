import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Khởi tạo Google Mobile Ads (AdMob). Chưa chèn quảng cáo vào màn nào.
abstract final class AdsService {
  /// Ad unit ID thử nghiệm của Google; thay bằng ID thật khi phát hành.
  static String get bannerUnitId {
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  static String get interstitialUnitId {
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  /// Tạm tắt quảng cáo; bật lại (`true`) khi đã có AdMob ID thật.
  static bool enabled = false;

  static bool get supported =>
      enabled && !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!supported) return;
    try {
      await MobileAds.instance.initialize();
    } on Object {
      // Không để lỗi quảng cáo chặn mở app.
    }
  }
}
