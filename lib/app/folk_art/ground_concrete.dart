import 'dart:math';

import 'package:flutter/painting.dart';

import 'ground_common.dart';
import 'ground_colors.dart';

void paintConcrete(Canvas c, Size s, Random r) {
  final rect = Offset.zero & s;
  c.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0xFFC6C3BB), Color(0xFFB7B4AC), Color(0xFFA9A69E)],
      ).createShader(rect),
  );
  final area = s.width * s.height;
  paintBlotches(
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
        center: groundPoint(r, s),
        width: 80 + r.nextDouble() * 200,
        height: 50 + r.nextDouble() * 120,
      ),
      Paint()
        ..color = const Color(0xFF6E6A62).withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }
  paintGrit(
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
    final at = groundPoint(r, s);
    final rad = 0.8 + r.nextDouble() * 2.2;
    final poly = Path();
    final k = 5 + r.nextInt(3);
    for (var j = 0; j < k; j++) {
      final a = j * 2 * pi / k;
      final rr = rad * (0.7 + r.nextDouble() * 0.5);
      final p = at + Offset(cos(a) * rr, sin(a) * rr);
      if (j == 0) {
        poly.moveTo(p.dx, p.dy);
      } else {
        poly.lineTo(p.dx, p.dy);
      }
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
    paintCrack(
      c,
      groundPoint(r, s),
      r.nextDouble() * pi * 2,
      60 + r.nextDouble() * 160,
      r,
      2,
    );
  }
}

void paintCrack(
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
      paintCrack(c, p, a + signedOf(r, 0.8), len * 0.35, r, depth - 1);
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
