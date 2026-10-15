import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Cầu nối tới trang app trên Google Play / App Store.
abstract final class StoreLinks {
  /// applicationId trong android/app/build.gradle.kts.
  static const androidPackage = 'vp.nam.oanquan';

  /// ID số của app trên App Store Connect (vd. '6740000000').
  /// Để trống khi chưa phát hành iOS: khi đó không kiểm tra cập nhật trên iOS.
  static const iosAppId = '';

  static const playUrl =
      'https://play.google.com/store/apps/details?id=$androidPackage';
  static const appStoreUrl = 'https://apps.apple.com/app/id$iosAppId';

  /// Link store của nền tảng hiện tại, null nếu chưa có.
  static String? get current {
    if (Platform.isAndroid) return playUrl;
    if (Platform.isIOS && iosAppId.isNotEmpty) return appStoreUrl;
    return null;
  }

  static Future<bool> open() async {
    final url = current;
    if (url == null) return false;
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
