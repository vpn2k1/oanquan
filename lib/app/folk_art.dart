import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Mặt sân dân dã, vẽ thủ tục bằng Canvas (không dùng ảnh).
enum GroundKind {
  dirt,
  concrete,
  tiles,

  /// Đất sỏi tông sẫm — nền các màn menu (chữ kem vẫn đọc rõ).
  darkDirt,
}

/// Dụng cụ kẻ bàn.
enum PenKind { stick, chalk, brick, charcoal }

/// Một tổ hợp mặt sân + nét vẽ.
class FolkStyle {
  const FolkStyle(this.id, this.ground, this.pen);

  final String id;
  final GroundKind ground;
  final PenKind pen;

  static const dirtStick = FolkStyle(
    'dirt_stick',
    GroundKind.dirt,
    PenKind.stick,
  );
  static const concreteChalk = FolkStyle(
    'concrete_chalk',
    GroundKind.concrete,
    PenKind.chalk,
  );
  static const tilesChalk = FolkStyle(
    'tiles_chalk',
    GroundKind.tiles,
    PenKind.chalk,
  );
  static const concreteBrick = FolkStyle(
    'concrete_brick',
    GroundKind.concrete,
    PenKind.brick,
  );
  static const concreteCharcoal = FolkStyle(
    'concrete_charcoal',
    GroundKind.concrete,
    PenKind.charcoal,
  );

  static const all = [
    dirtStick,
    concreteChalk,
    tilesChalk,
    concreteBrick,
    concreteCharcoal,
  ];

  /// Giá trị cài đặt cho "ngẫu nhiên mỗi ván".
  static const randomId = 'random';

  static FolkStyle byId(String id) =>
      all.where((s) => s.id == id).firstOrNull ?? concreteChalk;

  /// `setting` = id cụ thể hoặc [randomId] → chọn theo `seed` (ổn định trong một ván).
  static FolkStyle resolve(String setting, int seed) => setting == randomId
      ? all[(seed.abs() * 2654435761) % all.length]
      : byId(setting);

  /// Màu nét chính.
  Color get ink => switch (pen) {
    PenKind.stick => const Color(0xFF5A3A1E),
    PenKind.chalk => const Color(0xFFF7F4EC),
    PenKind.brick => const Color(0xFFB4452C),
    PenKind.charcoal => const Color(0xFF2B2826),
  };

  /// Nét màu cho dải chủ ô: phấn màu, riêng than/gạch giữ dụng cụ nhưng nhuộm màu.
  bool get coloredChalkMarks => true;

  @override
  bool operator ==(Object other) => other is FolkStyle && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Nhiễu mượt (tổng sin, đủ cho nét run tay)
// ---------------------------------------------------------------------------

class _Wobble {
  _Wobble(Random r)
    : _f = [for (var i = 0; i < 3; i++) 0.02 + r.nextDouble() * 0.09],
      _p = [for (var i = 0; i < 3; i++) r.nextDouble() * pi * 2];
  final List<double> _f;
  final List<double> _p;

  double at(double d) =>
      0.55 * sin(d * _f[0] + _p[0]) +
      0.3 * sin(d * _f[1] * 2.3 + _p[1]) +
      0.15 * sin(d * _f[2] * 5.1 + _p[2]);
}

// ---------------------------------------------------------------------------
// Nét vẽ tay
// ---------------------------------------------------------------------------

abstract final class FolkPen {
  /// Vẽ `path` như kẻ tay bằng `pen`. `color` ghi đè màu (phấn màu).
  static void stroke(
    Canvas canvas,
    Path path,
    PenKind pen, {
    required double width,
    Color? color,
    int seed = 0,
  }) {
    final rnd = Random(seed);
    for (final m in path.computeMetrics()) {
      final pts = _jitteredPoints(m, width, rnd);
      switch (pen) {
        case PenKind.chalk:
          _chalk(canvas, pts, width, color ?? const Color(0xFFF7F4EC), rnd);
        case PenKind.brick:
          _brick(canvas, pts, width, color ?? const Color(0xFFB4452C), rnd);
        case PenKind.charcoal:
          _charcoal(canvas, pts, width, color ?? const Color(0xFF2B2826), rnd);
        case PenKind.stick:
          if (color != null) {
            // Dải màu trên nền đất: phấn màu mảnh.
            _chalk(canvas, pts, width * 0.8, color, rnd);
          } else {
            _scratch(canvas, pts, width, rnd);
          }
      }
    }
  }

