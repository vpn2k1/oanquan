import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum Sfx { select, drop, capture, quan, refill, turn, win }

/// Âm thanh tổng hợp bằng code (WAV PCM trong bộ nhớ) — không phụ thuộc asset.
/// Mọi lỗi phát âm thanh đều được nuốt để game không bao giờ hỏng vì audio.
class SoundService {
  SoundService();

  static const _rate = 22050;
  final Map<Sfx, Uint8List> _bank = {};
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool enabled = true;
  bool haptics = true;
  bool _broken = false;
  DateTime _lastDrop = DateTime.fromMillisecondsSinceEpoch(0);

  void init() {
    if (_bank.isNotEmpty) return;
    _bank[Sfx.select] = _wav(_tone(880, 0.06, decay: 40));
    _bank[Sfx.drop] = _wav(_pebble());
    _bank[Sfx.capture] = _wav(_clack());
    _bank[Sfx.quan] = _wav(_chime([784, 1175, 1568], 0.7));
    _bank[Sfx.refill] = _wav(_chime([523, 659], 0.35));
    _bank[Sfx.turn] = _wav(_tone(660, 0.09, decay: 25, volume: 0.25));
    _bank[Sfx.win] = _wav(_arpeggio([523, 659, 784, 1047]));
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
      if (_pool.length < 5) {
        _pool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      }
      final p = _pool[_next++ % _pool.length];
      await p.stop();
      await p.play(BytesSource(_bank[s]!, mimeType: 'audio/wav'), volume: 0.8);
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

  static Float64List _tone(double f, double dur,
      {double decay = 20, double volume = 0.5}) {
    final n = (dur * _rate).round();
    final out = Float64List(n);
    for (var i = 0; i < n; i++) {
      final t = i / _rate;
      out[i] = sin(2 * pi * f * t) * exp(-t * decay) * volume;
    }
    return out;
  }

  /// Tiếng sỏi gốm chạm gỗ: sine trượt tần số + tiếng click nhiễu ngắn.
  static Float64List _pebble() {
    final n = (0.07 * _rate).round();
    final out = Float64List(n);
    final rng = Random(1);
    for (var i = 0; i < n; i++) {
      final t = i / _rate;
      final f = 1900 - 9000 * t;
      out[i] = sin(2 * pi * f * t) * exp(-t * 70) * 0.5 +
          (rng.nextDouble() * 2 - 1) * exp(-t * 400) * 0.35;
    }
    return out;
  }

  static Float64List _clack() {
    final n = (0.16 * _rate).round();
    final out = Float64List(n);
    final rng = Random(2);
    for (var i = 0; i < n; i++) {
      final t = i / _rate;
      out[i] = (sin(2 * pi * 420 * t) * 0.5 + sin(2 * pi * 610 * t) * 0.3) *
              exp(-t * 28) +
          (rng.nextDouble() * 2 - 1) * exp(-t * 250) * 0.3;
    }
    return out;
  }

  static Float64List _chime(List<double> fs, double dur) {
    final n = (dur * _rate).round();
    final out = Float64List(n);
    for (var i = 0; i < n; i++) {
      final t = i / _rate;
      var v = 0.0;
      for (var k = 0; k < fs.length; k++) {
        v += sin(2 * pi * fs[k] * t) * exp(-t * (5 + k * 3));
      }
      out[i] = v / fs.length * 0.6 * min(1.0, t * 200);
    }
    return out;
  }

  static Float64List _arpeggio(List<double> fs) {
    final parts = [for (final f in fs) _tone(f, 0.16, decay: 9, volume: 0.4)];
    final out = Float64List(parts.fold(0, (a, p) => a + p.length));
    var o = 0;
    for (final p in parts) {
      out.setAll(o, p);
      o += p.length;
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
