import 'dart:math';

import 'package:flutter/painting.dart';

import 'ground_common.dart';
import 'ground_colors.dart';

void paintDirt(Canvas c, Size s, Random r, {bool dark = false}) {
  final rect = Offset.zero & s;
  c.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: Alignment(r.nextDouble() - 0.5, r.nextDouble() - 0.5),
        radius: 1.1,
        colors: clayColors(dark),
        stops: const [0, 0.55, 1],
      ).createShader(rect),
  );
  final area = s.width * s.height;
  paintBlotches(
    c,
    s,
    r,
    (area / 9000).clamp(40, 220).round(),
    blotchDark(dark),
    blotchLight(dark),
    12,
    70,
    0.12,
  );
  // Vệt quét chổi.
  final sweep = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 18; i++) {
    final a = groundPoint(r, s);
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
        ..color = sweepColor(
          dark,
        ).withValues(alpha: 0.08 + r.nextDouble() * 0.08);
      c.drawPath(path.shift(Offset(k * 3.0, k * 2.0)), sweep);
    }
  }
  paintGrit(
    c,
    s,
    r,
    120,
    gritDark(dark),
    gritLight(dark),
    0.5,
    1.5,
    0.25,
    0.55,
  );
  // Sỏi nhỏ.
  // Nền menu "đất sỏi": dày và to hơn để thấy rõ sỏi.
  var density = 7000;
  if (dark) density = 2600;
  final n = (area / density).round();
  for (var i = 0; i < n; i++) {
    final at = groundPoint(r, s);
    var rad = 1.5 + r.nextDouble() * 3.2;
    if (dark) rad = 1.8 + pow(r.nextDouble(), 2) * 5.5;
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
        ..color = Color.lerp(pebbleLo(dark), pebbleHi(dark), r.nextDouble())!,
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
    final at = groundPoint(r, s);
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