  /// Điểm dọc theo contour, lệch theo pháp tuyến bằng nhiễu mượt. Contour kín
  /// được vẽ lố qua điểm đầu một đoạn như nét tay thật.
  static List<(Offset, Offset)> _jitteredPoints(
    ui.PathMetric m,
    double w,
    Random rnd,
  ) {
    final wob = _Wobble(rnd);
    final amp = w * 0.45;
    final step = max(2.0, w * 0.7);
    final len = m.length;
    final start = m.isClosed ? rnd.nextDouble() * len : 0.0;
    final total = m.isClosed ? len + w * (1.5 + rnd.nextDouble() * 2) : len;
    final out = <(Offset, Offset)>[];
    for (var d = 0.0; d <= total; d += step) {
      final at = m.isClosed ? (start + d) % len : d;
      final t = m.getTangentForOffset(at);
      if (t == null) continue;
      final n = Offset(-t.vector.dy, t.vector.dx);
      // Đầu/cuối nét hơi lệch ra ngoài (nhấc phấn).
      final edge = m.isClosed
          ? (d > len ? (d - len) / (total - len + 1) : 0.0)
          : 0.0;
      out.add((t.position + n * (wob.at(d) * amp + edge * w * 0.8), n));
    }
    return out;
  }

  static void _chalk(
    Canvas c,
    List<(Offset, Offset)> pts,
    double w,
    Color color,
    Random rnd,
  ) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Hai lượt: lượt chính và lượt mỏng lệch nhẹ (phấn nghiêng).
    for (var pass = 0; pass < 2; pass++) {
      final off = pass == 0 ? 0.0 : w * 0.28;
      for (var i = 1; i < pts.length; i++) {
        // Chỗ phấn không ăn.
        if (rnd.nextDouble() < (pass == 0 ? 0.05 : 0.25)) continue;
        final (a, na) = pts[i - 1];
        final (b, _) = pts[i];
        p
          ..strokeWidth =
              w *
              (pass == 0
                  ? 0.75 + rnd.nextDouble() * 0.4
                  : 0.35 + rnd.nextDouble() * 0.25)
          ..color = color.withValues(
            alpha: (pass == 0 ? 0.55 : 0.35) + rnd.nextDouble() * 0.35,
          );
        c.drawLine(a + na * off, b + na * off, p);
      }
    }
    // Hạt phấn và bụi rơi quanh nét.
    final dot = Paint();
    for (final (q, n) in pts) {
      if (rnd.nextDouble() < 0.35) {
        dot.color = color.withValues(alpha: 0.15 + rnd.nextDouble() * 0.3);
        c.drawCircle(
          q + n * ((rnd.nextDouble() - 0.5) * w * 2.6),
          w * (0.06 + rnd.nextDouble() * 0.12),
          dot,
        );
      }
    }
  }

