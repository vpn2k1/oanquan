import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Cầu nối tới trang app trên Google Play / App Store.
abstract final class StoreLinks {
  /// applicationId trong android/app/build.gradle.kts.
  static const androidPackage = 'vp.nam.oanquan';

  /// Bundle id iOS, dùng để hỏi phiên bản mới qua iTunes Lookup.
  static const iosBundleId = 'vp.nam.oanquan';

  /// ID số của app trên App Store Connect (vd. '6740000000'). Không bắt buộc:
  /// link App Store được lấy từ iTunes Lookup khi có bản mới.
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

  /// Mở [url] (vd. link lấy từ store), không có thì link của nền tảng.
  static Future<bool> open([String? url]) async {
    url ??= current;
    if (url == null) return false;
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
