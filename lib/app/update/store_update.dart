import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import 'app_version.dart';
import 'store_links.dart';

/// Bản mới hơn đang có trên Google Play / App Store.
class StoreUpdate {
  const StoreUpdate({
    required this.id,
    this.version,
    this.url,
    this.inApp = false,
  });

  /// Định danh bản mới (để nhớ "Để sau"): versionCode (Android) hoặc tên
  /// phiên bản (iOS).
  final String id;

  /// Tên phiên bản hiển thị cho người chơi (iOS có, Android không có).
  final String? version;

  /// Trang app trên store.
  final String? url;

  /// Android: Google Play cho phép cập nhật ngay trong app.
  final bool inApp;
}

/// Hỏi store xem có bản mới hơn bản đang cài không. Mọi lỗi (offline, cài
/// ngoài Play, app chưa lên store) đều trả null để không chặn người chơi.
abstract final class StoreUpdateSource {
  static Future<StoreUpdate?> check(AppVersion installed) async {
    if (kIsWeb) return null;
    try {
      if (Platform.isAndroid) return await _android();
      if (Platform.isIOS) return await _ios(installed);
    } on Object {
      // Bỏ qua: không kiểm tra được thì coi như không có bản mới.
    }
    return null;
  }

  /// Google Play In-App Updates: chỉ chạy với bản cài từ Play.
  static Future<StoreUpdate?> _android() async {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return null;
    }
    return StoreUpdate(
      id: '${info.availableVersionCode}',
      url: StoreLinks.playUrl,
      inApp: info.immediateUpdateAllowed,
    );
  }

  /// iTunes Lookup API theo bundle id, ở cửa hàng nước của máy (mặc định VN).
  static Future<StoreUpdate?> _ios(AppVersion installed) async {
    final country = PlatformDispatcher.instance.locale.countryCode ?? 'VN';
    final uri = Uri.https('itunes.apple.com', '/lookup', {
      'bundleId': StoreLinks.iosBundleId,
      'country': country.toLowerCase(),
    });
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      return parseItunesLookup(body, installed);
    } finally {
      client.close(force: true);
    }
  }

  /// Đọc kết quả iTunes Lookup; trả bản mới nếu store cao hơn [installed].
  static StoreUpdate? parseItunesLookup(String body, AppVersion installed) {
    final json = jsonDecode(body);
    if (json is! Map || json['results'] is! List) return null;
    final results = json['results'] as List;
    if (results.isEmpty || results.first is! Map) return null;
    final app = results.first as Map;
    final raw = app['version'];
    if (raw is! String) return null;
    final store = AppVersion.tryParse(raw);
    if (store == null || store.compareTo(installed) <= 0) return null;
    var url = app['trackViewUrl'];
    if (url is! String) url = null;
    return StoreUpdate(id: raw, version: raw, url: url as String?);
  }
}