  static void _brick(
    Canvas c,
    List<(Offset, Offset)> pts,
    double w,
    Color color,
    Random rnd,
  ) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < pts.length; i++) {
      if (rnd.nextDouble() < 0.03) continue;
      final (a, n) = pts[i - 1];
      final (b, _) = pts[i];
      final tint = Color.lerp(
        color,
        const Color(0xFF7A2A18),
        rnd.nextDouble() * 0.35,
      )!;
      p
        ..strokeWidth = w * (1.0 + rnd.nextDouble() * 0.45)
        ..color = tint.withValues(alpha: 0.5 + rnd.nextDouble() * 0.35);
      c.drawLine(a, b, p);
      // Vết gạch xước song song.
      if (rnd.nextDouble() < 0.6) {
        p
          ..strokeWidth = w * 0.3
          ..color = tint.withValues(alpha: 0.35);
        final o = n * (w * (rnd.nextBool() ? 0.55 : -0.55));
        c.drawLine(a + o, b + o, p);
      }
    }
    final dot = Paint();
    for (final (q, n) in pts) {
      if (rnd.nextDouble() < 0.45) {
        dot.color = Color.lerp(
          color,
          const Color(0xFFE08A5E),
          rnd.nextDouble(),
        )!.withValues(alpha: 0.25 + rnd.nextDouble() * 0.35);
        c.drawCircle(
          q + n * ((rnd.nextDouble() - 0.5) * w * 2.2),
          w * (0.08 + rnd.nextDouble() * 0.16),
          dot,
        );
      }
    }
  }

  static void _charcoal(
    Canvas c,
    List<(Offset, Offset)> pts,
    double w,
    Color color,
    Random rnd,
  ) {
    // Vệt nhòe mờ phía dưới.
    final smudge = Path()..moveTo(pts.first.$1.dx, pts.first.$1.dy);
    for (final (q, _) in pts.skip(1)) {
      smudge.lineTo(q.dx, q.dy);
    }
    c.drawPath(
      smudge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.8),
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < pts.length; i++) {
      if (rnd.nextDouble() < 0.06) continue;
      final (a, _) = pts[i - 1];
      final (b, _) = pts[i];
      p
        ..strokeWidth = w * (0.6 + rnd.nextDouble() * 0.5)
        ..color = color.withValues(alpha: 0.6 + rnd.nextDouble() * 0.35);
      c.drawLine(a, b, p);
    }
  }

  /// Que vạch trên đất: rãnh tối, mép sáng do đất bị đẩy lên, vụn đất hai bên.
  static void _scratch(
    Canvas c,
    List<(Offset, Offset)> pts,
    double w,
    Random rnd,
  ) {
    Path line(double off) {
      final path = Path();
      for (var i = 0; i < pts.length; i++) {
        final (q, n) = pts[i];
        final o = q + n * off;
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      return path;
    }

    Paint stroke(Color color, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..color = color;

    c.drawPath(line(w * 0.6), stroke(const Color(0xB3E9D0A8), w * 0.55));
    c.drawPath(line(-w * 0.55), stroke(const Color(0x66E9D0A8), w * 0.35));
    c.drawPath(line(0), stroke(const Color(0xCC6B4A2B), w));
    c.drawPath(line(w * 0.1), stroke(const Color(0x994A311A), w * 0.45));
    final dot = Paint();
    for (final (q, n) in pts) {
      if (rnd.nextDouble() < 0.4) {
        final light = rnd.nextBool();
        dot.color = (light ? const Color(0xFFE6CBA0) : const Color(0xFF6B4A2B))
            .withValues(alpha: 0.35 + rnd.nextDouble() * 0.4);
        final side = rnd.nextBool() ? 1 : -1;
        c.drawCircle(
          q + n * (side * w * (0.9 + rnd.nextDouble() * 0.9)),
          w * (0.12 + rnd.nextDouble() * 0.2),
          dot,
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Mặt sân
// ---------------------------------------------------------------------------

abstract final class FolkGround {
  static Color baseColor(GroundKind k) => switch (k) {
    GroundKind.dirt => const Color(0xFFC49A6C),
    GroundKind.concrete => const Color(0xFFBAB7AF),
    GroundKind.tiles => const Color(0xFFB5583D),
    GroundKind.darkDirt => const Color(0xFF4A3727),
  };

  static void paint(Canvas c, Size size, GroundKind kind, int seed) {
    final rnd = Random(seed);
    switch (kind) {
      case GroundKind.dirt:
        _dirt(c, size, rnd);
      case GroundKind.concrete:
        _concrete(c, size, rnd);
      case GroundKind.tiles:
        _tiles(c, size, rnd);
      case GroundKind.darkDirt:
        _dirt(c, size, rnd, dark: true);
    }
  }

  static Offset _rp(Random r, Size s) =>
      Offset(r.nextDouble() * s.width, r.nextDouble() * s.height);

  static void _blotches(
    Canvas c,
    Size s,
    Random r,
    int n,
    Color dark,
    Color light,
    double minR,
    double maxR,
    double maxAlpha,
  ) {
    final p = Paint();
    for (var i = 0; i < n; i++) {
      final rad = minR + r.nextDouble() * (maxR - minR);
      p
        ..color = (r.nextBool() ? dark : light).withValues(
          alpha: 0.03 + r.nextDouble() * maxAlpha,
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * 0.5);
      c.drawCircle(_rp(r, s), rad, p);
    }
  }

  static void _grit(
    Canvas c,
    Size s,
    Random r,
    double density,
    Color dark,
    Color light,
    double minR,
    double maxR,
    double minA,
    double maxA,
  ) {
    final n = (s.width * s.height / density).round();
    final p = Paint();
    for (var i = 0; i < n; i++) {
      p.color = (r.nextBool() ? dark : light).withValues(
        alpha: minA + r.nextDouble() * (maxA - minA),
      );
      c.drawCircle(_rp(r, s), minR + r.nextDouble() * (maxR - minR), p);
    }
  }

  static void _dirt(Canvas c, Size s, Random r, {bool dark = false}) {
    final rect = Offset.zero & s;
    c.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(r.nextDouble() - 0.5, r.nextDouble() - 0.5),
          radius: 1.1,
          colors: dark
              ? const [Color(0xFF5E4631), Color(0xFF4A3727), Color(0xFF33251A)]
              : const [Color(0xFFD3AE80), Color(0xFFC49A6C), Color(0xFFA97E52)],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    final area = s.width * s.height;
    _blotches(
      c,
      s,
      r,
      (area / 9000).clamp(40, 220).round(),
      dark ? const Color(0xFF1E140C) : const Color(0xFF7E5834),
      dark ? const Color(0xFF8A6A48) : const Color(0xFFE6C9A0),
      12,
      70,
      0.12,
    );
    // Vệt quét chổi.
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final a = _rp(r, s);
      final ang = r.nextDouble() * pi;
      final len = 40 + r.nextDouble() * 120;
      final path = Path()..moveTo(a.dx, a.dy);
      path.quadraticBezierTo(
        a.dx + cos(ang) * len * 0.5 + 15,
        a.dy + sin(ang) * len * 0.5 - 10,
        a.dx + cos(ang) * len,
        a.dy + sin(ang) * len,
      );
      for (var k = 0; k < 4; k++) {
        sweep
          ..strokeWidth = 0.8 + r.nextDouble()
          ..color = (dark ? const Color(0xFF7A5C3E) : const Color(0xFF8E683F))
              .withValues(alpha: 0.08 + r.nextDouble() * 0.08);
        c.drawPath(path.shift(Offset(k * 3.0, k * 2.0)), sweep);
      }
    }
    _grit(
      c,
      s,
      r,
      120,
      dark ? const Color(0xFF1A110A) : const Color(0xFF6E4C2C),
      dark ? const Color(0xFFA88660) : const Color(0xFFEAD3AE),
      0.5,
      1.5,
      0.25,
      0.55,
    );
    // Sỏi nhỏ.
    // Nền menu "đất sỏi": dày và to hơn để thấy rõ sỏi.
    final n = (area / (dark ? 2600 : 7000)).round();
    for (var i = 0; i < n; i++) {
      final at = _rp(r, s);
      final rad = dark
          ? 1.8 + pow(r.nextDouble(), 2) * 5.5
          : 1.5 + r.nextDouble() * 3.2;
      final rot = r.nextDouble() * pi;
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(rot);
      final o = Rect.fromCenter(
        center: Offset.zero,
        width: rad * 2.2,
        height: rad * 1.6,
      );
      c.drawOval(
        o.shift(Offset(rad * 0.25, rad * 0.3)),
        Paint()..color = const Color(0x40000000),
      );
      c.drawOval(
        o,
        Paint()
          ..color = Color.lerp(
            dark ? const Color(0xFF6E665C) : const Color(0xFF8F8478),
            dark ? const Color(0xFFB8AC98) : const Color(0xFFCDBEA8),
            r.nextDouble(),
          )!,
      );
      c.drawOval(
        Rect.fromCenter(
          center: Offset(-rad * 0.3, -rad * 0.25),
          width: rad * 0.8,
          height: rad * 0.5,
        ),
        Paint()..color = const Color(0x55FFFFFF),
      );
      c.restore();
    }
    // Lá khô.
    for (var i = 0; i < (area / 60000).clamp(2, 12).round(); i++) {
      final at = _rp(r, s);
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(r.nextDouble() * pi * 2);
      final len = 9 + r.nextDouble() * 8;
      final leaf = Path()
        ..moveTo(-len, 0)
        ..quadraticBezierTo(0, -len * 0.45, len, 0)
        ..quadraticBezierTo(0, len * 0.45, -len, 0);
      c.drawPath(
        leaf,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF8A6A2E),
            const Color(0xFF6B7A3A),
            r.nextDouble(),
          )!.withValues(alpha: 0.75),
      );
      c.drawLine(
        Offset(-len, 0),
        Offset(len, 0),
        Paint()
          ..color = const Color(0x55402A10)
          ..strokeWidth = 0.7,
      );
      c.restore();
    }
  }

  static void _concrete(Canvas c, Size s, Random r) {
    final rect = Offset.zero & s;
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFC6C3BB),
            Color(0xFFB7B4AC),
            Color(0xFFA9A69E),
          ],
        ).createShader(rect),
    );
    final area = s.width * s.height;
    _blotches(
      c,
      s,
      r,
      (area / 12000).clamp(30, 160).round(),
      const Color(0xFF5E5B55),
      const Color(0xFFE4E1DA),
      20,
      110,
      0.09,
    );
    // Vết ố nước.
    for (var i = 0; i < 4; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: _rp(r, s),
          width: 80 + r.nextDouble() * 200,
          height: 50 + r.nextDouble() * 120,
        ),
        Paint()
          ..color = const Color(0xFF6E6A62).withValues(alpha: 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    _grit(
      c,
      s,
      r,
      45,
      const Color(0xFF5A5751),
      const Color(0xFFEDEAE3),
      0.35,
      1.1,
      0.2,
      0.5,
    );
    // Cốt liệu (đá dăm lộ mặt).
    final agg = Paint();
    for (var i = 0; i < (area / 1800).round(); i++) {
      final at = _rp(r, s);
      final rad = 0.8 + r.nextDouble() * 2.2;
      final poly = Path();
      final k = 5 + r.nextInt(3);
      for (var j = 0; j < k; j++) {
        final a = j * 2 * pi / k;
        final rr = rad * (0.7 + r.nextDouble() * 0.5);
        final p = at + Offset(cos(a) * rr, sin(a) * rr);
        j == 0 ? poly.moveTo(p.dx, p.dy) : poly.lineTo(p.dx, p.dy);
      }
      poly.close();
      agg.color = Color.lerp(
        const Color(0xFF8A867E),
        const Color(0xFFD6D2C8),
        r.nextDouble(),
      )!.withValues(alpha: 0.45);
      c.drawPath(poly, agg);
    }
    // Khe co giãn.
    final joint = Paint()
      ..strokeWidth = 2
      ..color = const Color(0x405A5751);
    final jointHi = Paint()
      ..strokeWidth = 1
      ..color = const Color(0x40FFFFFF);
    final gap = max(s.width, s.height) / (2 + r.nextInt(2));
    for (var x = gap * (0.3 + r.nextDouble() * 0.4); x < s.width; x += gap) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), joint);
      c.drawLine(Offset(x + 1.5, 0), Offset(x + 1.5, s.height), jointHi);
    }
    // Vết nứt.
    for (var i = 0; i < 3 + r.nextInt(3); i++) {
      _crack(
        c,
        _rp(r, s),
        r.nextDouble() * pi * 2,
        60 + r.nextDouble() * 160,
        r,
        2,
      );
    }
  }

  static void _crack(
    Canvas c,
    Offset from,
    double ang,
    double len,
    Random r,
    int depth,
  ) {
    final path = Path()..moveTo(from.dx, from.dy);
    var p = from;
    var a = ang;
    var walked = 0.0;
    while (walked < len) {
      final seg = 4 + r.nextDouble() * 9;
      a += (r.nextDouble() - 0.5) * 0.9;
      p += Offset(cos(a) * seg, sin(a) * seg);
      path.lineTo(p.dx, p.dy);
      walked += seg;
      if (depth > 0 && r.nextDouble() < 0.05) {
        _crack(c, p, a + (r.nextBool() ? 0.8 : -0.8), len * 0.35, r, depth - 1);
      }
    }
    c.drawPath(
      path.shift(const Offset(0.8, 0.8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = const Color(0x40FFFFFF),
    );
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + depth * 0.25
        ..color = const Color(0x8C3F3C37),
    );
  }

  static void _tiles(Canvas c, Size s, Random r) {
    // Sân gạch bát: gạch vuông đỏ, mạch vữa xám.
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF9E9282));
    final tile = (min(s.width, s.height) / 4.2).clamp(64.0, 130.0);
    const mortar = 4.0;
    final ox = -r.nextDouble() * tile, oy = -r.nextDouble() * tile;
    const palette = [
      Color(0xFFB4553A),
      Color(0xFFC0623F),
      Color(0xFFA84A32),
      Color(0xFFBC6B48),
      Color(0xFFAE5A3E),
    ];
    for (var y = oy; y < s.height; y += tile) {
      for (var x = ox; x < s.width; x += tile) {
        final rect = Rect.fromLTWH(
          x + mortar / 2,
          y + mortar / 2,
          tile - mortar,
          tile - mortar,
        );
        final base = Color.lerp(
          palette[r.nextInt(palette.length)],
          const Color(0xFF8C3F2A),
          r.nextDouble() * 0.25,
        )!;
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
        c.drawRRect(
          rr,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(base, const Color(0xFFFFFFFF), 0.08)!,
                base,
                Color.lerp(base, const Color(0xFF000000), 0.12)!,
              ],
            ).createShader(rect),
        );
        c.save();
        c.clipRRect(rr);
        // Mòn, rỗ mặt gạch.
        final p = Paint();
        for (var i = 0; i < (tile * tile / 90).round(); i++) {
          p.color =
              (r.nextDouble() < 0.6
                      ? const Color(0xFF6E2A18)
                      : const Color(0xFFE4A07C))
                  .withValues(alpha: 0.12 + r.nextDouble() * 0.25);
          c.drawCircle(
            rect.topLeft +
                Offset(
                  r.nextDouble() * rect.width,
                  r.nextDouble() * rect.height,
                ),
            0.4 + r.nextDouble() * 1.3,
            p,
          );
        }
        for (var i = 0; i < 3; i++) {
          p
            ..color =
                (r.nextBool()
                        ? const Color(0xFF5A2414)
                        : const Color(0xFFE8B090))
                    .withValues(alpha: 0.08)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, tile * 0.12);
          c.drawCircle(
            rect.topLeft +
                Offset(
                  r.nextDouble() * rect.width,
                  r.nextDouble() * rect.height,
                ),
            tile * (0.15 + r.nextDouble() * 0.25),
            p,
          );
          p.maskFilter = null;
        }
        // Mẻ góc.
        if (r.nextDouble() < 0.25) {
          final corner = [
            rect.topLeft,
            rect.topRight,
            rect.bottomLeft,
            rect.bottomRight,
          ][r.nextInt(4)];
          c.drawCircle(
            corner,
            3 + r.nextDouble() * 6,
            Paint()..color = const Color(0xFF9E9282),
          );
        }
        c.restore();
      }
    }
    // Rêu trong mạch vữa.
    final moss = Paint();
    for (var i = 0; i < (s.width * s.height / 5000).round(); i++) {
      final onX = r.nextBool();
      final gx = ox + (r.nextInt((s.width / tile).ceil() + 2)) * tile;
      final gy = oy + (r.nextInt((s.height / tile).ceil() + 2)) * tile;
      final at = onX
          ? Offset(gx + r.nextDouble() * tile, gy)
          : Offset(gx, gy + r.nextDouble() * tile);
      moss.color = const Color(
        0xFF5E7A3A,
      ).withValues(alpha: 0.25 + r.nextDouble() * 0.35);
      c.drawCircle(at, 1 + r.nextDouble() * 2.2, moss);
    }
  }
}

