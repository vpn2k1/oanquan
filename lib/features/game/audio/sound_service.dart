import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

enum Sfx { select, drop, capture, quan, refill, turn, win }

/// Âm thanh tổng hợp bằng code (WAV PCM trong bộ nhớ) — không phụ thuộc asset.
/// Mọi lỗi phát âm thanh đều được nuốt để game không bao giờ hỏng vì audio.
class SoundService {
  SoundService();

  static const _rate = 44100;
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

  void init() {
    if (_bank.isNotEmpty) return;
    for (var v = 0; v < 6; v++) {
      _drops.add(_wav(_master(_pebble(v), reverb: 0.12)));
    }
    _bank[Sfx.select] = _wav(
      _master(_bamboo(1046.5, 0.18, bright: 0.6), reverb: 0.15),
    );
    _bank[Sfx.capture] = _wav(_master(_handful(), reverb: 0.15));
    _bank[Sfx.quan] = _wav(_master(_quan(), reverb: 0.3));
    _bank[Sfx.refill] = _wav(_master(_refill(), reverb: 0.15));
    _bank[Sfx.turn] = _wav(
      _master(_bamboo(392, 0.25, bright: 0.3), reverb: 0.2),
    );
    _bank[Sfx.win] = _wav(_master(_melody(), reverb: 0.35));
  }

