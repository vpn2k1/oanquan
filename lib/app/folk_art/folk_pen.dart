import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'folk_style.dart';
import 'ground_colors.dart';

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
    var start = 0.0;
    var total = len;
    if (m.isClosed) {
      start = rnd.nextDouble() * len;
      total = len + w * (1.5 + rnd.nextDouble() * 2);
    }
    final out = <(Offset, Offset)>[];
    for (var d = 0.0; d <= total; d += step) {
      var at = d;
      if (m.isClosed) at = (start + d) % len;
      final t = m.getTangentForOffset(at);
      if (t == null) continue;
      final n = Offset(-t.vector.dy, t.vector.dx);
      // Đầu/cuối nét hơi lệch ra ngoài (nhấc phấn).
      var edge = 0.0;
      if (m.isClosed && d > len) edge = (d - len) / (total - len + 1);
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
      // Lượt chính: nét dày, ít hở; lượt mỏng: lệch nhẹ, hở nhiều hơn.
      var off = w * 0.28;
      var skipChance = 0.25;
      var baseAlpha = 0.35;
      if (pass == 0) {
        off = 0.0;
        skipChance = 0.05;
        baseAlpha = 0.55;
      }
      for (var i = 1; i < pts.length; i++) {
        // Chỗ phấn không ăn.
        if (rnd.nextDouble() < skipChance) continue;
        final (a, na) = pts[i - 1];
        final (b, _) = pts[i];
        var widthFactor = 0.35 + rnd.nextDouble() * 0.25;
        if (pass == 0) widthFactor = 0.75 + rnd.nextDouble() * 0.4;
        p
          ..strokeWidth = w * widthFactor
          ..color = color.withValues(
            alpha: baseAlpha + rnd.nextDouble() * 0.35,
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
        final o = n * (w * signedOf(rnd, 0.55));
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
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
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
        var dotBase = const Color(0xFF6B4A2B);
        if (light) dotBase = const Color(0xFFE6CBA0);
        dot.color = dotBase.withValues(alpha: 0.35 + rnd.nextDouble() * 0.4);
        final side = signedOf(rnd, 1);
        c.drawCircle(
          q + n * (side * w * (0.9 + rnd.nextDouble() * 0.9)),
          w * (0.12 + rnd.nextDouble() * 0.2),
          dot,
        );
      }
    }
  }
}