/// Raster hóa mặt sân (cache theo kích thước + kiểu + seed) để vẽ mỗi frame rẻ.
abstract final class GroundCache {
  static final _cache = <String, ui.Image>{};

  static ui.Image image(Size size, double dpr, GroundKind kind, int seed) {
    final w = max(1, (size.width * dpr).round());
    final h = max(1, (size.height * dpr).round());
    final key = '$w×$h|${kind.name}|$seed';
    final hit = _cache[key];
    if (hit != null) return hit;
    // Không dispose: ảnh cũ có thể vẫn đang được widget khác vẽ; để GC thu.
    if (_cache.length > 6) _cache.clear();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)..scale(dpr);
    FolkGround.paint(c, size, kind, seed);
    final pic = rec.endRecording();
    final img = pic.toImageSync(w, h);
    pic.dispose();
    return _cache[key] = img;
  }
}

/// Viền nét phấn run tay cho nút/thẻ. Hình dạng (vùng bấm, nền) là hình chữ
/// nhật bo góc bình thường; chỉ đường viền được vẽ như kẻ phấn. Seed lấy theo
/// kích thước nên cùng một nút luôn vẽ y như nhau (không nhấp nháy).
class ChalkBorder extends OutlinedBorder {
  const ChalkBorder({
    this.radius = 16,
    this.color = const Color(0xFFF7F4EC),
    this.width = 2.2,
    super.side,
  });

