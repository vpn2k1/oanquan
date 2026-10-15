import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'folk_ground.dart';
import 'folk_style.dart';

/// Raster hóa mặt sân (cache theo kích thước + kiểu + seed) để vẽ mỗi frame rẻ.
abstract final class GroundCache {
  static final _cache = <String, ui.Image>{};
  static final _pending = <String, Future<ui.Image>>{};

  static String _key(Size size, double dpr, GroundKind kind, int seed) {
    final w = max(1, (size.width * dpr).round());
    final h = max(1, (size.height * dpr).round());
    return '$w×$h|${kind.name}|$seed';
  }

  static ui.Picture _record(Size size, double dpr, GroundKind kind, int seed) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)..scale(dpr);
    FolkGround.paint(c, size, kind, seed);
    return rec.endRecording();
  }

  static void _store(String key, ui.Image img) {
    // Không dispose: ảnh cũ có thể vẫn đang được vẽ; để GC thu.
    if (_cache.length > 8) _cache.clear();
    _cache[key] = img;
  }

  /// Ảnh đã có sẵn (không vẽ mới) — `null` nếu chưa vẽ xong.
  static ui.Image? peek(Size size, double dpr, GroundKind kind, int seed) =>
      _cache[_key(size, dpr, kind, seed)];

  /// Vẽ sẵn ở nền (bất đồng bộ). Gọi nhiều lần cùng tham số chỉ vẽ một lần.
  static Future<ui.Image> warmUp(
    Size size,
    double dpr,
    GroundKind kind,
    int seed,
  ) {
    final key = _key(size, dpr, kind, seed);
    final hit = _cache[key];
    if (hit != null) return Future.value(hit);
    return _pending[key] ??= () async {
      try {
        final pic = _record(size, dpr, kind, seed);
        final img = await pic.toImage(
          max(1, (size.width * dpr).round()),
          max(1, (size.height * dpr).round()),
        );
        pic.dispose();
        _store(key, img);
        return img;
      } finally {
        _pending.remove(key);
      }
    }();
  }

  /// Vẽ ngay (đồng bộ) — dùng cho nền menu cần có ngay ở frame đầu.
  static ui.Image image(Size size, double dpr, GroundKind kind, int seed) {
    final key = _key(size, dpr, kind, seed);
    final hit = _cache[key];
    if (hit != null) return hit;
    final pic = _record(size, dpr, kind, seed);
    final img = pic.toImageSync(
      max(1, (size.width * dpr).round()),
      max(1, (size.height * dpr).round()),
    );
    pic.dispose();
    _store(key, img);
    return img;
  }
}
