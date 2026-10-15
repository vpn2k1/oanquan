import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_version.dart';
import 'store_links.dart';

enum UpdateNeeded { none, soft, required }

/// Đọc phiên bản tối thiểu / mới nhất từ Firebase Remote Config và so với
/// bản đang cài. Mọi lỗi (offline, chưa cấu hình Firebase) đều coi là
/// "không cần cập nhật" để việc kiểm tra không bao giờ chặn người chơi.
class UpdateChecker {
  static const requiredKey = 'min_required_version';
  static const latestKey = 'latest_version';

  Future<UpdateNeeded> check() async {
    if (kIsWeb || StoreLinks.current == null || Firebase.apps.isEmpty) {
      return UpdateNeeded.none;
    }
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
      final info = await PackageInfo.fromPlatform();
      final current = AppVersion.tryParse(
        '${info.version}+${info.buildNumber}',
      );
      if (current == null) return UpdateNeeded.none;
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
