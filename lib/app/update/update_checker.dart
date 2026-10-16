import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_version.dart';
import 'store_update.dart';

enum UpdateNeeded { none, soft, required }

/// Kết quả kiểm tra: mức cần cập nhật + bản mới trên store (nếu biết).
class UpdateResult {
  const UpdateResult(this.need, [this.store]);
  final UpdateNeeded need;
  final StoreUpdate? store;
}

/// Kiểm tra cập nhật từ hai nguồn:
/// - store (Google Play / App Store): có bản mới hơn → nhắc nhẹ;
/// - Firebase Remote Config (nếu đã cấu hình): `min_required_version` để ép
///   cập nhật, `latest_version` để nhắc nhẹ.
/// Mọi lỗi đều coi là "không cần cập nhật" để không bao giờ chặn người chơi.
class UpdateChecker {
  static const requiredKey = 'min_required_version';
  static const latestKey = 'latest_version';

  Future<UpdateResult> check() async {
    if (!_mobile) return const UpdateResult(UpdateNeeded.none);
    final PackageInfo info;
    try {
      info = await PackageInfo.fromPlatform();
    } on Object {
      return const UpdateResult(UpdateNeeded.none);
    }
    final name = AppVersion.tryParse(info.version);
    final full = AppVersion.tryParse('${info.version}+${info.buildNumber}');
    StoreUpdate? store;
    if (name != null) store = await StoreUpdateSource.check(name);
    var need = UpdateNeeded.none;
    if (full != null) need = await _remote(full);
    return UpdateResult(merge(need, store != null), store);
  }

  /// Chỉ app cài từ store (Android/iOS) mới có cập nhật để nhắc.
  static bool get _mobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Gộp hai nguồn: bắt buộc thắng; store có bản mới thì ít nhất nhắc nhẹ.
  static UpdateNeeded merge(UpdateNeeded remote, bool storeHasNewer) {
    if (remote == UpdateNeeded.none && storeHasNewer) return UpdateNeeded.soft;
    return remote;
  }

  Future<UpdateNeeded> _remote(AppVersion current) async {
    if (Firebase.apps.isEmpty) return UpdateNeeded.none;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setDefaults({requiredKey: '0.0.0', latestKey: '0.0.0'});
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await rc.fetchAndActivate();
      return decide(
        current,
        required: AppVersion.tryParse(rc.getString(requiredKey)),
        latest: AppVersion.tryParse(rc.getString(latestKey)),
      );
    } on Object {
      return UpdateNeeded.none;
    }
  }

  /// Quyết định thuần, tách riêng để test.
  static UpdateNeeded decide(
    AppVersion current, {
    AppVersion? required,
    AppVersion? latest,
  }) {
    if (required != null && current.compareTo(required) < 0) {
      return UpdateNeeded.required;
    }
    if (latest != null && current.compareTo(latest) < 0) {
      return UpdateNeeded.soft;
    }
    return UpdateNeeded.none;
  }
}