  Future<void> play(Sfx s) async {
    if (s == Sfx.drop || s == Sfx.capture) _haptic(s);
    if (!enabled || _broken) return;
    if (s == Sfx.drop) {
      final now = DateTime.now();
      if (now.difference(_lastDrop).inMilliseconds < 55) return;
      _lastDrop = now;
    }
    try {
      init();
      if (_pool.length < 6) {
        _pool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      }
      final p = _pool[_next++ % _pool.length];
      final bytes = s == Sfx.drop
          ? _drops[_dropIdx++ % _drops.length]
          : _bank[s]!;
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
      s == Sfx.capture
          ? HapticFeedback.mediumImpact()
          : HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _pool.clear();
  }

  // --- Tổng hợp ---------------------------------------------------------------

  static Float64List _buf(double dur) => Float64List((dur * _rate).round());

  /// Cộng `src` vào `dst` tại thời điểm `at` (giây) với hệ số `gain`.
  static void _mix(
    Float64List dst,
    Float64List src,
    double at, [
    double gain = 1,
  ]) {
    final o = (at * _rate).round();
    for (var i = 0; i < src.length && o + i < dst.length; i++) {
      dst[o + i] += src[i] * gain;
    }
  }

  /// Tiếng đá chạm: vài cộng hưởng không điều hòa tắt nhanh (mô hình đá thật)
  /// + xung nhiễu lọc thông thấp (tiếng "tách") + tiếng "cộc" trầm của nền.
  static Float64List _stone(
    Random r, {
    double pitch = 1,
    double body = 0.5,
    double dur = 0.12,
  }) {
    final out = _buf(dur);
    final modes = [
      (2350.0 * pitch, 55.0, 0.45),
      (3720.0 * pitch, 75.0, 0.28),
      (5480.0 * pitch, 110.0, 0.16),
      (1260.0 * pitch, 42.0, 0.3),
    ];
    final phases = [for (final _ in modes) r.nextDouble() * pi * 2];
    var lp = 0.0;
    for (var i = 0; i < out.length; i++) {
      final t = i / _rate;
      var v = 0.0;
      for (var k = 0; k < modes.length; k++) {
        final (f, d, g) = modes[k];
        v +=
            sin(2 * pi * f * (1 + r.nextDouble() * 0.0008) * t + phases[k]) *
            exp(-t * d) *
            g;
      }
      // Xung nhiễu lọc thông thấp một cực.
      lp += 0.35 * ((r.nextDouble() * 2 - 1) - lp);
      v += lp * exp(-t * 520) * 0.9;
      // "Cộc" trầm ~170 Hz.
      v += sin(2 * pi * 170 * t) * exp(-t * 60) * body;
      out[i] = v;
    }
    return out;
  }

  static Float64List _pebble(int variant) {
    final r = Random(100 + variant);
    final out = _buf(0.16);
    _mix(out, _stone(r, pitch: 0.85 + r.nextDouble() * 0.35, body: 0.45), 0);
    // Đôi khi viên sỏi nảy nhẹ một lần.
    if (variant.isOdd) {
      _mix(
        out,
        _stone(r, pitch: 1.1, body: 0.1, dur: 0.06),
        0.035 + r.nextDouble() * 0.02,
        0.35,
      );
    }
    return out;
  }

  /// Vốc một nắm sỏi: nhiều tiếng chạm dày dần rồi thưa, kèm tiếng sột soạt.
  static Float64List _handful() {
    final r = Random(7);
    final out = _buf(0.42);
    for (var k = 0; k < 9; k++) {
      final at = 0.012 + pow(r.nextDouble(), 1.6) * 0.24;
      _mix(
        out,
        _stone(r, pitch: 0.9 + r.nextDouble() * 0.5, body: 0.15, dur: 0.09),
        at,
        0.55 - k * 0.03,
      );
    }
    var lp = 0.0;
    for (var i = 0; i < out.length; i++) {
      final t = i / _rate;
      lp += 0.08 * ((r.nextDouble() * 2 - 1) - lp);
      out[i] += lp * 0.5 * sin(pi * min(1.0, t / 0.3)) * exp(-t * 6);
    }
    return out;
  }

  /// Đàn t'rưng (tre): cơ bản + bội âm không điều hòa của ống tre, tấn công nhanh.
  static Float64List _bamboo(double f, double dur, {double bright = 0.5}) {
    final out = _buf(dur + 0.25);
    for (var i = 0; i < out.length; i++) {
      final t = i / _rate;
      final atk = min(1.0, t * 900);
      out[i] =
          atk *
          (sin(2 * pi * f * t) * exp(-t * 9) * 0.6 +
              sin(2 * pi * f * 2.76 * t) * exp(-t * 22) * 0.35 * bright +
              sin(2 * pi * f * 5.4 * t) * exp(-t * 45) * 0.2 * bright +
              sin(2 * pi * f * 0.5 * t) * exp(-t * 30) * 0.15);
    }
    return out;
  }

  /// Ăn quan: đá nặng rơi + hai nốt t'rưng (Sol–Đô).
  static Float64List _quan() {
    final r = Random(11);
    final out = _buf(1.1);
    _mix(out, _stone(r, pitch: 0.55, body: 1.0, dur: 0.2), 0, 0.9);
    _mix(out, _bamboo(783.99, 0.5, bright: 0.5), 0.09, 0.7);
    _mix(out, _bamboo(1046.5, 0.6, bright: 0.45), 0.22, 0.75);
    return out;
  }

  /// Rải lại 5 dân: năm tiếng sỏi đặt xuống đều nhau.
  static Float64List _refill() {
    final r = Random(5);
    final out = _buf(0.6);
    for (var k = 0; k < 5; k++) {
      _mix(
        out,
        _stone(r, pitch: 0.9 + k * 0.05, body: 0.35, dur: 0.1),
        k * 0.09,
        0.7,
      );
    }
    return out;
  }

  /// Thắng: giai điệu ngũ cung (Đô–Rê–Fa–Sol–La–Đô) bằng tiếng t'rưng.
  static Float64List _melody() {
    const notes = [523.25, 587.33, 698.46, 783.99, 880.0, 1046.5];
    final out = _buf(1.9);
    for (var k = 0; k < notes.length; k++) {
      _mix(
        out,
        _bamboo(notes[k], k == notes.length - 1 ? 0.9 : 0.35, bright: 0.45),
        k * 0.14,
        k == notes.length - 1 ? 0.85 : 0.65,
      );
    }
    _mix(out, _bamboo(523.25, 0.9, bright: 0.2), 0.7, 0.35);
    return out;
  }

  /// Hậu kỳ: vang ngắn (vài đường trễ hồi tiếp), khử DC, chuẩn hoá, fade in/out.
  static Float64List _master(Float64List x, {double reverb = 0.2}) {
    final tail = (0.25 * _rate).round();
    final out = Float64List(x.length + tail)..setAll(0, x);
    if (reverb > 0) {
      for (final (ms, g) in const [
        (29.0, 0.5),
        (37.0, 0.42),
        (53.0, 0.33),
        (71.0, 0.25),
      ]) {
        final d = (ms / 1000 * _rate).round();
        for (var i = d; i < out.length; i++) {
          out[i] += out[i - d] * g * reverb;
        }
      }
    }
    var prevIn = 0.0, prevOut = 0.0, peak = 1e-9;
    for (var i = 0; i < out.length; i++) {
      final y = out[i] - prevIn + 0.995 * prevOut; // khử DC
      prevIn = out[i];
      prevOut = y;
      out[i] = y;
      peak = max(peak, y.abs());
    }
    final fadeIn = (0.002 * _rate).round(), fadeOut = (0.03 * _rate).round();
    for (var i = 0; i < out.length; i++) {
      var g = 0.85 / peak;
      if (i < fadeIn) g *= i / fadeIn;
      if (i > out.length - fadeOut) g *= (out.length - i) / fadeOut;
      out[i] *= g;
    }
    return out;
  }

  static Uint8List _wav(Float64List samples) {
    final dataLen = samples.length * 2;
    final b = ByteData(44 + dataLen);
    void str(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        b.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    b.setUint32(4, 36 + dataLen, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little); // PCM
    b.setUint16(22, 1, Endian.little); // mono
    b.setUint32(24, _rate, Endian.little);
    b.setUint32(28, _rate * 2, Endian.little);
    b.setUint16(32, 2, Endian.little);
    b.setUint16(34, 16, Endian.little);
    str(36, 'data');
    b.setUint32(40, dataLen, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
      b.setInt16(44 + i * 2, v, Endian.little);
    }
    return b.buffer.asUint8List();
  }
}