  final double radius;
  final Color color;
  final double width;

  RRect _rrect(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect).deflate(width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) return;
    final path = Path()..addRRect(_rrect(rect).deflate(width * 0.9));
    final seed =
        (rect.width.round() * 131 + rect.height.round() * 7) & 0x7fffffff;
    FolkPen.stroke(
      canvas,
      path,
      PenKind.chalk,
      width: width,
      color: color,
      seed: seed,
    );
  }

  @override
  ChalkBorder copyWith({
    BorderSide? side,
    double? radius,
    Color? color,
    double? width,
  }) => ChalkBorder(
    radius: radius ?? this.radius,
    color: color ?? this.color,
    width: width ?? this.width,
    side: side ?? this.side,
  );

  @override
  ShapeBorder scale(double t) => ChalkBorder(
    radius: radius * t,
    color: color,
    width: width * t,
    side: side.scale(t),
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is ChalkBorder
      ? ChalkBorder(
          radius: radius,
          color: Color.lerp(a.color, color, t)!,
          width: width,
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is ChalkBorder
      ? ChalkBorder(
          radius: radius,
          color: Color.lerp(color, b.color, t)!,
          width: width,
        )
      : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is ChalkBorder &&
      other.radius == radius &&
      other.color == color &&
      other.width == width;

  @override
  int get hashCode => Object.hash(radius, color, width);
}
