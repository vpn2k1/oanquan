import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show compute, visibleForTesting;
import 'package:flutter/services.dart';

import 'sound_synth.dart';

enum Sfx { select, drop, capture, quan, refill, turn, win }

/// Âm thanh tổng hợp bằng code (WAV PCM trong bộ nhớ) — không phụ thuộc asset.
/// Mọi lỗi phát âm thanh đều được nuốt để game không bao giờ hỏng vì audio.
class SoundService {
  SoundService();

  final Map<Sfx, Uint8List> _bank = {};

  /// Nhiều biến thể tiếng sỏi rơi, phát luân phiên cho tự nhiên.
  final List<Uint8List> _drops = [];
  int _dropIdx = 0;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool enabled = true;
  bool haptics = true;
  bool _broken = false;
  DateTime _lastDrop = DateTime.fromMillisecondsSinceEpoch(0);

  static const _volume = {
    Sfx.select: 0.55,
    Sfx.drop: 0.9,
    Sfx.capture: 0.9,
    Sfx.quan: 0.95,
    Sfx.refill: 0.8,
    Sfx.turn: 0.45,
    Sfx.win: 0.85,
  };

  /// Chỉ dùng trong test: các file WAV đã tổng hợp.
  @visibleForTesting
  Map<String, Uint8List> get debugSounds => {
    for (final e in _bank.entries) e.key.name: e.value,
    for (var i = 0; i < _drops.length; i++) 'drop$i': _drops[i],
  };

  /// Kho âm thanh dùng chung, tổng hợp một lần ở isolate nền.
  static Future<Map<String, Uint8List>>? _shared;

  /// Bắt đầu tổng hợp ở nền (gọi sớm, lúc mở app) để vào ván không bị khựng.
  static Future<Map<String, Uint8List>> prepare() =>
      _shared ??= compute(SoundSynth.all, 0);

  void _fill(Map<String, Uint8List> m) {
    if (_bank.isNotEmpty) return;
    for (var v = 0; v < 6; v++) {
      _drops.add(m['drop$v']!);
    }
    for (final s in Sfx.values) {
      if (s != Sfx.drop) _bank[s] = m[s.name]!;
    }
  }

  /// Tổng hợp ngay trên luồng hiện tại (test).
  void init() => _fill(SoundSynth.all(0));

  /// Lấy kho đã tổng hợp ở nền, không chặn giao diện.
  Future<void> warmUp() async {
    if (_bank.isNotEmpty) return;
    try {
      _fill(await prepare());
    } on Object {
      _broken = true; // không tổng hợp được → im lặng
    }
  }

  Future<void> play(Sfx s) async {
    if (s == Sfx.drop || s == Sfx.capture) _haptic(s);
    if (!enabled || _broken) return;
    if (s == Sfx.drop) {
      final now = DateTime.now();
      if (now.difference(_lastDrop).inMilliseconds < 55) return;
      _lastDrop = now;
    }
    // Kho chưa sẵn (rất hiếm, vừa mở app): bỏ qua tiếng này, không chặn UI.
    if (_bank.isEmpty) {
      warmUp();
      return;
    }
    try {
      if (_pool.length < 6) {
        _pool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      }
      final p = _pool[_next++ % _pool.length];
      final Uint8List bytes;
      if (s == Sfx.drop) {
        bytes = _drops[_dropIdx++ % _drops.length];
      } else {
        bytes = _bank[s]!;
      }
      await p.stop();
      await p.play(
        BytesSource(bytes, mimeType: 'audio/wav'),
        volume: _volume[s] ?? 0.8,
      );
    } catch (_) {
      _broken = true; // nền tảng không hỗ trợ → im lặng, không crash
    }
  }

  void _haptic(Sfx s) {
    if (!haptics) return;
    try {
      if (s == Sfx.capture) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _pool.clear();
  }
}
